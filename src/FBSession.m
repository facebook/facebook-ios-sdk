/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIDevice.h>
#import "FBSession.h"
#import "FBSession+Internal.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBError.h"
#import "FBLogger.h"
#import "FBUtility.h"

// the sooner we can remove these the better
#import "Facebook.h"
#import "FBLoginDialog.h"

// these are helpful macros for testing various login methods, should always checkin as NO/NO
#define TEST_DISABLE_MULTITASKING_LOGIN (NO)
#define TEST_DISABLE_SSO (NO)

// extern const strings
NSString *const FBErrorLoginFailedReasonInlineCancelledValue = @"com.facebook.FBiOSSDK:InlineLoginCancelled";
NSString *const FBErrorLoginFailedReasonInlineNotCancelledValue = @"com.facebook.FBiOSSDK:ErrorLoginNotCancelled";
NSString *const FBErrorLoginFailedReasonUnitTestResponseUnrecognized = @"com.facebook.FBiOSSDK:UnitTestResponseUnrecognized";

// const strings
static NSString *const FBPLISTAppIDKey = @"FacebookAppID";
// for unit testing mode only (DO NOT store application secrets in a published application plist)
static NSString *const FBPLISTAppSecretKey = @"FacebookAppSecret";
static NSString *const FBAuthURLScheme = @"fbauth";
static NSString *const FBAuthURLPath = @"authorize";
static NSString *const FBRedirectURL = @"fbconnect://success";
static NSString *const FBDialogBaseURL = @"https://m.facebook.com/dialog/";
static NSString *const FBLoginDialogMethod = @"oauth";
static NSString *const FBLoginAuthTestUserURLPath = @"oauth/access_token";
static NSString *const FBLoginAuthTestUserCreatePathFormat = @"%@/accounts/test-users";
static NSString *const FBLoginTestUserClientID = @"client_id";
static NSString *const FBLoginTestUserClientSecret = @"client_secret";
static NSString *const FBLoginTestUserGrantType = @"grant_type";
static NSString *const FBLoginTestUserGrantTypeClientCredentials = @"client_credentials";
static NSString *const FBLoginTestUserAccessToken = @"access_token";
static NSString *const FBLoginTestUserID = @"id";
static NSString *const FBLoginUXClientID = @"client_id";
static NSString *const FBLoginUXUserAgent = @"user_agent";
static NSString *const FBLoginUXType = @"type";
static NSString *const FBLoginUXRedirectURI = @"redirect_uri";
static NSString *const FBLoginUXTouch = @"touch";
static NSString *const FBLoginUXDisplay = @"display";
static NSString *const FBLoginUXIOS = @"ios";
static NSString *const FBLoginUXSDK = @"sdk";

// the following const strings name properties for which KVO is manually handled
// if name changes occur, these strings must be modified to match, else KVO will fail
static NSString *const FBisValidPropertyName = @"isValid";
static NSString *const FBstatusPropertyName = @"status";
static NSString *const FBaccessTokenPropertyName = @"accessToken";
static NSString *const FBexpirationDatePropertyName = @"expirationDate";

// module scoped globals
static NSString *FBPLISTAppID = nil;
static NSSet *g_loggingBehavior;

@interface FBSession () <FBLoginDialogDelegate> {
    @private
    // public property ivars
    FBSessionState _status;
    NSString *_appID;
    NSString *_urlSchemeSuffix;
    NSString *_accessToken;
    NSString *_userID;
    NSDate *_expirationDate;
    NSArray *_permissions;

    // private property and non-property ivars
    BOOL _isInStateTransition;
    FBSessionStatusHandler _loginHandler;
    FBLoginDialog *_loginDialog;
    NSThread *_affinitizedThread;
    // in app-use cases this value is always non-nil, for unit testing this value is nil
    FBSessionTokenCachingStrategy *_tokenCachingStrategy;
}

// private setters
@property(readwrite) FBSessionState status;
@property(readwrite, copy) NSString *appID;
@property(readwrite, copy) NSString *urlSchemeSuffix;
@property(readwrite, copy) NSString *accessToken;
@property(readwrite, copy) NSDate *expirationDate;
@property(readwrite, copy) NSArray *permissions;

