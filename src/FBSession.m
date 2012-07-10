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
#define TEST_DISABLE_MULTITASKING_LOGIN NO
#define TEST_DISABLE_FACEBOOKLOGIN NO

// this macro turns on IOS6 preview support
#ifdef __IPHONE_6_0
#define IOS6_PREVIEW_SUPPORT
#endif

// we turn this on for 5 so that we can build our production libs using a production compiler,
// rather than a preview compiler -- however integrated Facebook support will only be on when running on 6
#ifdef __IPHONE_5_0
#define IOS6_PREVIEW_SUPPORT
#endif

#ifdef IOS6_PREVIEW_SUPPORT
// we dynamically bind to a few methods, and this protocol helps
// us manage warnings from the call-sites
@protocol FBWarningHelperProtocol
- (id)accountTypeWithAccountTypeIdentifier:(id)type;
- (void)requestAccessToAccountsWithType:(id)accountTypeFB
                                options:(id)options
                             completion:(id)handler;
- (NSArray*)accountsWithAccountType:(id)type;
- (id)credential;
- (id)oauthToken;
@end
#endif

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

NSString *const FBLogBehaviorFBRequests = @"fb_requests";
NSString *const FBLogBehaviorFBURLConnections = @"fburl_connections";
NSString *const FBLogBehaviorAccessTokens = @"include_access_tokens";
NSString *const FBLogBehaviorSessionStateTransitions = @"state_transitions";
NSString *const FBLogBehaviorPerformanceCharacteristics = @"perf_characteristics";

// the following constant strings are used by NSNotificationCenter
NSString *const FBSessionDidSetActiveSessionNotification = @"com.facebook.FBiOSSDK:FBSessionDidSetActiveSessionNotification";
NSString *const FBSessionDidUnsetActiveSessionNotification = @"com.facebook.FBiOSSDK:FBSessionDidUnsetActiveSessionNotification";

// the following const strings name properties for which KVO is manually handled
// if name changes occur, these strings must be modified to match, else KVO will fail
static NSString *const FBisValidPropertyName = @"isValid";
static NSString *const FBstatusPropertyName = @"status";
static NSString *const FBaccessTokenPropertyName = @"accessToken";
static NSString *const FBexpirationDatePropertyName = @"expirationDate";

static int const FBTokenExtendThresholdSeconds = 24 * 60 * 60;  // day
static int const FBTokenRetryExtendSeconds = 60 * 60;           // hour

// module scoped globals
static NSString *g_defaultAppID = nil;
static FBSession *g_activeSession = nil;
static NSSet *g_loggingBehavior;

@interface FBSession () <FBLoginDialogDelegate> {
    @private
    // public-property ivars
    NSString *_urlSchemeSuffix;

    // private property and non-property ivars
    BOOL _isInStateTransition;
    BOOL _isFacebookLoginToken;    
}

// private setters
@property(readwrite)            FBSessionState state;
@property(readwrite, copy)      NSString *appID;
@property(readwrite, copy)      NSString *urlSchemeSuffix;
@property(readwrite, copy)      NSString *accessToken;
@property(readwrite, copy)      NSDate *expirationDate;
@property(readwrite, copy)      NSArray *permissions;

// private properties
@property(readwrite, retain)    FBSessionTokenCachingStrategy *tokenCachingStrategy;
@property(readwrite, copy)      NSDate *refreshDate;
@property(readwrite, copy)      NSDate *attemptedRefreshDate;
@property(readwrite, copy)      FBSessionStateHandler loginHandler;
@property(readwrite, copy)      FBSessionReauthorizeResultHandler reauthorizeHandler;
@property(readwrite, copy)      NSArray *reauthorizePermissions;
@property(readonly)             NSString *appBaseUrl;
@property(readwrite, retain)    FBLoginDialog *loginDialog;
@property(readwrite, retain)    NSThread *affinitizedThread;

// private members
- (void)notifyOfState:(FBSessionState)state;
- (void)authorizeWithPermissions:(NSArray*)permissions
                  integratedAuth:(BOOL)tryIntegratedAuth
                       FBAppAuth:(BOOL)tryFBAppAuth
                      safariAuth:(BOOL)trySafariAuth
                        fallback:(BOOL)tryFallback;
- (BOOL)handleOpenURLPreOpen:(NSDictionary*)parameters
                 accessToken:(NSString*)accessToken;
- (BOOL)handleOpenURLReauthorize:(NSDictionary*)parameters
                     accessToken:(NSString*)accessToken;
