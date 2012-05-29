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
#import "FBSession+Protected.h"
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

// const strings
static NSString *const FBPLISTAppIDKey = @"FacebookAppID";
// for unit testing mode only (DO NOT store application secrets in a published application plist)
static NSString *const FBPLISTAppSecretKey = @"FacebookAppSecret";
static NSString *const FBAuthURLScheme = @"fbauth";
static NSString *const FBAuthURLPath = @"authorize";
static NSString *const FBRedirectURL = @"fbconnect://success";
static NSString *const FBDialogBaseURL = @"https://m." FB_BASE_URL @"/dialog/";
static NSString *const FBLoginDialogMethod = @"oauth";
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

static int const FBTokenExtendThresholdSeconds = 24 * 60 * 60;  // day
static int const FBTokenRetryExtendSeconds = 60 * 60;           // hour

// module scoped globals
static NSString *FBPLISTAppID = nil;
static NSSet *g_loggingBehavior;

@interface FBSession () <FBLoginDialogDelegate> {
    @private
    // public-property ivars
    NSString *_urlSchemeSuffix;

    // private property and non-property ivars
    BOOL _isInStateTransition;
    BOOL _isSSOToken;    
}

// private setters
@property(readwrite) FBSessionState state;
@property(readwrite, copy) NSString *appID;
@property(readwrite, copy) NSString *urlSchemeSuffix;
@property(readwrite, copy) NSString *accessToken;
@property(readwrite, copy) NSDate *expirationDate;
@property(readwrite, copy) NSArray *permissions;

// private properties
@property(readwrite, retain) FBSessionTokenCachingStrategy *tokenCachingStrategy;
@property(readwrite, copy) NSDate *refreshDate;
@property(readwrite, copy) NSDate *attemptedRefreshDate;
@property(readwrite, copy) FBSessionStateHandler loginHandler;
@property(readonly) NSString *appBaseUrl;
@property(readwrite, retain) FBLoginDialog *loginDialog;
@property(readwrite, retain) NSThread *affinitizedThread;
@property(readwrite) unsigned long previousTransitionBeginTime;

// private members
- (void)notifyOfState:(FBSessionState)state;
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth
                    safariAuth:(BOOL)trySafariAuth
                      fallback:(BOOL)tryFallback;

// class members
+ (NSString*)appIDFromPLIST;
+ (BOOL)areRequiredPermissions:(NSArray*)requiredPermissions
          aSubsetOfPermissions:(NSArray*)cachedPermissions;

@end

@implementation FBSession : NSObject

@synthesize
            // public properties
            appID = _appID,
            permissions = _permissions,

            // following properties use manual KVO -- changes to names require
            // changes to static property name variables (e.g. FBisValidPropertyName)
            state = _state,
            accessToken = _accessToken,
            expirationDate = _expirationDate,

            // private properties
            tokenCachingStrategy = _tokenCachingStrategy,
            refreshDate = _refreshDate,
            attemptedRefreshDate = _attemptedRefreshDate,
            loginDialog = _loginDialog,
            affinitizedThread = _affinitizedThread,
            loginHandler = _loginHandler,
            previousTransitionBeginTime = _previousTransitionBeginTime;

#pragma mark Lifecycle

- (id)init {
    return [self initWithAppID:nil
                   permissions:nil
               urlSchemeSuffix:nil
            tokenCacheStrategy:nil];
}

- (id)initWithPermissions:(NSArray*)permissions {
    return [self initWithAppID:nil
                   permissions:permissions
               urlSchemeSuffix:nil
            tokenCacheStrategy:nil];
}