// private properties
@property(readwrite, retain) FBSessionTokenCachingStrategy *tokenCachingStrategy;
@property(readwrite, copy) FBSessionStatusHandler loginHandler;
@property(readonly) NSString *appBaseUrl;
@property(readwrite, retain) FBLoginDialog *loginDialog;
@property(readwrite, retain) NSThread *affinitizedThread;
@property(readonly) BOOL isForUnitTesting;
@property(readwrite, copy) NSString *userID;

// private members
- (void)notifyOfState:(FBSessionState)state;
- (BOOL)transitionToState:(FBSessionState)state
           andUpdateToken:(NSString*)token
        andExpirationDate:(NSDate*)date
              shouldCache:(BOOL)shouldCache;
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth
                    safariAuth:(BOOL)trySafariAuth
                      fallback:(BOOL)tryFallback;
- (void)authorizeUnitTestUser;
- (void)transitionAndCallHandlerWithState:(FBSessionState)status
                                    error:(NSError*)error
                                    token:(NSString*)token
                           expirationDate:(NSDate*)date
                              shouldCache:(BOOL)shouldCache;

// private initializer is the designated initializer
- (id)initWithAppID:(NSString*)appID
        permissions:(NSArray*)permissions
    urlSchemeSuffix:(NSString*)urlSchemeSuffix
 tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy
   isForUnitTesting:(BOOL)isForUnitTesting;

// class members
+ (NSString*)appIDFromPLIST;
+ (NSError*)errorLoginFailedWithReason:(NSString*)errorReason
                             errorCode:(NSString*)errorCode;
+ (void)deleteUnitTestUser:(NSString*)userID accessToken:(NSString*)accessToken;

@end

@implementation FBSession : NSObject

#pragma mark Lifecycle

- (id)init {
    return [self initWithAppID:nil
                   permissions:nil
               urlSchemeSuffix:nil
            tokenCacheStrategy:nil
              isForUnitTesting:NO];
}

- (id)initWithPermissions:(NSArray*)permissions {
    return [self initWithAppID:nil
                   permissions:permissions
               urlSchemeSuffix:nil
            tokenCacheStrategy:nil
              isForUnitTesting:NO];
}

- (id)initWithAppID:(NSString*)appID
        permissions:(NSArray*)permissions
    urlSchemeSuffix:(NSString*)urlSchemeSuffix
 tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy {
    return [self initWithAppID:nil
                   permissions:permissions
               urlSchemeSuffix:nil
            tokenCacheStrategy:nil
              isForUnitTesting:NO];
}