- (void)callReauthorizeHandlerAndClearState:(NSError*)error;

// class members
+ (BOOL)areRequiredPermissions:(NSArray*)requiredPermissions
          aSubsetOfPermissions:(NSArray*)cachedPermissions;
+ (NSString *)sessionStateDescription:(FBSessionState)sessionState;

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
            reauthorizeHandler = _reauthorizeHandler,
            reauthorizePermissions = _reauthorizePermissions;

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
            appID = [FBSession defaultAppID];    
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
        _isFacebookLoginToken = NO;
        self.attemptedRefreshDate = [NSDate distantPast];
        self.refreshDate = nil;
        self.state = FBSessionStateCreated;
        self.affinitizedThread = [NSThread currentThread];
        [FBLogger registerCurrentTime:FBLogBehaviorPerformanceCharacteristics
                              withTag:self];
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
                
                // if we have cached an optional refresh date or Facebook Login indicator, pick them up here
                self.refreshDate = [tokenInfo objectForKey:FBTokenInformationRefreshDateKey];
                _isFacebookLoginToken = [[tokenInfo objectForKey:FBTokenInformationIsFacebookLoginKey] boolValue];
                
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
    [_reauthorizeHandler release];
    [_loginHandler release];
    [_reauthorizePermissions release];
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
    [self openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView completionHandler:handler];
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

        // set the state and token info
        [self transitionToState:FBSessionStateCreatedOpening
                 andUpdateToken:nil
              andExpirationDate:nil
                    shouldCache:NO];

        [self authorizeWithPermissions:self.permissions
                              behavior:behavior];

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

- (void)reauthorizeWithPermissions:(NSArray*)permissions
                          behavior:(FBSessionLoginBehavior)behavior
                 completionHandler:(FBSessionReauthorizeResultHandler)handler {

    if (!self.isOpen) {
        // session must be open in order to reauthorize
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBSession: an attempt was made reauthorize permissions on an unopened session"
                               userInfo:nil]
         raise];
    }
        
    if (self.reauthorizeHandler) {
        // block must be cleared (meaning it has been called back) before a reauthorize can happen again
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBSession: It is not valid to reauthorize while a previous "
                                        @"reauthorize call has not yet completed."
                               userInfo:nil]
         raise];
    }

    // setup handler and permissions and perform the actual reauthorize
    self.reauthorizePermissions = permissions;
    self.reauthorizeHandler = handler;
    [self authorizeWithPermissions:permissions
                          behavior:behavior];
}

- (void)close {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    FBSessionState state; 
    if (self.state == FBSessionStateCreatedOpening) {
        state = FBSessionStateClosedLoginFailed;
    } else {
        state = FBSessionStateClosed;
    }

    [self transitionAndCallHandlerWithState:state
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
    
    switch (self.state) {
        case FBSessionStateCreatedOpening:
            return [self handleOpenURLPreOpen:params
                                  accessToken:accessToken];
        case FBSessionStateOpen:
        case FBSessionStateOpenTokenExtended:
            return [self handleOpenURLReauthorize:params
                                      accessToken:accessToken];
        default:
            NSAssert(NO, @"handleOpenURL should not be called once a session has closed");
            return NO;
    }
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

/*!
 @abstract
 This is the simplest method for opening a session with Facebook. Using sessionOpen logs on a user,
 and sets the static activeSession which becomes the default session object for any Facebook UI controls
 used by the application.
 */
+ (FBSession*)sessionOpen {
    return [FBSession sessionOpenWithPermissions:nil
                               completionHandler:nil];
}

+ (FBSession*)sessionOpenWithPermissions:(NSArray*)permissions
                       completionHandler:(FBSessionStateHandler)handler {
    FBSession *session = [[[FBSession alloc] initWithPermissions:permissions] autorelease];
    [FBSession setActiveSession:session];
    // we open after the fact, in order to avoid overlapping close
    // and open handler calls for blocks
    [session openWithCompletionHandler:handler];
    return session;
}

+ (FBSession*)activeSession {
    if (!g_activeSession) {
        FBSession *session = [[FBSession alloc] init];
        [FBSession setActiveSession:session];
        [session release];
    }
    return [[g_activeSession retain] autorelease];
}

+ (FBSession*)setActiveSession:(FBSession*)session {
    
    // we will close this, but we want any resulting 
    // handlers to see the new active session
    FBSession *toRelease = g_activeSession;
    
    g_activeSession = [session retain];
    
    // some housekeeping needs to happen if we had a previous session
    if (toRelease) {
        // now the actual close/notification/release of the prior active
        [toRelease close];
        [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidUnsetActiveSessionNotification
                                                            object:toRelease];
        [toRelease release];
    }
    
    // we don't notify nil sets
    if (session) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidSetActiveSessionNotification
                                                            object:session];
    }
    
    return session;
}