- (id)initWithAppID:(NSString*)appID
        permissions:(NSArray*)permissions
    urlSchemeSuffix:(NSString*)urlSchemeSuffix
 tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy {
    self = [super init];
    if (self) {

        // setup values where nil implies a default
        if (!appID) {
            appID = [FBSession appIDFromPLIST];    
        }
        if (!permissions) {
            permissions = [NSArray array];
        }
        if (!tokenCachingStrategy) {
            tokenCachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
        }
        
        // if we don't have an appID by here, fail -- this is almost certainly an app-bug
        if (!appID) {
            [[NSException exceptionWithName:FBInvalidOperationException
                                     reason:@"FBSession: No AppID provided; either pass an "
                                            @"AppID to init, or add a string valued key with the "
                                            @"appropriate id named FacebookAppID to the bundle *.plist"
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
        _isSSOToken = NO;
        self.attemptedRefreshDate = [NSDate distantPast];
        self.refreshDate = nil;
        self.state = FBSessionStateCreated;
        self.affinitizedThread = [NSThread currentThread];
        self.previousTransitionBeginTime = [FBUtility currentTimeInMilliseconds];

        //first notification
        [self notifyOfState:self.state];

        // use cached token if present
        NSDictionary *tokenInfo = [tokenCachingStrategy fetchTokenInformation];
        if ([FBSessionTokenCachingStrategy isValidTokenInformation:tokenInfo]) {
            NSDate *cachedTokenExpirationDate = [tokenInfo objectForKey:FBTokenInformationExpirationDateKey];
            NSString *cachedToken = [tokenInfo objectForKey:FBTokenInformationTokenKey];
                        
            // get the cached permissions, and do a subset check
            NSArray *cachedPermissions = [tokenInfo objectForKey:FBTokenInformationPermissionsKey];
            BOOL isSubset = [FBSession areRequiredPermissions:permissions
                                         aSubsetOfPermissions:cachedPermissions];

            if (isSubset &&
                // check to see if expiration date is later than now
                (NSOrderedDescending == [cachedTokenExpirationDate compare:[NSDate date]])) {           
                // if we had cached anything at all, use those
                if (cachedPermissions) {
                    self.permissions = cachedPermissions;
                }
                
                // if we have cached an optional refresh date or SSO indicator, pick them up here
                self.refreshDate = [tokenInfo objectForKey:FBTokenInformationRefreshDateKey];
                _isSSOToken = [[tokenInfo objectForKey:FBTokenInformationIsSSOKey] boolValue];
                
                // set the state and token info
                [self transitionToState:FBSessionStateCreatedTokenLoaded
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
    [_attemptedRefreshDate release];
    [_refreshDate release];
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

- (void)openWithCompletionHandler:(FBSessionStateHandler)handler {
    [self openWithBehavior:FBSessionLoginBehaviorSSOWithFallback completionHandler:handler];
}

- (void)openWithBehavior:(FBSessionLoginBehavior)behavior
    completionHandler:(FBSessionStateHandler)handler {

    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    if (!(self.state == FBSessionStateCreated ||
          self.state == FBSessionStateCreatedTokenLoaded)) {
        // login may only be called once, and only from one of the two initial states
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBSession: an attempt was made to login an already logged in or invalid"
                                        @"session"
                               userInfo:nil]
         raise];
    }
    self.loginHandler = handler;

    // normal login depends on the availability of a valid cached token
    if (self.state == FBSessionStateCreated) {
        [self authorizeWithBehavior:behavior];
    } else { // self.status == FBSessionStateLoadedValidToken
        // this case implies that a valid cached token was found, and preserves the
        // "1-session-1-identity" rule, by transitioning to logged in, without a transition to login UX
        [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                          error:nil
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO];
    }
}

- (void)close {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    [self transitionAndCallHandlerWithState:FBSessionStateClosed
                                      error:nil
                                      token:nil
                             expirationDate:nil
                                shouldCache:NO];
}

- (void)closeAndClearTokenInformation {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    [self.tokenCachingStrategy clearToken:self.accessToken];
    [self transitionAndCallHandlerWithState:FBSessionStateClosed
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
        [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                          error:error
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO];
    } else {

        // we have an access token, so parse the expiration date.
        NSString *expTime = [params objectForKey:@"expires_in"];
        NSDate *expirationDate = [FBSession expirationDateFromExpirationTimeString:expTime];
        if (!expirationDate) {
            expirationDate = [NSDate distantFuture];
        }
                
        // this is one of two ways that we get an SSO token (the other is from cache) 
        _isSSOToken = YES;
        
        // we received a token just now
        self.refreshDate = [NSDate date];

        // set token and date, state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                          error:nil
                                          token:accessToken
                                 expirationDate:expirationDate
                                    shouldCache:YES];
    }
    return YES;
}

- (BOOL)isOpen {
    return FB_ISSESSIONOPENWITHSTATE(self.state);
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

    statePrior = self.state;
    switch (state) {
        default:
        case FBSessionStateCreated:
            isValidTransition = NO;
            break;
        case FBSessionStateOpen:
            isValidTransition = (
                                 statePrior == FBSessionStateCreated ||
                                 statePrior == FBSessionStateCreatedTokenLoaded
                                 );
            break;
        case FBSessionStateCreatedTokenLoaded:
        case FBSessionStateClosedLoginFailed:
            isValidTransition = statePrior == FBSessionStateCreated;
            break;
        case FBSessionStateOpenTokenExtended:
            isValidTransition = (
                                 statePrior == FBSessionStateOpen ||
                                 statePrior == FBSessionStateOpenTokenExtended
                                 );
            break;
        case FBSessionStateClosed:
            isValidTransition = (
                                 statePrior == FBSessionStateOpen ||
                                 statePrior == FBSessionStateOpenTokenExtended ||
                                 statePrior == FBSessionStateCreatedTokenLoaded
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
    unsigned long currTime = [FBUtility currentTimeInMilliseconds];
    NSString *logString = [NSString stringWithFormat:@"FBSession transition toState:%i fromState:%i - %d msec", 
                           state, 
                           statePrior,
                           currTime - self.previousTransitionBeginTime];
    self.previousTransitionBeginTime = currTime;
    [FBLogger singleShotLogEntry:FB_LOG_BEHAVIOR_SESSION_STATE_TRANSITIONS logEntry:logString];
    [FBLogger singleShotLogEntry:FB_LOG_BEHAVIOR_PERFORMANCE_CHARACTERISTICS logEntry:logString];
    
    // identify whether we will update token and date, and what the values will be
    BOOL changingTokenAndDate = false;
    if (token && date) {
        changingTokenAndDate = true;
    } else if (!FB_ISSESSIONOPENWITHSTATE(state) &&
               FB_ISSESSIONOPENWITHSTATE(statePrior)) {
        changingTokenAndDate = true;
        token = nil;
        date = nil;
    }

    BOOL changingIsInvalid = FB_ISSESSIONOPENWITHSTATE(state) == FB_ISSESSIONOPENWITHSTATE(statePrior);

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
    self.state = state;

    // ... to here -- if YES
    _isInStateTransition = NO;

    // internal state change notification
    [self notifyOfState:state];

    if (changingTokenAndDate) {
        // update the cache
        if (shouldCache) {
            NSMutableDictionary *tokenInfo = [NSMutableDictionary dictionaryWithCapacity:4];
            // we don't consider it a valid cache without these two values
            [tokenInfo setObject:token forKey:FBTokenInformationTokenKey];
            [tokenInfo setObject:date forKey:FBTokenInformationExpirationDateKey];
            
            // but these following values are optional
            if (self.refreshDate) {
                [tokenInfo setObject:self.refreshDate forKey:FBTokenInformationRefreshDateKey];
            }
            
            if (_isSSOToken) {
                [tokenInfo setObject:[NSNumber numberWithBool:YES] forKey:FBTokenInformationIsSSOKey];
            }
            
            if (self.permissions) {
                [tokenInfo setObject:self.permissions forKey:FBTokenInformationPermissionsKey];
            }
            
            [self.tokenCachingStrategy cacheTokenInformation:tokenInfo];
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
- (void)authorizeWithBehavior:(FBSessionLoginBehavior)behavior {
    BOOL trySSO = (behavior == FBSessionLoginBehaviorSSOOnly) ||
    (behavior == FBSessionLoginBehaviorSSOWithFallback);
    BOOL tryFallback = (behavior == FBSessionLoginBehaviorSSOWithFallback) ||
    (behavior == FBSessionLoginBehaviorSuppressSSO);
    
    [self authorizeWithFBAppAuth:trySSO
                      safariAuth:trySSO
                        fallback:tryFallback];
}

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
            [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                              error:error
                                              token:nil
                                     expirationDate:nil
                                        shouldCache:NO];
        }
    }
}

- (void)refreshAccessToken:(NSString*)token 
            expirationDate:(NSDate*)expireDate {
    // refreshing now
    self.refreshDate = [NSDate date];
    
    // refresh token and date, state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                      error:nil
                                      token:token ? token : self.accessToken
                             expirationDate:expireDate
                                shouldCache:YES];
}

- (BOOL)shouldExtendAccessToken {
    BOOL result = NO;
    NSDate *now = [NSDate date];
    if (self.isOpen &&
        _isSSOToken &&
        [now timeIntervalSinceDate:self.attemptedRefreshDate] > FBTokenRetryExtendSeconds &&
        [now timeIntervalSinceDate:self.refreshDate] > FBTokenExtendThresholdSeconds) {
        result = YES;
        self.attemptedRefreshDate = now;
    }
    return result;
}

// core handler for inline UX flow
- (void)fbDialogLogin:(NSString *)accessToken expirationDate:(NSDate *)expirationDate {
    // no reason to keep this object
    self.loginDialog = nil;
    
    // though this is not SSO our policy is to cache the refresh date if we have it
    self.refreshDate = [NSDate date];

    // set token and date, state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateOpen
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
    [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
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

    
    // lets get the state transition out of the way
    BOOL didTransition = [self transitionToState:status
                                  andUpdateToken:token
                               andExpirationDate:date
                                     shouldCache:shouldCache];

    // if we are given a handler, we promise to call it once and only once

    // release the object's count on the handler, but copy (not retain, since it is a block)
    // a stack ref to use as our callback outside of the lock
    FBSessionStateHandler handler = [self.loginHandler retain];

    // the moment we transition to a terminal state, we release our handler
    // and in the unit test case, we may delete the test user
    if (didTransition && FB_ISSESSIONSTATETERMINAL(self.state)) {
        self.loginHandler = nil;
    }

    // if we have a handler, call it and release our
    // final retain on the handler
    if (handler) {
        @try {
            // unsuccessful transitions don't change state and don't propagate the error object
            handler(self,
                    self.state,
                    didTransition ? error : nil);
        }
        @finally {
            // now release our stack reference
            [handler release];
        }
    }
}

- (NSString *)appBaseUrl {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            self.appID,
            self.urlSchemeSuffix];
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

+ (BOOL)areRequiredPermissions:(NSArray*)requiredPermissions
          aSubsetOfPermissions:(NSArray*)cachedPermissions {
    NSSet *required = [NSSet setWithArray:requiredPermissions];
    NSSet *cached = [NSSet setWithArray:cachedPermissions];
    return [required isSubsetOfSet:cached];
}

#pragma mark -
#pragma mark Internal members

+ (void)deleteFacebookCookies {
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:@"http://login." FB_BASE_URL]];

    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

+ (NSDate*)expirationDateFromExpirationTimeString:(NSString*)expirationTime {
    NSDate *expirationDate = nil;
    if (expirationTime != nil) {
        int expValue = [expirationTime intValue];
        if (expValue != 0) {
            expirationDate = [NSDate dateWithTimeIntervalSinceNow:expValue];
        }
    }
    return expirationDate;
}

#pragma mark -
@end