- (id)initWithAppID:(NSString*)appID
        permissions:(NSArray*)permissions
    urlSchemeSuffix:(NSString*)urlSchemeSuffix
 tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy 
   isForUnitTesting:(BOOL)isForUnitTesting {
    self = [super init];
    if (self) {

        // setup values where nil implies a default
        if (!appID) {
            appID = [FBSession appIDFromPLIST];
        }
        if (!permissions) {
            permissions = [NSArray array];
        }
        if (!tokenCachingStrategy && !isForUnitTesting) {
            tokenCachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
        }
        NSAssert(!(tokenCachingStrategy && isForUnitTesting), 
                 @"Invalid to have a caching strategy when for unit testing, public interface should dissallow");
        
        // if we are built for unit testing, then assert and setup a few things
        if (self.isForUnitTesting) {
            NSAssert(!urlSchemeSuffix, 
                     @"Invalid to have a urlSchemeSuffix when for unit testing, public interface should dissallow");
            NSAssert(!appID, 
                     @"Invalid to have an explicit appID when for unit testing, public interface should dissallow");
            
            // building-up an appID and initial app-token
            
            // first fetch documents directory 
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            // fetch config contents
            NSString *configfilename = [documentsDirectory stringByAppendingPathComponent:@"FBiOSSDK-UnitTestConfig.plist"];
            NSDictionary *configsettings = [NSDictionary dictionaryWithContentsOfFile:configfilename];
            
            NSString *appIDUT = [configsettings objectForKey:FBPLISTAppIDKey];
            NSString *appSecret = [configsettings objectForKey:FBPLISTAppSecretKey];
            if (appIDUT && appSecret) {
                appID = appIDUT;
                self.accessToken = [NSString stringWithFormat:@"%@|%@", appID, appSecret];
            } else {
                appID = nil; // this assures we trigger the following exception
            }
        }

        // if we don't have an appID by here, fail -- this is almost certainly an app-bug
        if (!appID) {
            [[NSException exceptionWithName:FBInvalidOperationException
                                     reason:@"FBSession: No AppID provided; either pass an "
                                            @"AppID to init, or add a string valued key with the "
                                            @"appropriate id named FacebookAppID to the bundle *.plist; if this "
                                            @"is a unit testing session, then FBiOSSDK-UnitTestConfig.plist is "
                                            @"is missing or invalid; to create a Facebook AppID, "
                                            @"visit https://developers.facebook.com/apps"
                                   userInfo:nil]
             raise];
        }

        // assign arguments;
        self.appID = appID;
        self.permissions = permissions;
        self.urlSchemeSuffix = urlSchemeSuffix;
        self.tokenCachingStrategy = tokenCachingStrategy;

        // additional setup
        _isInStateTransition = NO;
        self.status = FBSessionStateCreated;
        self.affinitizedThread = [NSThread currentThread];

        //first notification
        [self notifyOfState:self.status];

        // use cached token if present
        NSDate *cachedTokenExpirationDate = nil;
        NSString *cachedToken = [tokenCachingStrategy fetchTokenAndExpirationDate:&cachedTokenExpirationDate];
        if (cachedToken) {
            // check to see if expiration date is later than now
            if (NSOrderedDescending == [cachedTokenExpirationDate compare:[NSDate date]]) {
                // set the state and token info
                [self transitionToState:FBSessionStateLoadedValidToken
                         andUpdateToken:cachedToken
                      andExpirationDate:cachedTokenExpirationDate
                            shouldCache:NO];
            } else {
                // else this token is expired and should be cleared from cache
                [tokenCachingStrategy clearToken:cachedToken];
            }
        }
    }
    return self;
}

- (void)dealloc {
    [_loginDialog release];
    [_loginHandler release];
    [_appID release];
    [_urlSchemeSuffix release];
    [_accessToken release];
    [_expirationDate release];
    [_permissions release];
    [_tokenCachingStrategy release];
    [_affinitizedThread release];

    [super dealloc];
}

#pragma mark -
#pragma mark Public Members

@synthesize appID = _appID,
            permissions = _permissions,
            loginHandler = _loginHandler,
            // following properties use manual KVO -- changes to names require
            // changes to static property name variables (e.g. FBisValidPropertyName)
            status = _status,
            accessToken = _accessToken,
            expirationDate = _expirationDate,
            userID = _userID;


- (void)loginWithCompletionHandler:(FBSessionStatusHandler)handler {
    [self loginWithBehavior:FBSessionLoginBehaviorSSOWithFallback completionHandler:handler];
}

- (void)loginWithBehavior:(FBSessionLoginBehavior)behavior
    completionHandler:(FBSessionStatusHandler)handler {

    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    if (!(self.status == FBSessionStateCreated ||
          self.status == FBSessionStateLoadedValidToken)) {
        // login may only be called once, and only from one of the two initial states
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBSession: an attempt was made to login an already logged in or invalid"
                                        @"session"
                               userInfo:nil]
         raise];
    }
    self.loginHandler = handler;

    if (!self.isForUnitTesting) {
        // normal login depends on the availability of a valid cached token
        if (self.status == FBSessionStateCreated) {
            BOOL trySSO = (behavior == FBSessionLoginBehaviorSSOOnly) ||
            (behavior == FBSessionLoginBehaviorSSOWithFallback);
            BOOL tryFallback = (behavior == FBSessionLoginBehaviorSSOWithFallback) ||
            (behavior == FBSessionLoginBehaviorSuppressSSO);
            
            [self authorizeWithFBAppAuth:trySSO
                              safariAuth:trySSO
                                fallback:tryFallback];
        } else { // self.status == FBSessionStateLoadedValidToken
            // this case implies that a valid cached token was found, and preserves the
            // "1-session-1-identity" rule, by transitioning to logged in, without a transition to login UX
            [self transitionAndCallHandlerWithState:FBSessionStateLoggedIn
                                              error:nil
                                              token:nil
                                     expirationDate:nil
                                        shouldCache:NO];
        }
    } else {
        // unit testing login is different from normal app login flow in a couple ways:
        // * There will be no UX
        // * A test user is created dynamically
        // * Cached credentials are fetched (by init) from a special unit testing config file
        [self authorizeUnitTestUser];
    }
}