+ (NSSet *)loggingBehavior {
    return g_loggingBehavior;
}

+ (void)setLoggingBehavior:(NSSet *)newValue {
    [g_loggingBehavior release];
    g_loggingBehavior = newValue;
    [g_loggingBehavior retain];
}

+ (void)setDefaultAppID:(NSString*)appID {
    NSString *oldValue = g_defaultAppID;
    g_defaultAppID = [appID copy];
    [oldValue release];
}

+ (NSString*)defaultAppID {
    if (!g_defaultAppID) {
        NSBundle* bundle = [NSBundle mainBundle];
        g_defaultAppID = [bundle objectForInfoDictionaryKey:FBPLISTAppIDKey];
    }
    return g_defaultAppID;
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
                                 statePrior == FBSessionStateCreatedTokenLoaded ||
                                 statePrior == FBSessionStateCreatedOpening
                                 );
            break;
        case FBSessionStateCreatedOpening:
        case FBSessionStateCreatedTokenLoaded:
            isValidTransition = statePrior == FBSessionStateCreated;
            break;
        case FBSessionStateClosedLoginFailed:
            isValidTransition = statePrior == FBSessionStateCreatedOpening;
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
        [FBLogger singleShotLogEntry:FBLogBehaviorSessionStateTransitions
                            logEntry:[NSString stringWithFormat:@"FBSession **INVALID** transition from %@ to %@",
                                      [FBSession sessionStateDescription:statePrior],
                                      [FBSession sessionStateDescription:state]]];
        return NO;
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
    NSString *logString = [NSString stringWithFormat:@"FBSession transition from %@ to %@ ",
                           [FBSession sessionStateDescription:statePrior],
                           [FBSession sessionStateDescription:state]];
    [FBLogger singleShotLogEntry:FBLogBehaviorSessionStateTransitions logEntry:logString];
    
    [FBLogger singleShotLogEntry:FBLogBehaviorPerformanceCharacteristics 
                    timestampTag:self
                    formatString:@"%@", logString];
    
    // Re-start session transition timer for the next time around.
    [FBLogger registerCurrentTime:FBLogBehaviorPerformanceCharacteristics
                          withTag:self];
    
    // identify whether we will update token and date, and what the values will be
    BOOL changingTokenAndDate = NO;
    if (token && date) {
        changingTokenAndDate = YES;
    } else if (!FB_ISSESSIONOPENWITHSTATE(state) &&
               FB_ISSESSIONOPENWITHSTATE(statePrior)) {
        changingTokenAndDate = YES;
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
            
            if (_isFacebookLoginToken) {
                [tokenInfo setObject:[NSNumber numberWithBool:YES] forKey:FBTokenInformationIsFacebookLoginKey];
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
    return YES;
}

// core authorization UX flow
- (void)authorizeWithPermissions:(NSArray*)permissions
                        behavior:(FBSessionLoginBehavior)behavior {
    BOOL tryFacebookLogin = (behavior == FBSessionLoginBehaviorWithFallbackToWebView) ||
                            (behavior == FBSessionLoginBehaviorWithNoFallbackToWebView);
    BOOL tryFallback =  (behavior == FBSessionLoginBehaviorWithFallbackToWebView) ||
                        (behavior == FBSessionLoginBehaviorForcingWebView);
    
    [self authorizeWithPermissions:(NSArray*)permissions
                    integratedAuth:tryFacebookLogin
                         FBAppAuth:tryFacebookLogin
                        safariAuth:tryFacebookLogin
                          fallback:tryFallback];
}

- (void)authorizeWithPermissions:(NSArray*)permissions
                  integratedAuth:(BOOL)tryIntegratedAuth
                       FBAppAuth:(BOOL)tryFBAppAuth
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

    if (permissions != nil) {
        NSString* scope = [permissions componentsJoinedByString:@","];
        [params setValue:scope forKey:@"scope"];
    }

    if (_urlSchemeSuffix) {
        [params setValue:_urlSchemeSuffix forKey:@"local_client_id"];
    }

    // To avoid surprises, delete any cookies we currently have.
    [FBSession deleteFacebookCookies];
    
    // when iOS 6 ships we will have enough cases here to justify refactoring to a nicer
    // approach to managing our fallback auth methods -- however while we are still previewing
    // iOS 6 functionality, we will keep the logic essentially as is, with a series of ifs

    BOOL didAuthNWithSystemAccount = NO;
    
#ifdef IOS6_PREVIEW_SUPPORT
    id accountStore = nil;
    id accountTypeFB = nil;
    // do we want and have the ability to attempt integrated authn
    if (tryIntegratedAuth &&
        (accountStore = [[[NSClassFromString(@"ACAccountStore") alloc] init] autorelease]) &&
        (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"])) {
                
        // looks like we will get to attempt a login with integrated authn
        didAuthNWithSystemAccount = YES;
        
        // BUG: this works around a bug in the current iOS preview that requires
        // at least one permission in order to get an access token -- user_likes
        // was selected as a generally innocuous permission to request in the case
        // where the application only needs basic access; will remove in production
        NSArray *permissionsToUse = permissions;
        if (!permissionsToUse.count) {
            permissionsToUse = [NSArray arrayWithObject:@"user_likes"];
        }
        
        // construct access options
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 self.appID, @"ACFacebookAppIdKey",
                                 permissionsToUse, @"ACFacebookPermissionsKey",
                                 @"read_write", @"ACFacebookPermissionGroupKey",
                                 nil];
        
        // we will attempt an iOS integrated facebook login
        [accountStore requestAccessToAccountsWithType:accountTypeFB
                                              options:options
                                           completion:^(BOOL granted, NSError *error) {
                                               // requestAccessToAccountsWithType:options:completion: completes on an
                                               // arbitrary thread; let's process this back on our main thread
                                               dispatch_async( dispatch_get_main_queue(), ^{
                                                   NSString *oauthToken = nil;
                                                   if (granted) {
                                                       NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
                                                       id account = [fbAccounts objectAtIndex:0];
                                                       id credential = [account credential];
                                                       
                                                       oauthToken = [credential oauthToken];
                                                   }
                                                   
                                                   if (oauthToken) {
                                                       // this is one of two ways that we get an Facebook Login token (the other is from cache)
                                                       _isFacebookLoginToken = YES;
                                                       
                                                       // we received a token just now
                                                       self.refreshDate = [NSDate date];
                                                       
                                                       // set token and date, state transition, and call the handler if there is one
                                                       [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                                                                         error:nil
                                                                                         token:oauthToken
                                                        // BUG: we need a means for fetching the expiration date of the token
                                                                                expirationDate:[NSDate distantFuture]
                                                                                   shouldCache:YES];
                                                   } else {
                                                       // BUG: in all failed cases we fall back to other authn schemes,
                                                       // in order to allow for some instability in the new API; post
                                                       // preview, a failed integrated authentication will result in a
                                                       // failed login for the session
                                                       [self authorizeWithPermissions:permissions
                                                                       integratedAuth:NO
                                                                            FBAppAuth:YES
                                                                           safariAuth:YES
                                                                             fallback:YES];
                                                   }
                                               });
                                           }];
    }
#endif

    // If the device is running a version of iOS that supports multitasking,
    // try to obtain the access token from the Facebook app installed
    // on the device.
    // If the Facebook app isn't installed or it doesn't support
    // the fbauth:// URL scheme, fall back on Safari for obtaining the access token.
    // This minimizes the chance that the user will have to enter his or
    // her credentials in order to authorize the application.
    UIDevice *device = [UIDevice currentDevice];
    if (!didAuthNWithSystemAccount &&
        [device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported] &&
        !TEST_DISABLE_MULTITASKING_LOGIN) {
        if (tryFBAppAuth &&
            !TEST_DISABLE_FACEBOOKLOGIN) {
            NSString *scheme = FBAuthURLScheme;
            if (_urlSchemeSuffix) {
                scheme = [scheme stringByAppendingString:@"2"];
            }
            NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, FBAuthURLPath];
            NSString *fbAppUrl = [FBRequest serializeURL:urlPrefix params:params];
            didAuthNWithSystemAccount = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }

        if (trySafariAuth && !didAuthNWithSystemAccount) {
            NSString *nextUrl = self.appBaseUrl;
            [params setValue:nextUrl forKey:@"redirect_uri"];

            NSString *fbAppUrl = [FBRequest serializeURL:loginDialogURL params:params];
            didAuthNWithSystemAccount = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }
    }

    // If single sign-on failed, see if we should attempt to fallback
    if (!didAuthNWithSystemAccount) {
        if (tryFallback) {
            // open an inline login dialog. This will require the user to enter his or her credentials.
            self.loginDialog = [[[FBLoginDialog alloc] initWithURL:loginDialogURL
                                                       loginParams:params
                                                          delegate:self]
                                autorelease];
            [self.loginDialog show];
        } else {
            // Can't fallback and Facebook Login failed, so transition to an error state
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

- (BOOL)handleOpenURLPreOpen:(NSDictionary*)parameters
                 accessToken:(NSString*)accessToken {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [parameters objectForKey:@"error"];
        
        // if the error response indicates that we should try again using Safari, open
        // the authorization dialog in Safari.
        if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
            [self authorizeWithPermissions:self.permissions
                            integratedAuth:NO
                                 FBAppAuth:NO
                                safariAuth:YES
                                  fallback:NO];
            return YES;
        }
        
        // if the error response indicates that we should try the authorization flow
        // in an inline dialog, do that.
        if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
            [self authorizeWithPermissions:self.permissions
                            integratedAuth:NO
                                 FBAppAuth:NO
                                safariAuth:NO
                                  fallback:NO];
            return YES;
        }
        
        // the facebook app may return an error_code parameter in case it
        // encounters a UIWebViewDelegate error
        NSString *errorCode = [parameters objectForKey:@"error_code"];
        
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
        NSString *expTime = [parameters objectForKey:@"expires_in"];
        NSDate *expirationDate = [FBSession expirationDateFromExpirationTimeString:expTime];
        if (!expirationDate) {
            expirationDate = [NSDate distantFuture];
        }
        
        // this is one of two ways that we get an Facebook Login token (the other is from cache) 
        _isFacebookLoginToken = YES;
        
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

- (BOOL)handleOpenURLReauthorize:(NSDictionary*)parameters
                     accessToken:(NSString*)accessToken {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        // no token in this case implies that the user cancelled the permissions upgrade
        NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                     errorCode:nil];
        [self callReauthorizeHandlerAndClearState:error];
    } else {
        
        // we have an access token, so parse the expiration date.
        NSString *expTime = [parameters objectForKey:@"expires_in"];
        NSDate *expirationDate = [FBSession expirationDateFromExpirationTimeString:expTime];
        if (!expirationDate) {
            expirationDate = [NSDate distantFuture];
        }
        
        // now we are going to kick-off a batch request, where we confirm that the new token
        // refers to the same fbid as the old, and if so we will succeed the reauthorize call
        FBRequest *requestSessionMe = [FBRequest requestForGraphPath:@"me"];
        [requestSessionMe setSession:self];
        FBRequest *requestNewTokenMe = [[[FBRequest alloc] initWithSession:nil
                                                                 graphPath:@"me"
                                                                parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                            accessToken, @"access_token",
                                                                            nil]
                                                                HTTPMethod:nil]
                                        autorelease];
        
        FBRequest *requestPermissions = [FBRequest requestForGraphPath:@"me/permissions"];
        [requestPermissions setSession:self];

        // we create a block here with related state -- which will be the main handler block for all
        // three requests -- wrapped by smaller blocks to provide context
        
        // we will use these to compare fbid's
        __block id fbid = nil;
        __block id fbid2 = nil;
        __block id permissionsRefreshed = nil;
        // and this to assure we notice when we have been called three times
        __block int callsPending = 3;
        
        void (^handleBatch)(id<FBGraphUser>,id) = [^(id<FBGraphUser> user,
                                                     id permissions) {
            
            // here we accumulate state from the various callbacks
            if (user && !fbid) {
                fbid = [[user objectForKey:@"id"] retain];
            } else if (user && !fbid2) {
                fbid2 = [[user objectForKey:@"id"] retain];
            } else if (permissions) {
                permissionsRefreshed = [permissions retain];
            }
            
            // if this was our last call, then complete the operation
            if (!--callsPending) {
                if ([fbid isEqual:fbid2]) {
                    // this is one of two ways that we get an Facebook Login token (the other is from cache) 
                    _isFacebookLoginToken = YES;
                    
                    // we received a token just now
                    self.refreshDate = [NSDate date];
                    
                    // if viable, use the latest permissions as the new effective permissions
                    id newPermissions = [[permissionsRefreshed objectAtIndex:0] allKeys];
                    if ([newPermissions isKindOfClass:[NSArray class]]) {
                        self.permissions = newPermissions;
                    }
                    
                    // set token and date, state transition, and call the handler if there is one
                    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                                      error:nil
                                                      token:accessToken
                                             expirationDate:expirationDate
                                                shouldCache:YES];
                    
                    // no error, ack a completed permission upgrade
                    [self callReauthorizeHandlerAndClearState:nil];
                } else {
                    // no we don't have matching FBIDs, then we fail on these grounds
                    NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonWrongUser
                                                                 errorCode:nil];
                    [self callReauthorizeHandlerAndClearState:error];
                }
                
                // because these are __block, we manually handle their lifetime
                [fbid release];
                [fbid2 release];
                [permissionsRefreshed release];
            }
        } copy];
                
        FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
        [connection addRequest:requestSessionMe
             completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> user, NSError *error) {
                 handleBatch(user, nil);
             }];
        
        [connection addRequest:requestNewTokenMe
             completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> user, NSError *error) {
                 handleBatch(user, nil);
             }];
        
        [connection addRequest:requestPermissions
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             handleBatch(nil, [result objectForKey:@"data"]);
         }];
        
        [connection start];
    }
    return YES;    
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
        _isFacebookLoginToken &&
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
    
    // though this is not Facebook Login our policy is to cache the refresh date if we have it
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

    // if we are given a handler, we promise to call it once per transition from open to close

    // release the object's count on the handler, but copy (not retain, since it is a block)
    // a stack ref to use as our callback outside of the lock
    FBSessionStateHandler handler = [self.loginHandler retain];

    // the moment we transition to a terminal state, we release our handlers, and possibly fail-call reauthorize
    if (didTransition && FB_ISSESSIONSTATETERMINAL(self.state)) {
        self.loginHandler = nil;

        NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonSessionClosed
                                                     errorCode:nil];
        [self callReauthorizeHandlerAndClearState:error];
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