- (void)invalidate {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    [self transitionAndCallHandlerWithState:FBSessionStateInvalidated
                                      error:nil
                                      token:nil
                             expirationDate:nil
                                shouldCache:NO];
}

- (void)logout {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    [self.tokenCachingStrategy clearToken:self.accessToken];
    [self transitionAndCallHandlerWithState:FBSessionStateLoggedOut
                                      error:nil
                                      token:nil
                             expirationDate:nil
                                shouldCache:NO];
}

- (BOOL)handleOpenURL:(NSURL *)url {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    if (![[url absoluteString] hasPrefix:self.appBaseUrl]) {
        return NO;
    }

    // version 3.2.3 of the Facebook app encodes the parameters in the query but
    // version 3.3 and above encode the parameters in the fragment; check first for
    // fragment, and if missing fall back to query
    NSString *query = [url fragment];
    if (!query) {
        query = [url query];
    }

    NSDictionary *params = [FBUtility dictionaryByParsingURLQueryPart:query];
    NSString *accessToken = [params objectForKey:@"access_token"];

    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [params objectForKey:@"error"];

        // if the error response indicates that we should try again using Safari, open
        // the authorization dialog in Safari.
        if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
            [self authorizeWithFBAppAuth:NO safariAuth:YES fallback:NO];
            return YES;
        }

        // if the error response indicates that we should try the authorization flow
        // in an inline dialog, do that.
        if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
            [self authorizeWithFBAppAuth:NO safariAuth:NO fallback:NO];
            return YES;
        }

        // the facebook app may return an error_code parameter in case it
        // encounters a UIWebViewDelegate error
        NSString *errorCode = [params objectForKey:@"error_code"];

        // create an error object with additional info regarding failed login
        NSError *error = [FBSession errorLoginFailedWithReason:errorReason
                                                    errorCode:errorCode];

        // state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateLoginFailed
                                          error:error
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO];
    } else {

        // we have an access token, so parse the expiration date.
        NSString *expTime = [params objectForKey:@"expires_in"];
        NSDate *expirationDate = [NSDate distantFuture];
        if (expTime != nil) {
            int expVal = [expTime intValue];
            if (expVal != 0) {
                expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
            }
        }

        // set token and date, state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateLoggedIn
                                          error:nil
                                          token:accessToken
                                 expirationDate:expirationDate
                                    shouldCache:YES];
    }
    return YES;
}

- (BOOL)isValid {
    return FB_ISSESSIONVALIDWITHSTATE(self.status);
}

- (NSString*)urlSchemeSuffix {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");
    return _urlSchemeSuffix ? _urlSchemeSuffix : @"";
}

// actually a private member, but wanted to be close to its public colleague
- (void)setUrlSchemeSuffix:(NSString*)newValue {
    if (_urlSchemeSuffix != newValue) {
        [_urlSchemeSuffix release];
        _urlSchemeSuffix = [(newValue ? newValue : @"") copy];
    }
}

// our sole public static member, used to create a unit-test instance
+ (id)sessionForUnitTestingWithPermissions:(NSArray*)permissions {
    // call our internal delegated initializer to create a unit-testing instance
    return [[[FBSession alloc] initWithAppID:nil
                                permissions:permissions 
                            urlSchemeSuffix:nil
                         tokenCacheStrategy:nil
                           isForUnitTesting:YES]
            autorelease];
}