- (void)callReauthorizeHandlerAndClearState:(NSError*)error {
    // clear state and call handler
    FBSessionReauthorizeResultHandler reauthorizeHandler = [self.reauthorizeHandler retain];
    self.reauthorizeHandler = nil;
    self.reauthorizePermissions = nil;
    if (reauthorizeHandler) {
        reauthorizeHandler(self, error); 
    }
    [reauthorizeHandler release];
}

- (NSString *)appBaseUrl {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            self.appID,
            self.urlSchemeSuffix];
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

+ (FBSession*)activeSessionIfOpen {
    if (g_activeSession.isOpen) {
        return FBSession.activeSession;
    }
    return nil;
}

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
#pragma mark Debugging helpers

+ (NSString *)sessionStateDescription:(FBSessionState)sessionState {
    NSString *stateDescription = nil;
    switch (sessionState) {
        case FBSessionStateCreated: 
            stateDescription = @"FBSessionStateCreated"; 
            break;
        case FBSessionStateCreatedTokenLoaded: 
            stateDescription = @"FBSessionStateCreatedTokenLoaded";
            break;
        case FBSessionStateOpen:
            stateDescription = @"FBSessionStateOpen";
            break;
        case FBSessionStateOpenTokenExtended:
            stateDescription = @"FBSessionStateOpenTokenExtended";
            break;
        case FBSessionStateClosedLoginFailed:
            stateDescription = @"FBSessionStateClosedLoginFailed";
            break;
        case FBSessionStateClosed:
            stateDescription = @"FBSessionStateClosed";
            break;
        default:
            stateDescription = @"[Unknown]";
            break;
    }
    
    return stateDescription;
}


- (NSString*)description {
    NSString *stateDescription = [FBSession sessionStateDescription:self.state];
	return [NSString stringWithFormat:@"<%@: %p, state: %@, loginHandler: %p, appID: %@, urlSchemeSuffix: %@, tokenCachingStrategy:%@, expirationDate: %@, refreshDate: %@, attemptedRefreshDate: %@, permissions:%@>",
            NSStringFromClass([self class]), 
            self, 
            stateDescription,
            self.loginHandler,
            self.appID,
            self.urlSchemeSuffix,
            [self.tokenCachingStrategy description],
            self.expirationDate,
            self.refreshDate,
            self.attemptedRefreshDate,
            [self.permissions description]];    
}

#pragma mark -

@end