#pragma mark -
#pragma mark Class Methods

+ (NSSet *)loggingBehavior {
    return g_loggingBehavior;
}

+ (void)setLoggingBehavior:(NSSet *)newValue {
    [g_loggingBehavior release];
    g_loggingBehavior = newValue;
    [g_loggingBehavior retain];
}

#pragma mark -
#pragma mark Private Members

@synthesize     tokenCachingStrategy = _tokenCachingStrategy,
                loginDialog = _loginDialog,
                affinitizedThread = _affinitizedThread;

// private methods are broken into two categories: core session and helpers

// core session members

// core member that owns all state transitions as well as property setting for status and isValid
- (BOOL)transitionToState:(FBSessionState)state
           andUpdateToken:(NSString*)token
        andExpirationDate:(NSDate*)date
              shouldCache:(BOOL)shouldCache
{

    // is this a valid transition?
    BOOL isValidTransition;
    FBSessionState statePrior;

    statePrior = self.status;
    switch (state) {
        default:
        case FBSessionStateCreated:
            isValidTransition = NO;
            break;
        case FBSessionStateLoggedIn:
            isValidTransition = (
                                 statePrior == FBSessionStateCreated ||
                                 statePrior == FBSessionStateLoadedValidToken
                                 );
            break;
        case FBSessionStateLoadedValidToken:
        case FBSessionStateLoginFailed:
            isValidTransition = statePrior == FBSessionStateCreated;
            break;
        case FBSessionStateExtendedToken:
            isValidTransition = (
                                 statePrior == FBSessionStateLoggedIn ||
                                 statePrior == FBSessionStateExtendedToken
                                 );
            break;
        case FBSessionStateLoggedOut:
        case FBSessionStateInvalidated:
            isValidTransition = (
                                 statePrior == FBSessionStateLoggedIn ||
                                 statePrior == FBSessionStateExtendedToken ||
                                 statePrior == FBSessionStateLoadedValidToken
                                 );
            break;
    }

    // invalid transition short circuits
    if (!isValidTransition) {
        [FBLogger singleShotLogEntry:FB_LOG_BEHAVIOR_SESSION_STATE_TRANSITIONS
                            logEntry:[NSString stringWithFormat:@"FBSession !transitionToState:%i fromState:%i", state, statePrior]];
        return false;
    }

    // if this is yes, someone called a method on FBSession from within a KVO will change handler
    if (_isInStateTransition) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBSession: An attempt to change an FBSession object was "
                                        @"made while a change was in flight; this is most likely due to "
                                        @"a KVO observer calling a method on FBSession while handling a "
                                        @"NSKeyValueObservingOptionPrior notification"
                               userInfo:nil]
         raise];
    }

    // valid transitions notify
    [FBLogger singleShotLogEntry:FB_LOG_BEHAVIOR_SESSION_STATE_TRANSITIONS
                        logEntry:[NSString stringWithFormat:@"FBSession transitionToState:%i fromState:%i", state, statePrior]];
    
    // identify whether we will update token and date, and what the values will be
    BOOL changingTokenAndDate = false;
    if (token && date) {
        changingTokenAndDate = true;
    } else if (!FB_ISSESSIONVALIDWITHSTATE(state) &&
               FB_ISSESSIONVALIDWITHSTATE(statePrior)) {
        changingTokenAndDate = true;
        token = nil;
        date = nil;
    }

    BOOL changingIsInvalid = FB_ISSESSIONVALIDWITHSTATE(state) == FB_ISSESSIONVALIDWITHSTATE(statePrior);

    // should only ever be YES from here...
    _isInStateTransition = YES;

    // KVO property will change notifications, for state change
    [self willChangeValueForKey:FBstatusPropertyName];
    if (changingIsInvalid) {
        [self willChangeValueForKey:FBisValidPropertyName];
    }

    if (changingTokenAndDate) {
        // KVO property will-change notifications for token and date
        [self willChangeValueForKey:FBaccessTokenPropertyName];
        [self willChangeValueForKey:FBexpirationDatePropertyName];

        // change the token and date values, should be kept near to state change following the conditional
        self.accessToken = token;
        self.expirationDate = date;
    }

    // change the actual state
    // note: we should not inject any callbacks between this and the token/date changes above
    self.status = state;

    // ... to here -- if YES
    _isInStateTransition = NO;

    // internal state change notification
    [self notifyOfState:state];

    if (changingTokenAndDate) {
        // update the cache
        if (shouldCache) {
            [self.tokenCachingStrategy cacheToken:token expirationDate:date];
        }

        // KVO property change notifications token and date
        [self didChangeValueForKey:FBexpirationDatePropertyName];
        [self didChangeValueForKey:FBaccessTokenPropertyName];
    }

    // KVO property did change notifications, for state change
    if (changingIsInvalid) {
        [self didChangeValueForKey:FBisValidPropertyName];
    }
    [self didChangeValueForKey:FBstatusPropertyName];

    // Note! It is important that no processing occur after the KVO notifications have been raised, in order to
    // assure the state is cohesive in common reintrant scenarios

    // the NO case short-circuits after the state switch/case
    return true;
}

// core authorization UX flow
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth
                    safariAuth:(BOOL)trySafariAuth 
                      fallback:(BOOL)tryFallback {
    // setup parameters for either the safari or inline login
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.appID, FBLoginUXClientID,
                                   FBLoginUXUserAgent, FBLoginUXType,
                                   FBRedirectURL, FBLoginUXRedirectURI,
                                   FBLoginUXTouch, FBLoginUXDisplay,
                                   FBLoginUXIOS, FBLoginUXSDK,
                                   nil];

    NSString *loginDialogURL = [FBDialogBaseURL stringByAppendingString:FBLoginDialogMethod];

    if (_permissions != nil) {
        NSString* scope = [_permissions componentsJoinedByString:@","];
        [params setValue:scope forKey:@"scope"];
    }

    if (_urlSchemeSuffix) {
        [params setValue:_urlSchemeSuffix forKey:@"local_client_id"];
    }

    // To avoid surprises, delete any cookies we currently have.
    [FBSession deleteFacebookCookies];

    // If the device is running a version of iOS that supports multitasking,
    // try to obtain the access token from the Facebook app installed
    // on the device.
    // If the Facebook app isn't installed or it doesn't support
    // the fbauth:// URL scheme, fall back on Safari for obtaining the access token.
    // This minimizes the chance that the user will have to enter his or
    // her credentials in order to authorize the application.
    BOOL didOpenOtherApp = NO;
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported] &&
        !TEST_DISABLE_MULTITASKING_LOGIN) {
        if (tryFBAppAuth &&
            !TEST_DISABLE_SSO) {
            NSString *scheme = FBAuthURLScheme;
            if (_urlSchemeSuffix) {
                scheme = [scheme stringByAppendingString:@"2"];
            }
            NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, FBAuthURLPath];
            NSString *fbAppUrl = [FBRequest serializeURL:urlPrefix params:params];
            didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }

        if (trySafariAuth && !didOpenOtherApp) {
            NSString *nextUrl = self.appBaseUrl;
            [params setValue:nextUrl forKey:@"redirect_uri"];

            NSString *fbAppUrl = [FBRequest serializeURL:loginDialogURL params:params];
            didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }
    }

    // If single sign-on failed, see if we should attempt to fallback
    if (!didOpenOtherApp) {
        if (tryFallback) {
            // open an inline login dialog. This will require the user to enter his or her credentials.
            self.loginDialog = [[[FBLoginDialog alloc] initWithURL:loginDialogURL
                                                       loginParams:params
                                                          delegate:self]
                                autorelease];
            [self.loginDialog show];
        } else {
            // Can't fallback and SSO failed, so transition to an error state
            NSError *error = [FBSession errorLoginFailedWithReason:FBErrorLoginFailedReasonInlineNotCancelledValue
                                                         errorCode:nil];

            // state transition, and call the handler if there is one
            [self transitionAndCallHandlerWithState:FBSessionStateLoginFailed
                                              error:error
                                              token:nil
                                     expirationDate:nil
                                        shouldCache:NO];
        }
    }
}

// core authorization unit testing (no UX + test user) flow
- (void)authorizeUnitTestUser {    
    // fetch a test user and token
    // note, this fetch uses a manually constructed app token using the appid|appsecret approach,
    // if there is demand for support for apps for which this will not work, we may consider handling 
    // failure by falling back and fetching an app-token via a request; the current approach reduces 
    // traffic for commin unit testing configuration, which seems like the right tradeoff to start with
    if (!self.permissions.count) {
        self.permissions = [NSArray arrayWithObjects:@"email", @"publish_actions", nil];
    }
    [[FBRequest connectionWithSession:nil
                            graphPath:[NSString stringWithFormat:FBLoginAuthTestUserCreatePathFormat, self.appID]
                           parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                       @"true", @"installed",
                                       [self.permissions componentsJoinedByString:@","], @"permissions",
                                       @"post", @"method",
                                       self.accessToken, @"access_token",
                                       nil]
                           HTTPMethod:nil
                    completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        id userToken;
                        id userID;
                        if ([result isKindOfClass:[NSDictionary class]] &&
                            (userToken = [result objectForKey:FBLoginTestUserAccessToken]) &&
                            [userToken isKindOfClass:[NSString class]] &&
                            (userID = [result objectForKey:FBLoginTestUserID]) &&
                            [userID isKindOfClass:[NSString class]]) {
                            
                            // capture the id for future use (delete)
                            self.userID = userID;
                            
                            // set token and date, state transition, and call the handler if there is one
                            [self transitionAndCallHandlerWithState:FBSessionStateLoggedIn
                                                              error:nil
                                                              token:userToken
                                                     expirationDate:[NSDate distantFuture]
                                                        shouldCache:NO];
                        } else {
                            // we fetched something unexpected when requesting an app token
                            NSError *loginError = [FBSession errorLoginFailedWithReason:FBErrorLoginFailedReasonUnitTestResponseUnrecognized
                                                                         errorCode:nil];
                            
                            // state transition, and call the handler if there is one
                            [self transitionAndCallHandlerWithState:FBSessionStateLoginFailed
                                                              error:loginError
                                                              token:nil
                                                     expirationDate:nil
                                                        shouldCache:NO];
                        }
                    }] 
     start];
}

// core handler for inline UX flow
- (void)fbDialogLogin:(NSString *)accessToken expirationDate:(NSDate *)expirationDate {
    // no reason to keep this object
    self.loginDialog = nil;

    // set token and date, state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateLoggedIn
                                      error:nil
                                      token:accessToken
                             expirationDate:expirationDate
                                shouldCache:YES];
}

// core handler for inline UX flow
- (void)fbDialogNotLogin:(BOOL)cancelled {
    // done with this
    self.loginDialog = nil;

    // manually set the reason string for inline dialog
    NSString *reason =
        cancelled ? FBErrorLoginFailedReasonInlineCancelledValue : FBErrorLoginFailedReasonInlineNotCancelledValue;

    // create an error object with additional info regarding failed login
    NSError *error = [FBSession errorLoginFailedWithReason:reason
                                                 errorCode:nil];

    // state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateLoginFailed
                                      error:error
                                      token:nil
                             expirationDate:nil
                                shouldCache:NO];
}

// internal notification distrubtion
- (void)notifyOfState:(FBSessionState)state {
    // TODO: implement this once we have session contributors wired up
}

// private helpers

// helper to wrap-up handler callback and state-change
- (void)transitionAndCallHandlerWithState:(FBSessionState)status
                                    error:(NSError*)error
                                    token:(NSString*)token
                           expirationDate:(NSDate*)date
                              shouldCache:(BOOL)shouldCache {

    // in case we need these after the transition
    NSString *userID = self.userID;
    NSString *accessToken = self.accessToken;
    
    // lets get the state transition out of the way
    BOOL didTransition = [self transitionToState:status
                                  andUpdateToken:token
                               andExpirationDate:date
                                     shouldCache:shouldCache];

    // if we are given a handler, we promise to call it once and only once

    // release the object's count on the handler, but retain a
    // stack ref to use as our callback outside of the lock
    FBSessionStatusHandler handler = [self.loginHandler retain];

    // the moment we transition to a terminal state, we release our handler
    // and in the unit test case, we may delete the test user
    if (didTransition && FB_ISSESSIONSTATETERMINAL(self.status)) {
        self.loginHandler = nil;
        if (self.isForUnitTesting) {
            [FBSession deleteUnitTestUser:userID accessToken:accessToken]; 
        }
    }

    // if we have a handler, call it and release our
    // final retain on the handler
    if (handler) {
        @try {
            // unsuccessful transitions don't change state and don't propegate the error object
            handler(self,
                    self.status,
                    didTransition ? error : nil);
        }
        @finally {
            // now release our stack referece
            [handler release];
        }
    }
}

- (NSString *)appBaseUrl {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            self.appID,
            self.urlSchemeSuffix];
}

- (BOOL)isForUnitTesting {
    // we use the absence of a tokenCachingStrategy to signal the instance is for unit-testing
    return self.tokenCachingStrategy == nil;
}

+ (NSString*) appIDFromPLIST {
    // ignoring small race between test and assign due to perf-only implications
    if (!FBPLISTAppID) {
        // pickup the AppID from Info.plist
        NSBundle* bundle = [NSBundle mainBundle];
        FBPLISTAppID = [bundle objectForInfoDictionaryKey:FBPLISTAppIDKey];
    }
    return FBPLISTAppID;
}

+ (NSError*)errorLoginFailedWithReason:(NSString*)errorReason
                             errorCode:(NSString*)errorCode {
    // capture reason and nested code as user info
    NSMutableDictionary* userinfo = [[NSMutableDictionary alloc] init];
    if (errorReason) {
        [userinfo setObject:errorReason
                     forKey:FBErrorLoginFailedReason];
    }
    if (errorCode) {
        [userinfo setObject:errorCode
                     forKey:FBErrorLoginFailedOriginalErrorCode];
    }

    // create error object
    NSError *err = [NSError errorWithDomain:FBiOSSDKDomain
                                      code:FBErrorLoginFailedOrCancelled
                                  userInfo:userinfo];
    [userinfo release];
    return err;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    // these properties must manually notify for KVO
    if ([key isEqualToString:FBisValidPropertyName] ||
        [key isEqualToString:FBaccessTokenPropertyName] ||
        [key isEqualToString:FBexpirationDatePropertyName] ||
        [key isEqualToString:FBstatusPropertyName]) {
        return NO;
    } else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

+ (void)deleteUnitTestUser:(NSString*)userID accessToken:(NSString*)accessToken {
    if (userID && accessToken) {
        // use FBRequest to create an NSURLRequest
        NSURLRequest *request = [FBRequest connectionWithSession:nil
                                graphPath:userID
                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                           @"delete", @"method",
                                           accessToken, @"access_token",
                                           nil]
                               HTTPMethod:nil
                        completionHandler:nil].urlRequest;
        
        // synchronously delete the user
        NSURLResponse *response;
        NSError *error = nil;
        NSData *data;
        data = [NSURLConnection sendSynchronousRequest:request 
                                     returningResponse:&response
                                                 error:&error];
        // if !data or if data == false, log
        NSString *body = !data ? nil : [[[NSString alloc] initWithData:data
                                                              encoding:NSUTF8StringEncoding]
                                         autorelease];
        if (!data || [body isEqualToString:@"false"]) {
            NSLog(@"FBSession !delete test user with id:%@ error:%@", userID, error ? error : body);
        }         
    }
}

#pragma mark -
#pragma mark Internal members

+ (void)deleteFacebookCookies {
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:@"http://login.facebook.com"]];

    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

#pragma mark -
@end
