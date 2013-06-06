/*
 * Copyright 2010-present Facebook.
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
#import <Accounts/Accounts.h>
#import "FBSession.h"
#import "FBSession+Internal.h"
#import "FBSession+Protected.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBSettings.h"
#import "FBSettings+Internal.h"
#import "FBError.h"
#import "FBLogger.h"
#import "FBUtility.h"
#import "FBDataDiskCache.h"
#import "FBSystemAccountStoreAdapter.h"
#import "FBAccessTokenData+Internal.h"
#import "FBInsights.h"
#import "FBInsights+Internal.h"
#import "FBLoginDialogParams.h"
#import "FBAppCall+Internal.h"
#import "FBDialogs+Internal.h"
#import "FBAppBridge.h"

// the sooner we can remove these the better
#import "Facebook.h"
#import "FBLoginDialog.h"

// these are helpful macros for testing various login methods, should always checkin as NO/NO
#define TEST_DISABLE_MULTITASKING_LOGIN NO
#define TEST_DISABLE_FACEBOOKLOGIN NO
#define TEST_DISABLE_FACEBOOKNATIVELOGIN NO

// for unit testing mode only (DO NOT store application secrets in a published application plist)
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

// client state related strings
NSString *const FBLoginUXClientState = @"state";
NSString *const FBLoginUXClientStateIsClientState = @"com.facebook.sdk_client_state";
NSString *const FBLoginUXClientStateIsOpenSession = @"is_open_session";
NSString *const FBLoginUXClientStateIsActiveSession = @"is_active_session";

// the following constant strings are used by NSNotificationCenter
NSString *const FBSessionDidSetActiveSessionNotification = @"com.facebook.sdk:FBSessionDidSetActiveSessionNotification";
NSString *const FBSessionDidUnsetActiveSessionNotification = @"com.facebook.sdk:FBSessionDidUnsetActiveSessionNotification";
NSString *const FBSessionDidBecomeOpenActiveSessionNotification = @"com.facebook.sdk:FBSessionDidBecomeOpenActiveSessionNotification";
NSString *const FBSessionDidBecomeClosedActiveSessionNotification = @"com.facebook.sdk:FBSessionDidBecomeClosedActiveSessionNotification";

// the following const strings name properties for which KVO is manually handled
// if name changes occur, these strings must be modified to match, else KVO will fail
static NSString *const FBisOpenPropertyName = @"isOpen";
static NSString *const FBstatusPropertyName = @"state";
static NSString *const FBaccessTokenPropertyName = @"accessToken";
static NSString *const FBexpirationDatePropertyName = @"expirationDate";
static NSString *const FBaccessTokenDataPropertyName = @"accessTokenData";

static int const FBTokenExtendThresholdSeconds = 24 * 60 * 60;  // day
static int const FBTokenRetryExtendSeconds = 60 * 60;           // hour

// the following constant strings are used as keys into response url parameters during authorization flow

// Key used to access an inner error object in the response parameters. Currently used by Native Login only.
NSString *const FBInnerErrorObjectKey = @"inner_error_object";

NSString *const FacebookNativeApplicationLoginDomain = @"com.facebook.Facebook.platform.login";

// module scoped globals
static FBSession *g_activeSession = nil;

@interface FBSession () <FBLoginDialogDelegate> {
    @protected
    // public-property ivars
    NSString *_urlSchemeSuffix;

    // private property and non-property ivars
    BOOL _isInStateTransition;
    FBSessionLoginType _loginTypeOfPendingOpenUrlCallback;
    FBSessionDefaultAudience _defaultDefaultAudience;
}

// private setters
@property(readwrite)            FBSessionState state;
@property(readwrite, copy)      NSString *appID;
@property(readwrite, copy)      NSString *urlSchemeSuffix;
@property(readwrite, copy)      FBAccessTokenData *accessTokenData;
@property(readwrite, copy)      NSArray *initializedPermissions;
@property(readwrite, assign)    FBSessionDefaultAudience lastRequestedSystemAudience;

// private properties
@property(readwrite, retain)    FBSessionTokenCachingStrategy *tokenCachingStrategy;
@property(readwrite, copy)      NSDate *attemptedRefreshDate;
@property(readwrite, copy)      FBSessionStateHandler loginHandler;
@property(readwrite, copy)      FBSessionRequestPermissionResultHandler reauthorizeHandler;
@property(readwrite, copy)      NSArray *reauthorizePermissions;
@property(readonly)             NSString *appBaseUrl;
@property(readwrite, retain)    FBLoginDialog *loginDialog;
@property(readwrite, retain)    NSThread *affinitizedThread;
@property(readwrite, retain)    FBSessionInsightsState *insightsState;

@end

@implementation FBSession : NSObject

@synthesize
            // public properties
            appID = _appID,

            // following properties use manual KVO -- changes to names require
            // changes to static property name variables (e.g. FBisOpenPropertyName)
            state = _state,
            accessTokenData = _accessTokenData,

            // private properties
            initializedPermissions = _initializedPermissions,
            tokenCachingStrategy = _tokenCachingStrategy,
            attemptedRefreshDate = _attemptedRefreshDate,
            loginDialog = _loginDialog,
            affinitizedThread = _affinitizedThread,
            loginHandler = _loginHandler,
            reauthorizeHandler = _reauthorizeHandler,
            reauthorizePermissions = _reauthorizePermissions,
            lastRequestedSystemAudience = _lastRequestedSystemAudience,
            insightsState = _insightsState;

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
    return [self initWithAppID:appID
                   permissions:permissions
               defaultAudience:FBSessionDefaultAudienceNone
               urlSchemeSuffix:urlSchemeSuffix
            tokenCacheStrategy:tokenCachingStrategy];
}

- (id)initWithAppID:(NSString*)appID
        permissions:(NSArray*)permissions
    defaultAudience:(FBSessionDefaultAudience)defaultAudience
    urlSchemeSuffix:(NSString*)urlSchemeSuffix
 tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy {
    self = [super init];
    if (self) {

        // setup values where nil implies a default
        if (!appID) {
            appID = [FBSettings defaultAppID];
        }
        if (!permissions) {
            permissions = [NSArray array];
        }
        if (!urlSchemeSuffix) {
            urlSchemeSuffix = [FBSettings defaultUrlSchemeSuffix];
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
        self.initializedPermissions = permissions;
        self.urlSchemeSuffix = urlSchemeSuffix;
        self.tokenCachingStrategy = tokenCachingStrategy;

        // additional setup
        _isInStateTransition = NO;
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
        _defaultDefaultAudience = defaultAudience;
        _insightsState = [[FBSessionInsightsState alloc] init];

        self.attemptedRefreshDate = [NSDate distantPast];
        self.state = FBSessionStateCreated;
        self.affinitizedThread = [NSThread currentThread];
        [FBLogger registerCurrentTime:FBLoggingBehaviorPerformanceCharacteristics
                              withTag:self];
        FBAccessTokenData *cachedTokenData = [self.tokenCachingStrategy fetchFBAccessTokenData];
        if (cachedTokenData && ![self initializeFromCachedToken:cachedTokenData withPermissions:permissions]){
            [self.tokenCachingStrategy clearToken];
        };

        [FBSettings autoPublishInstall:self.appID];
    }
    return self;
}

// Helper method to initialize current state from a cached token. This will transition to
// FBSessionStateCreatedTokenLoaded if the `cachedToken` is viable and return YES. Otherwise, it returns NO.
// This method will return NO immediately if the current state is not FBSessionStateCreated.
- (BOOL)initializeFromCachedToken:(FBAccessTokenData *) cachedToken withPermissions:(NSArray *)permissions
{
    if (cachedToken && self.state == FBSessionStateCreated) {
        BOOL isSubset = [FBSession areRequiredPermissions:permissions
                                     aSubsetOfPermissions:cachedToken.permissions];
        
        if (isSubset && (NSOrderedDescending == [cachedToken.expirationDate compare:[NSDate date]])) {
            self.initializedPermissions = cachedToken.permissions;
            
            [self transitionToState:FBSessionStateCreatedTokenLoaded
                     andUpdateToken:cachedToken.accessToken
                  andExpirationDate:cachedToken.expirationDate
                        shouldCache:NO
                          loginType:cachedToken.loginType];
            // Task #2015922 - refactor transitionToState methods to use FBAccessTokenData
            // so that we do not need to manually set these additional fields that
            // are lost inside transitionToState.
            self.accessTokenData.refreshDate = cachedToken.refreshDate;
            return YES;
        }
    }
    return NO;
}

- (void)dealloc {
    [_loginDialog release]; 
    [_attemptedRefreshDate release];
    [_accessTokenData release];
    [_reauthorizeHandler release];
    [_loginHandler release];
    [_reauthorizePermissions release];
    [_appID release];
    [_urlSchemeSuffix release];
    [_initializedPermissions release];
    [_tokenCachingStrategy release];
    [_affinitizedThread release];
    [_insightsState release];

    [super dealloc];
}

#pragma mark - Public Properties

- (NSArray *)permissions {
    if (self.accessTokenData) {
        return self.accessTokenData.permissions;
    } else {
        return self.initializedPermissions;
    }
}

- (NSDate *)refreshDate {
    return self.accessTokenData.refreshDate;
}

- (NSString *)accessToken {
    return self.accessTokenData.accessToken;
}

- (NSDate *)expirationDate {
    return self.accessTokenData.expirationDate;
}

- (FBSessionLoginType) loginType {
    if (self.accessTokenData) {
        return self.accessTokenData.loginType;
    } else {
        return FBSessionLoginTypeNone;
    }
}

#pragma mark - Public Members

- (void)openWithCompletionHandler:(FBSessionStateHandler)handler {
    [self openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView completionHandler:handler];
}

- (void)openWithBehavior:(FBSessionLoginBehavior)behavior
       completionHandler:(FBSessionStateHandler)handler {

    [self checkThreadAffinity];

    if (!(self.state == FBSessionStateCreated ||
          self.state == FBSessionStateCreatedTokenLoaded)) {
        // login may only be called once, and only from one of the two initial states
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:@"FBSession: an attempt was made to open an already opened or closed session"
                               userInfo:nil]
         raise];
    }
    if (handler != nil) {
        if (self.loginHandler == nil) {
            self.loginHandler = handler;
        } else if (self.loginHandler != handler) {
            //Note blocks are not value comparable, so this can intentionally result in false positives.
            NSLog(@"INFO: A different session open completion handler was supplied when one already existed.");
        }
    }

    // normal login depends on the availability of a valid cached token
    if (self.state == FBSessionStateCreated) {

        // set the state and token info
        [self transitionToState:FBSessionStateCreatedOpening
                 andUpdateToken:nil
              andExpirationDate:nil
                    shouldCache:NO
                      loginType:FBSessionLoginTypeNone];

        [self authorizeWithPermissions:self.initializedPermissions
                              behavior:behavior
                       defaultAudience:_defaultDefaultAudience
                         isReauthorize:NO];

    } else { // self.status == FBSessionStateLoadedValidToken

        // this case implies that a valid cached token was found, and preserves the
        // "1-session-1-identity" rule, by transitioning to logged in, without a transition to login UX
        [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                          error:nil
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO
                                      loginType:FBSessionLoginTypeNone];
    }
}

- (void)reauthorizeWithPermissions:(NSArray*)permissions
                          behavior:(FBSessionLoginBehavior)behavior
                 completionHandler:(FBSessionReauthorizeResultHandler)handler {
    [self reauthorizeWithPermissions:permissions
                              isRead:NO
                            behavior:behavior
                     defaultAudience:FBSessionDefaultAudienceNone
                   completionHandler:handler];
}

- (void)reauthorizeWithReadPermissions:(NSArray*)readPermissions
                     completionHandler:(FBSessionReauthorizeResultHandler)handler {
    [self requestNewReadPermissions:readPermissions
                  completionHandler:handler];
}

- (void)reauthorizeWithPublishPermissions:(NSArray*)writePermissions
                        defaultAudience:(FBSessionDefaultAudience)audience
                      completionHandler:(FBSessionReauthorizeResultHandler)handler {
    [self requestNewPublishPermissions:writePermissions
                       defaultAudience:audience
                     completionHandler:handler];
}

- (void)requestNewReadPermissions:(NSArray*)readPermissions
                completionHandler:(FBSessionRequestPermissionResultHandler)handler {
    [self reauthorizeWithPermissions:readPermissions
                              isRead:YES
                            behavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     defaultAudience:FBSessionDefaultAudienceNone
                   completionHandler:handler];
}

- (void)requestNewPublishPermissions:(NSArray*)writePermissions
                     defaultAudience:(FBSessionDefaultAudience)audience
                   completionHandler:(FBSessionRequestPermissionResultHandler)handler {
    [self reauthorizeWithPermissions:writePermissions
                              isRead:NO
                            behavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     defaultAudience:audience
                   completionHandler:handler];
}

- (void)close {
    [self checkThreadAffinity];

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
                                shouldCache:NO
                                  loginType:FBSessionLoginTypeNone];
}

- (void)closeAndClearTokenInformation {
    [self closeAndClearTokenInformation:nil];
}

// Helper method to transistion token state correctly when
// the app is called back in cases of either app switch
// or FBLoginDialog
- (BOOL)handleAuthorizationCallbacks:(NSString *)accessToken params:(NSDictionary *)params loginType:(FBSessionLoginType)loginType {
    switch (self.state) {
        case FBSessionStateCreatedOpening:
            return [self handleAuthorizationOpen:params
                                  accessToken:accessToken
                                    loginType:loginType];
        case FBSessionStateOpen:
        case FBSessionStateOpenTokenExtended:
            if (loginType == FBSessionLoginTypeNone){
                // If loginType == None, then we were not expecting a re-auth
                // and entered here from an app link into an existing session
                // so we should immediately return NO to prevent a false transition
                // to TokenExtended.
                return NO;
            } else {
                return [self handleReauthorize:params
                                   accessToken:accessToken];
            }
        default:
            return NO;
    }
}

- (BOOL)handleOpenURL:(NSURL *)url {
    [self checkThreadAffinity];
    
    NSDictionary *params = [FBSession queryParamsFromLoginURL:url
                                                        appID:self.appID
                                              urlSchemeSuffix:self.urlSchemeSuffix];
    
    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    if (!params) {
        // We need to not discard native login responses, since the app might not have updated its
        // AppDelegate to call into FBAppCall. We are impersonating the native Facebook application's
        // bundle Id here. This is no less secure than old FBSession url handling
        __block BOOL completionHandlerFound = YES;
        BOOL handled = [[FBAppBridge sharedInstance] handleOpenURL:url
                                                 sourceApplication:@"com.facebook.Facebook"
                                                   fallbackHandler:^(FBAppCall *call) {
                                                       completionHandlerFound = NO;
                                                   }];
        return handled && completionHandlerFound;
    }
    FBSessionLoginType loginType = _loginTypeOfPendingOpenUrlCallback;
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
    
    NSString *accessToken = [params objectForKey:@"access_token"];
    
    // #2015922 should refactor these methods to take the FBAccessTokenData instance at which time
    // we should also use +FBAccessTokenData createTokenFromFacebookURL.
    return [self handleAuthorizationCallbacks:accessToken params:params loginType:loginType];
}

- (BOOL)openFromAccessTokenData:(FBAccessTokenData *)accessTokenData completionHandler:(FBSessionStateHandler) handler {
    return [self openFromAccessTokenData:accessTokenData
                       completionHandler:handler
            raiseExceptionIfInvalidState:YES];
}

- (void)handleDidBecomeActive {
    // Unexpected calls to app delegate's applicationDidBecomeActive are
    // handled by this method. If a pending fast-app-switch [re]authorization
    // is in flight, it is cancelled. Otherwise, this method is a no-op.
    [self authorizeRequestWasImplicitlyCancelled];
    
    // This is forward-compatibility. If an AppDelegate isn't updated to use AppCall,
    // we still want to provide a good AppBridge experience if possible.
    [[FBAppBridge sharedInstance] handleDidBecomeActive];
}

- (BOOL)isOpen {
    return FB_ISSESSIONOPENWITHSTATE(self.state);
}

- (NSString*)urlSchemeSuffix {
    [self checkThreadAffinity];
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

+ (BOOL)openActiveSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    return [FBSession openActiveSessionWithPermissions:nil
                                          allowLoginUI:allowLoginUI
                                    allowSystemAccount:YES
                                                isRead:YES
                                       defaultAudience:FBSessionDefaultAudienceNone
                                     completionHandler:nil];
}

+ (BOOL)openActiveSessionWithPermissions:(NSArray*)permissions
                            allowLoginUI:(BOOL)allowLoginUI
                       completionHandler:(FBSessionStateHandler)handler {
    return [FBSession openActiveSessionWithPermissions:permissions
                                          allowLoginUI:allowLoginUI
                                    allowSystemAccount:NO
                                                isRead:NO
                                       defaultAudience:FBSessionDefaultAudienceNone
                                     completionHandler:handler];
}

+ (BOOL)openActiveSessionWithReadPermissions:(NSArray*)readPermissions
                                allowLoginUI:(BOOL)allowLoginUI
                           completionHandler:(FBSessionStateHandler)handler {
    return [FBSession openActiveSessionWithPermissions:readPermissions
                                          allowLoginUI:allowLoginUI
                                    allowSystemAccount:YES
                                                isRead:YES
                                       defaultAudience:FBSessionDefaultAudienceNone
                                     completionHandler:handler];
}

+ (BOOL)openActiveSessionWithPublishPermissions:(NSArray*)publishPermissions
                                defaultAudience:(FBSessionDefaultAudience)defaultAudience
                                   allowLoginUI:(BOOL)allowLoginUI
                              completionHandler:(FBSessionStateHandler)handler {
    return [FBSession openActiveSessionWithPermissions:publishPermissions
                                          allowLoginUI:allowLoginUI
                                    allowSystemAccount:YES
                                                isRead:NO
                                       defaultAudience:defaultAudience
                                     completionHandler:handler];
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
    
    if (session != g_activeSession) {
        // we will close this, but we want any resulting 
        // handlers to see the new active session
        FBSession *toRelease = g_activeSession;
        
        // if we are being replaced, then we close you
        [toRelease close];
        
        // set the new session
        g_activeSession = [session retain];
        
        // some housekeeping needs to happen if we had a previous session
        if (toRelease) {
            // now the notification/release of the prior active
            [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidUnsetActiveSessionNotification
                                                                object:toRelease];
            [toRelease release];
        }
        
        // we don't notify nil sets
        if (session) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidSetActiveSessionNotification
                                                                object:session];
            
            if (session.isOpen) {
                [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidBecomeOpenActiveSessionNotification
                                                                    object:session];    
            }
        }
    }
    
    return session;
}

+ (void)setDefaultAppID:(NSString*)appID {
    [FBSettings setDefaultAppID:appID];
}

+ (NSString*)defaultAppID {
    return [FBSettings defaultAppID];
}

+ (void)setDefaultUrlSchemeSuffix:(NSString*)urlSchemeSuffix {
    [FBSettings setDefaultUrlSchemeSuffix:urlSchemeSuffix];
}

+ (NSString*)defaultUrlSchemeSuffix {
    return [FBSettings defaultUrlSchemeSuffix];
}

+ (void)renewSystemCredentials:(FBSessionRenewSystemCredentialsHandler) handler {
    [[FBSystemAccountStoreAdapter sharedInstance] renewSystemAuthorization:handler];
}

#pragma mark -
#pragma mark Private Members (core session members)

// private methods are broken into two categories: core session and helpers

// core member that owns all state transitions as well as property setting for status and isOpen
- (BOOL)transitionToState:(FBSessionState)state
           andUpdateToken:(NSString*)token
        andExpirationDate:(NSDate*)date
              shouldCache:(BOOL)shouldCache
                loginType:(FBSessionLoginType)loginType {

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
        [FBLogger singleShotLogEntry:FBLoggingBehaviorSessionStateTransitions
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
    [FBLogger singleShotLogEntry:FBLoggingBehaviorSessionStateTransitions logEntry:logString];
    
    [FBLogger singleShotLogEntry:FBLoggingBehaviorPerformanceCharacteristics 
                    timestampTag:self
                    formatString:@"%@", logString];
    
    // Re-start session transition timer for the next time around.
    [FBLogger registerCurrentTime:FBLoggingBehaviorPerformanceCharacteristics
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

    BOOL changingIsOpen = FB_ISSESSIONOPENWITHSTATE(state) != FB_ISSESSIONOPENWITHSTATE(statePrior);

    // should only ever be YES from here...
    _isInStateTransition = YES;

    // KVO property will change notifications, for state change
    [self willChangeValueForKey:FBstatusPropertyName];
    if (changingIsOpen) {
        [self willChangeValueForKey:FBisOpenPropertyName];
    }

    if (changingTokenAndDate) {
        // if we are just about to transition to open or token loaded, and the caller
        // wants to specify a login type other than none, then we set the login type
        FBSessionLoginType loginTypeUpdated = self.accessTokenData.loginType;
        if (isValidTransition &&
            (state == FBSessionStateOpen || state == FBSessionStateCreatedTokenLoaded) &&
            loginType != FBSessionLoginTypeNone) {
            loginTypeUpdated = loginType;
        }

        // KVO property will-change notifications for token and date
        [self willChangeValueForKey:FBaccessTokenPropertyName];
        [self willChangeValueForKey:FBaccessTokenDataPropertyName];
        [self willChangeValueForKey:FBexpirationDatePropertyName];
       
        // set the new access token as a copy of any existing token with the updated
        // token string and expiration date.
        if (token) {
            FBAccessTokenData *fbAccessToken = [FBAccessTokenData createTokenFromString:token
                                                                            permissions:(self.accessTokenData.permissions ?: self.initializedPermissions)
                                                                         expirationDate:date
                                                                              loginType:loginTypeUpdated
                                                                            refreshDate:[NSDate date]];
            self.accessTokenData = fbAccessToken;
        } else {
            self.accessTokenData = nil;
        }
    }

    // change the actual state
    // note: we should not inject any callbacks between this and the token/date changes above
    self.state = state;

    // ... to here -- if YES
    _isInStateTransition = NO;

    if (changingTokenAndDate) {
        // update the cache
        if (shouldCache) {
            [self.tokenCachingStrategy cacheFBAccessTokenData:self.accessTokenData];
        }

        // KVO property change notifications token and date
        [self didChangeValueForKey:FBexpirationDatePropertyName];
        [self didChangeValueForKey:FBaccessTokenPropertyName];
        [self didChangeValueForKey:FBaccessTokenDataPropertyName];
    }

    // KVO property did change notifications, for state change
    if (changingIsOpen) {
        [self didChangeValueForKey:FBisOpenPropertyName];
    }
    [self didChangeValueForKey:FBstatusPropertyName];
    
    // if we are the active session, and we changed is-valid, notify
    if (changingIsOpen && g_activeSession == self) {
        if (FB_ISSESSIONOPENWITHSTATE(state)) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidBecomeOpenActiveSessionNotification
                                                                object:self];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:FBSessionDidBecomeClosedActiveSessionNotification
                                                                object:self];
        }
    }

    // Note! It is important that no processing occur after the KVO notifications have been raised, in order to
    // assure the state is cohesive in common reintrant scenarios

    // the NO case short-circuits after the state switch/case
    return YES;
}

// core authorization UX flow
- (void)authorizeWithPermissions:(NSArray*)permissions
                        behavior:(FBSessionLoginBehavior)behavior
                 defaultAudience:(FBSessionDefaultAudience)audience
                   isReauthorize:(BOOL)isReauthorize {
    BOOL tryIntegratedAuth = behavior == FBSessionLoginBehaviorUseSystemAccountIfPresent;
    BOOL tryFacebookLogin = (behavior == FBSessionLoginBehaviorUseSystemAccountIfPresent) ||
                            (behavior == FBSessionLoginBehaviorWithFallbackToWebView) ||
                            (behavior == FBSessionLoginBehaviorWithNoFallbackToWebView);
    BOOL tryFallback =  (behavior == FBSessionLoginBehaviorWithFallbackToWebView) ||
                        (behavior == FBSessionLoginBehaviorForcingWebView);
    
    [self authorizeWithPermissions:(NSArray*)permissions
                   defaultAudience:audience
                    integratedAuth:tryIntegratedAuth
                         FBAppAuth:tryFacebookLogin
                        safariAuth:tryFacebookLogin
                          fallback:tryFallback
                     isReauthorize:isReauthorize
               canFetchAppSettings:YES];
}

- (void)authorizeWithPermissions:(NSArray*)permissions
                 defaultAudience:(FBSessionDefaultAudience)defaultAudience
                  integratedAuth:(BOOL)tryIntegratedAuth
                       FBAppAuth:(BOOL)tryFBAppAuth
                      safariAuth:(BOOL)trySafariAuth
                        fallback:(BOOL)tryFallback
                   isReauthorize:(BOOL)isReauthorize
             canFetchAppSettings:(BOOL)canFetchAppSettings {
    // setup parameters for either the safari or inline login
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   self.appID, FBLoginUXClientID,
                                   FBLoginUXUserAgent, FBLoginUXType,
                                   FBRedirectURL, FBLoginUXRedirectURI,
                                   FBLoginUXTouch, FBLoginUXDisplay,
                                   FBLoginUXIOS, FBLoginUXSDK,
                                   nil];
    
    NSString *clientStateString = [FBUtility simpleJSONEncode:[self clientState]];
    if (clientStateString) {
        params[FBLoginUXClientState] = clientStateString;
    }
    
    if (permissions != nil) {
        NSString* scope = [permissions componentsJoinedByString:@","];
        [params setValue:scope forKey:@"scope"];
    }

    if (_urlSchemeSuffix) {
        [params setValue:_urlSchemeSuffix forKey:@"local_client_id"];
    }

    // To avoid surprises, delete any cookies we currently have.
    [FBSession deleteFacebookCookies];
    
    // we prefer OS-integrated Facebook login if supported by the device
    // attempt to open an account store with the type Facebook; and if successful authorize
    // using the OS
    BOOL didRequestAuthorize = NO;
    
    // do we want and have the ability to attempt integrated authn
    if (!didRequestAuthorize &&
        tryIntegratedAuth &&
        (!isReauthorize || self.accessTokenData.loginType == FBSessionLoginTypeSystemAccount) &&
        [self isSystemAccountStoreAvailable]) {
                
        // looks like we will get to attempt a login with integrated authn
        didRequestAuthorize = YES;
        
        [self authorizeUsingSystemAccountStore:permissions
                               defaultAudience:defaultAudience
                                  isReauthorize:isReauthorize];
    }
    
    // if the device is running a version of iOS that supports multitasking,
    // try to obtain the access token from the Facebook app installed
    // on the device.
    // If the Facebook app isn't installed or it doesn't support
    // the fbauth:// URL scheme, fall back on Safari for obtaining the access token.
    // This minimizes the chance that the user will have to enter his or
    // her credentials in order to authorize the application.
    if (!didRequestAuthorize &&
        [self isMultitaskingSupported] &&
        [self isURLSchemeRegistered] &&
        !TEST_DISABLE_MULTITASKING_LOGIN) {
        
        if (tryFBAppAuth) {
            FBFetchedAppSettings *fetchedSettings = [FBUtility fetchedAppSettings];
            if ([FBSettings defaultDisplayName] &&            // don't autoselect Native Login unless the app has been setup for it,
                [self.appID isEqualToString:[FBSettings defaultAppID]] && // If the appId has been overridden, then the bridge cannot be used and native login is denied
                (fetchedSettings || canFetchAppSettings) &&   // and we have app-settings available to us, or could fetch if needed
                !TEST_DISABLE_FACEBOOKNATIVELOGIN) {
                if (!fetchedSettings) {
                    // fetch the settings and call this method again
                    didRequestAuthorize = YES;
                    [FBUtility fetchAppSettings:[FBSettings defaultAppID] callback:^(FBFetchedAppSettings * settings, NSError * error) {
                        [self authorizeWithPermissions:permissions
                                       defaultAudience:defaultAudience
                                        integratedAuth:tryIntegratedAuth
                                             FBAppAuth:tryFBAppAuth
                                            safariAuth:trySafariAuth
                                              fallback:tryFallback
                                         isReauthorize:isReauthorize
                                   canFetchAppSettings:NO];
                    }];
                } else if (!fetchedSettings.suppressNativeGdp) {
                    if (![[FBSettings defaultDisplayName] isEqualToString:fetchedSettings.serverAppName]) {
                        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                            logEntry:@"PLIST entry for FacebookDisplayName does not match Facebook app name."];

                    }
                    didRequestAuthorize = [self authorizeUsingFacebookNativeLoginWithPermissions:permissions
                                                                                 defaultAudience:defaultAudience];
                }
            }
            
            if (!TEST_DISABLE_FACEBOOKLOGIN && !didRequestAuthorize) {
                didRequestAuthorize = [self authorizeUsingFacebookApplication:params];
            }
        }

        if (trySafariAuth && !didRequestAuthorize) {
            didRequestAuthorize = [self authorizeUsingSafari:params];
        }
        //In case openURL failed, make sure we don't still expect a openURL callback.
        if (!didRequestAuthorize){
            _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
        }
    }

    // If single sign-on failed, see if we should attempt to fallback
    if (!didRequestAuthorize) {
        if (tryFallback) {
            [self authorizeUsingLoginDialog:params];
        } else {
            // Can't fallback and Facebook Login failed, so transition to an error state
            NSError *error = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonInlineNotCancelledValue
                                                    errorCode:nil
                                                   innerError:nil];

            // state transition, and call the handler if there is one
            [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                              error:error
                                              token:nil
                                     expirationDate:nil
                                        shouldCache:NO
                                          loginType:FBSessionLoginTypeNone];
        }
    }
}

- (void)logIntegratedAuthInsights:(NSString *)dialogOutcome
                      permissions:(NSArray *)permissions {
    
    NSString *sortedPermissions;
    
    if (permissions.count == 0) {
        sortedPermissions = @"<NoPermissionsSpecified>";
    } else {
        sortedPermissions = [[permissions sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
                             componentsJoinedByString:@","];
    }
    
    // We log Launch and Dismiss one after the other, because we can't determine a priori whether
    // this invocation will necessarily result in launching a dialog, and logging an event and then
    // retracting it conditionally is too problematic.
    
    [FBInsights logImplicitEvent:FBInsightsEventNamePermissionsUILaunch
                      valueToSum:1.0
                      parameters:@{ @"ui_dialog_type" : @"iOS integrated auth",
                                    @"permissions_requested" : sortedPermissions }
                         session:self];
    
    [FBInsights logImplicitEvent:FBInsightsEventNamePermissionsUIDismiss
                      valueToSum:1.0
                      parameters:@{ @"ui_dialog_type" : @"iOS integrated auth",
                                    FBInsightsEventParameterDialogOutcome : dialogOutcome,
                                    @"permissions_requested" : sortedPermissions }
                         session:self];
}

- (BOOL)isSystemAccountStoreAvailable {
    id accountStore = nil;
    id accountTypeFB = nil;
    
    return (accountStore = [[[NSClassFromString(@"ACAccountStore") alloc] init] autorelease]) &&
        (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"]);
}

- (void)authorizeUsingSystemAccountStore:(NSArray*)permissions
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                           isReauthorize:(BOOL)isReauthorize {
    self.lastRequestedSystemAudience = defaultAudience;

    unsigned long timePriorToShowingUI = [FBUtility currentTimeInMilliseconds];
    
    FBSystemAccountStoreAdapter *systemAccountStoreAdapter = [self getSystemAccountStoreAdapter];
    [systemAccountStoreAdapter
        requestAccessToFacebookAccountStore:permissions
        defaultAudience:defaultAudience
        isReauthorize:isReauthorize
        appID:self.appID
        session:self
        handler:^(NSString *oauthToken, NSError *accountStoreError) {           
            BOOL isUntosedDevice = (!oauthToken && accountStoreError.code == ACErrorAccountNotFound);
            
            int millisecondsSinceUIWasPotentiallyShown = [FBUtility currentTimeInMilliseconds] - timePriorToShowingUI;
            
            // There doesn't appear to be a reliable way to determine whether or not a UI was invoked
            // to get us here, or whether the cached token was sufficient.  So we use a timer heuristic
            // assuming that human response time couldn't complete a dialog in under the interval
            // given here, but the process will return here fast enough if the token is cached.  The threshold was
            // chosen empirically, so there may be some edge cases that are false negatives or false positives.
            BOOL dialogWasShown = millisecondsSinceUIWasPotentiallyShown > 350;

            // initial auth case
            if (!isReauthorize) {
                if (oauthToken) {
                    
                    if (dialogWasShown) {
                        [self logIntegratedAuthInsights:@"Authorization succeeded"
                                            permissions:permissions];
                    }
                    
                    [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                                          error:nil
                                                          token:oauthToken
                     // BUG: we need a means for fetching the expiration date of the token
                                                 expirationDate:[NSDate distantFuture]
                                                    shouldCache:YES
                                                      loginType:FBSessionLoginTypeSystemAccount];

                } else if (isUntosedDevice) {
                    
                    // Don't invoke logIntegratedAuthInsights, since this is not an 'integrated dialog' case.
                    
                    // even when OS integrated auth is possible we use native-app/safari
                    // login if the user has not signed on to Facebook via the OS
                    [self authorizeWithPermissions:permissions
                                   defaultAudience:defaultAudience
                                    integratedAuth:NO
                                         FBAppAuth:YES
                                        safariAuth:YES
                                          fallback:YES
                                     isReauthorize:NO
                               canFetchAppSettings:YES];
                } else {
                    
                    [self logIntegratedAuthInsights:@"Authorization cancelled"
                                        permissions:permissions];

                    NSError *err;
                    if ([accountStoreError.domain isEqualToString:FacebookSDKDomain]){
                        // If the requestAccess call results in a Facebook error, surface it as a top-level
                        // error. This implies it is not the typical user "disallows" case.
                        err = accountStoreError;
                    } else if ([accountStoreError.domain isEqualToString:@"com.apple.accounts"] && accountStoreError.code == 7) {
                        // code 7 is for user cancellations, see ACErrorCode
                        err = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonUserCancelledSystemValue
                                                      errorCode:nil
                                                     innerError:accountStoreError];
                    } else {
                        // create an error object with additional info regarding failed login
                        err = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonSystemError
                                                     errorCode:nil
                                                    innerError:accountStoreError];
                    }
                    
                    // state transition, and call the handler if there is one
                    [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                                          error:err
                                                          token:nil
                                                 expirationDate:nil
                                                    shouldCache:NO
                                                      loginType:FBSessionLoginTypeNone];
                }
            } else { // reauth case
                if (oauthToken) {
                    
                    if (dialogWasShown) {
                        [self logIntegratedAuthInsights:@"Reauthorization succeeded"
                                            permissions:permissions];
                    }
                    
                    // union the requested permissions with the already granted permissions
                    NSMutableSet *set = [NSMutableSet setWithArray:self.accessTokenData.permissions];
                    [set addObjectsFromArray:permissions];
                    
                    // complete the operation: success
                    [self completeReauthorizeWithAccessToken:oauthToken
                                                  expirationDate:[NSDate distantFuture]
                                                     permissions:[set allObjects]];
                } else {
                    
                    if (dialogWasShown) {
                        [self logIntegratedAuthInsights:@"Reauthorization cancelled"
                                            permissions:permissions];
                    }
                    
                    NSError *err;
                    if ([accountStoreError.domain isEqualToString:FacebookSDKDomain]){
                        // If the requestAccess call results in a Facebook error, surface it as a top-level
                        // error. This implies it is not the typical user "disallows" case.
                        err = accountStoreError;
                    } else if ([accountStoreError.domain isEqualToString:@"com.apple.accounts"]
                               && accountStoreError.code == 7
                               && ![accountStoreError userInfo][NSLocalizedDescriptionKey]) {
                        // code 7 is for user cancellations, see ACErrorCode
                        // for re-auth, there is a specical case where device will return a code 7 if the app
                        // has been untossed. In those cases, there is a localized message so we want to ignore
                        // those for purposes of classifying user cancellations.
                        err = [self errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelledSystem
                                                          errorCode:nil
                                                         innerError:accountStoreError];
                    } else {
                        // create an error object with additional info regarding failed login
                        err = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonSystemError
                                                     errorCode:nil
                                                    innerError:accountStoreError];
                    }

                    // complete the operation: failed
                    [self callReauthorizeHandlerAndClearState:err];
                    
                    // if we made it this far into the reauth case with an untosed device, then
                    // it is time to invalidate the session
                    if (isUntosedDevice) {
                        [self closeAndClearTokenInformation];
                    }
                }
            }
        }];
}

- (FBSystemAccountStoreAdapter *)getSystemAccountStoreAdapter {
    return [FBSystemAccountStoreAdapter sharedInstance];
}

- (BOOL)isMultitaskingSupported {
    return [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] &&
        [[UIDevice currentDevice] isMultitaskingSupported];
}

- (BOOL)authorizeUsingFacebookNativeLoginWithPermissions:(NSArray*)permissions
                                         defaultAudience:(FBSessionDefaultAudience)defaultAudience {
    FBLoginDialogParams *params = [[[FBLoginDialogParams alloc] init] autorelease];
    params.permissions = permissions;
    params.writePrivacy = defaultAudience;
    
    FBAppCall *call = [FBDialogs presentLoginDialogWithParams:params
                                                    clientState:nil
                                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                            [self handleDidCompleteNativeLoginForAppCall:call];
                                                        }];
    if (call) {
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookApplication;
    }
    return (call != nil);
}

- (void)handleDidCompleteNativeLoginForAppCall:(FBAppCall *)call {
    if (call.error.code == FBErrorAppActivatedWhilePendingAppCall) {
        // We're here because the app was activated while a authorize request was pending
        // and without a response URL. This is the same flow as handleDidBecomeActive.
        [self authorizeRequestWasImplicitlyCancelled];
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (call.dialogData.results) {
        [params addEntriesFromDictionary:call.dialogData.results];
    }
    
    // The error from the native Facebook application will be wrapped by an SDK error later on.
    // NOTE: If the user cancelled the login, there won't be an error in the app call. However,
    // an error will be generated further downstream, once the access token is found to be missing.
    // So there is no more work to be done here.
    if (call.error) {
        params[FBInnerErrorObjectKey] = [FBSession sdkSurfacedErrorForNativeLoginError:call.error];
    }
    
    FBSessionLoginType loginType = _loginTypeOfPendingOpenUrlCallback;
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
    
    [self handleAuthorizationCallbacks:params[@"access_token"]
                                params:params
                             loginType:loginType];
}

- (void)addWebLoginStartTimeToParams:(NSMutableDictionary *)params
{
    NSNumber *timeValue = [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])];
    NSString *e2eTimestampString = [FBUtility simpleJSONEncode:@{@"init":timeValue}];
    [params setObject:e2eTimestampString forKey:@"e2e"];
}

- (BOOL)isURLSchemeRegistered {
    // If the url scheme is not registered, then the app we delegate to cannot call
    // back, and hence this is an invalid call.
    NSString *defaultUrlScheme = [NSString stringWithFormat:@"fb%@%@", self.appID, self.urlSchemeSuffix ?: @""];
    if (![FBUtility isRegisteredURLScheme:defaultUrlScheme]) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:[NSString stringWithFormat:@"Cannot use the Facebook app or Safari to authorize, %@ is not registered as a URL Scheme", defaultUrlScheme]];
        return NO;
    }
    return YES;
}

- (BOOL)authorizeUsingFacebookApplication:(NSMutableDictionary *)params {
    NSString *scheme = FBAuthURLScheme;
    if (_urlSchemeSuffix) {
        scheme = [scheme stringByAppendingString:@"2"];
    }
    // add a timestamp for tracking GDP e2e time
    [self addWebLoginStartTimeToParams:params];
    
    NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, FBAuthURLPath];
    NSString *fbAppUrl = [FBRequest serializeURL:urlPrefix params:params];
    
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookApplication;
    return [self tryOpenURL:[NSURL URLWithString:fbAppUrl]];
}

- (BOOL)authorizeUsingSafari:(NSMutableDictionary *)params {
    // add a timestamp for tracking GDP e2e time
    [self addWebLoginStartTimeToParams:params];

    NSString *loginDialogURL = [FBDialogBaseURL stringByAppendingString:FBLoginDialogMethod];

    NSString *nextUrl = self.appBaseUrl;
    [params setValue:nextUrl forKey:@"redirect_uri"];
    
    NSString *fbAppUrl = [FBRequest serializeURL:loginDialogURL params:params];
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookViaSafari;
    
    return [self tryOpenURL:[NSURL URLWithString:fbAppUrl]];
}

- (BOOL)tryOpenURL:(NSURL *)url {
    return [[UIApplication sharedApplication] openURL:url];
}

- (void)authorizeUsingLoginDialog:(NSMutableDictionary *)params {
    // add a timestamp for tracking GDP e2e time
    [self addWebLoginStartTimeToParams:params];

    NSString *loginDialogURL = [FBDialogBaseURL stringByAppendingString:FBLoginDialogMethod];
    
    // open an inline login dialog. This will require the user to enter his or her credentials.
    self.loginDialog = [[[FBLoginDialog alloc] initWithURL:loginDialogURL
                                               loginParams:params
                                                  delegate:self]
                        autorelease];
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeWebView;
    [self.loginDialog show];
}

- (BOOL)handleAuthorizationOpen:(NSDictionary*)parameters
                 accessToken:(NSString*)accessToken
                   loginType:(FBSessionLoginType)loginType {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [parameters objectForKey:@"error"];
        
        // if the error response indicates that we should try again using Safari, open
        // the authorization dialog in Safari.
        if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
            [self authorizeWithPermissions:self.initializedPermissions
                           defaultAudience:_defaultDefaultAudience
                            integratedAuth:NO
                                 FBAppAuth:NO
                                safariAuth:YES
                                  fallback:NO
                             isReauthorize:NO
                       canFetchAppSettings:YES];
            return YES;
        }
        
        // if the error response indicates that we should try the authorization flow
        // in an inline dialog, do that.
        if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
            [self authorizeWithPermissions:self.initializedPermissions
                           defaultAudience:_defaultDefaultAudience
                            integratedAuth:NO
                                 FBAppAuth:NO
                                safariAuth:NO
                                  fallback:NO
                             isReauthorize:NO
                       canFetchAppSettings:YES];
            return YES;
        }
        
        // the facebook app may return an error_code parameter in case it
        // encounters a UIWebViewDelegate error
        NSString *errorCode = [parameters objectForKey:@"error_code"];
        
        // create an error object with additional info regarding failed login
        // making sure the top level error reason is defined there.
        // If an inner error or another errorReason is present, pass it along
        // as an inner error for the top level error
        NSError *innerError = parameters[FBInnerErrorObjectKey];
        if (!innerError && errorReason) {
            innerError = [self errorLoginFailedWithReason:errorReason errorCode:nil innerError:nil];
        }
        NSError *error = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonUserCancelledValue
                                                errorCode:errorCode
                                               innerError:innerError];
        
        // state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                          error:error
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO
                                      loginType:FBSessionLoginTypeNone];
    } else {
        
        // we have an access token, so parse the expiration date.
        NSDate *expirationDate = [FBSession expirationDateFromResponseParams:parameters];
        
        // set token and date, state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                          error:nil
                                          token:accessToken
                                 expirationDate:expirationDate
                                    shouldCache:YES
                                      loginType:loginType];
    }
    return YES;
}

- (BOOL)handleReauthorize:(NSDictionary*)parameters
              accessToken:(NSString*)accessToken {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        // no token in this case implies that the user cancelled the permissions upgrade
        NSError *innerError = parameters[FBInnerErrorObjectKey];
        NSError *error = [self errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                errorCode:nil
                                               innerError:innerError];
        [self callReauthorizeHandlerAndClearState:error];
    } else {
        
        // we have an access token, so parse the expiration date.
        NSDate *expirationDate = [FBSession expirationDateFromResponseParams:parameters];
        
        [self validateReauthorizedAccessToken:accessToken expirationDate:expirationDate];
    }
    return YES;    
}

- (void)validateReauthorizedAccessToken:(NSString *)accessToken expirationDate:(NSDate *)expirationDate {
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
    
    void (^handleBatch)(id<FBGraphUser>,id) = [[^(id<FBGraphUser> user,
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
                id newPermissions = [[permissionsRefreshed objectAtIndex:0] allKeys];
                if (![newPermissions isKindOfClass:[NSArray class]]) {
                    newPermissions = nil;
                }
                [self completeReauthorizeWithAccessToken:accessToken
                                          expirationDate:expirationDate
                                             permissions:newPermissions];
            } else {
                // no we don't have matching FBIDs, then we fail on these grounds
                NSError *error = [self errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonWrongUser
                                                        errorCode:nil
                                                       innerError:nil];
                [self callReauthorizeHandlerAndClearState:error];
            }
            
            // because these are __block, we manually handle their lifetime
            [fbid release];
            [fbid2 release];
            [permissionsRefreshed release];
        }
    } copy] autorelease];
    
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

- (void)reauthorizeWithPermissions:(NSArray*)permissions
                            isRead:(BOOL)isRead
                          behavior:(FBSessionLoginBehavior)behavior
                   defaultAudience:(FBSessionDefaultAudience)audience
                 completionHandler:(FBSessionRequestPermissionResultHandler)handler {
    
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
    
    // is everything in good order argument-wise?
    [FBSession validateRequestForPermissions:permissions
                             defaultAudience:audience
                          allowSystemAccount:behavior == FBSessionLoginBehaviorUseSystemAccountIfPresent
                                      isRead:isRead];
    
    // setup handler and permissions and perform the actual reauthorize
    self.reauthorizePermissions = permissions;
    self.reauthorizeHandler = handler;
    [self authorizeWithPermissions:permissions
                          behavior:behavior
                   defaultAudience:audience
                     isReauthorize:YES];
}

- (void)completeReauthorizeWithAccessToken:(NSString*)accessToken
                            expirationDate:(NSDate*)expirationDate
                               permissions:(NSArray*)permissions {
    if (permissions) {
        self.accessTokenData.permissions = permissions;
    }
    
    // set token and date, state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                      error:nil
                                      token:accessToken
                             expirationDate:expirationDate
                                shouldCache:YES
                                  loginType:FBSessionLoginTypeNone];
    
    // no error, ack a completed permission upgrade
    [self callReauthorizeHandlerAndClearState:nil];
}

-(void)authorizeRequestWasImplicitlyCancelled {
    
    const FBSessionState state = self.state;
    
    if (state == FBSessionStateCreated ||
        state == FBSessionStateClosed ||
        state == FBSessionStateClosedLoginFailed){
        return;
    }
    
    //we also skip FBSessionLoginTypeWebView because the FBDialogDelegate will handle
    // the flow on its own. Otherwise, the dismissal of the webview will incorrectly
    // trigger this block.
    if (_loginTypeOfPendingOpenUrlCallback != FBSessionLoginTypeNone
        && _loginTypeOfPendingOpenUrlCallback != FBSessionLoginTypeWebView){
        
        if (state == FBSessionStateCreatedOpening){
            //if we're here, user had declined a fast app switch login.
            [self close];
        } else {
            //this means the user declined a 'reauthorization' so we need
            // to clean out the in-flight request.
            NSError *error = [self errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                    errorCode:nil
                                                   innerError:nil];
            [self callReauthorizeHandlerAndClearState:error];
        }
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
    }
}

- (void)refreshAccessToken:(NSString*)token 
            expirationDate:(NSDate*)expireDate {
    // refresh token and date, state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                      error:nil
                                      token:token ? token : self.accessTokenData.accessToken
                             expirationDate:expireDate
                                shouldCache:YES
                                  loginType:FBSessionLoginTypeNone];
}

- (BOOL)shouldExtendAccessToken {
    BOOL result = NO;
    NSDate *now = [NSDate date];
    BOOL isFacebookLogin = self.accessTokenData.loginType == FBSessionLoginTypeFacebookApplication
                            || self.accessTokenData.loginType == FBSessionLoginTypeFacebookViaSafari
                            || self.accessTokenData.loginType == FBSessionLoginTypeSystemAccount;
    
    if (self.isOpen &&
        isFacebookLogin &&
        [now timeIntervalSinceDate:self.attemptedRefreshDate] > FBTokenRetryExtendSeconds &&
        [now timeIntervalSinceDate:self.accessTokenData.refreshDate] > FBTokenExtendThresholdSeconds) {
        result = YES;
        self.attemptedRefreshDate = now;
    }
    return result;
}

// Internally accessed, so we can bind the affinitized thread later.
- (void)clearAffinitizedThread {
    self.affinitizedThread = nil;
}

- (void)checkThreadAffinity {

    // Validate affinity, or, if not established, establish it.
    if (self.affinitizedThread) {
        NSAssert(self.affinitizedThread == [NSThread currentThread],
                 @"FBSession: should only be used from a single thread");
    } else {
        self.affinitizedThread = [NSThread currentThread];
    }
}


// core handler for inline UX flow
- (void)fbDialogLogin:(NSString *)accessToken expirationDate:(NSDate *)expirationDate {
    // no reason to keep this object
    self.loginDialog = nil;

    NSTimeInterval expirationTimeInterval = [expirationDate timeIntervalSinceNow];
    NSDictionary* params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[NSNumber numberWithDouble:expirationTimeInterval] stringValue], @"expires_in", nil];
    
    [self handleAuthorizationCallbacks:accessToken params:params loginType:FBSessionLoginTypeWebView];
    [params release];
}

// core handler for inline UX flow
- (void)fbDialogNotLogin:(BOOL)cancelled {
    // done with this
    self.loginDialog = nil;

    NSString *reason =
        cancelled ? FBErrorLoginFailedReasonInlineCancelledValue : FBErrorLoginFailedReasonInlineNotCancelledValue;
    NSDictionary* params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:reason, @"error", nil];
    
    [self handleAuthorizationCallbacks:nil
                                params:params
                             loginType:FBSessionLoginTypeWebView];
    [params release];
}

#pragma mark - Private Members (private helpers)

// helper to wrap-up handler callback and state-change
- (void)transitionAndCallHandlerWithState:(FBSessionState)status
                                    error:(NSError*)error
                                    token:(NSString*)token
                           expirationDate:(NSDate*)date
                              shouldCache:(BOOL)shouldCache
                                loginType:(FBSessionLoginType)loginType {

    
    // lets get the state transition out of the way
    BOOL didTransition = [self transitionToState:status
                                  andUpdateToken:token
                               andExpirationDate:date
                                     shouldCache:shouldCache
                                       loginType:loginType];

    // if we are given a handler, we promise to call it once per transition from open to close

    // note the retain message works the same as a copy because loginHandler was already declared
    // as a copy property.
    FBSessionStateHandler handler = [self.loginHandler retain];

    @try {
        // the moment we transition to a terminal state, we release our handlers, and possibly fail-call reauthorize
        if (didTransition && FB_ISSESSIONSTATETERMINAL(self.state)) {
            self.loginHandler = nil;
            
            NSError *error = [self errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonSessionClosed
                                                    errorCode:nil
                                                   innerError:nil];
            [self callReauthorizeHandlerAndClearState:error];
        }
        
        // if we have a handler, call it and release our
        // final retain on the handler
        if (handler) {
            
            // unsuccessful transitions don't change state and don't propagate the error object
            handler(self,
                    self.state,
                    didTransition ? error : nil);
            
        }
    }
    @finally {
        // now release our stack reference
        [handler release];
    }
}

- (void)callReauthorizeHandlerAndClearState:(NSError*)error {
    // clear state and call handler
    FBSessionRequestPermissionResultHandler reauthorizeHandler = [self.reauthorizeHandler retain];
    @try {
        self.reauthorizeHandler = nil;
        self.reauthorizePermissions = nil;
        if (reauthorizeHandler) {
            reauthorizeHandler(self, error);
        }
    }
    @finally {
        [reauthorizeHandler release];
    }
}

- (NSString *)appBaseUrl {
    return [FBUtility stringAppBaseUrlFromAppId:self.appID urlSchemeSuffix:self.urlSchemeSuffix];
}

- (NSError*)errorLoginFailedWithReason:(NSString*)errorReason
                             errorCode:(NSString*)errorCode
                            innerError:(NSError*)innerError {
    // capture reason and nested code as user info
    NSMutableDictionary* userinfo = [[NSMutableDictionary alloc] init];
    if (errorReason) {
        userinfo[FBErrorLoginFailedReason] = errorReason;
    }
    if (errorCode) {
        userinfo[FBErrorLoginFailedOriginalErrorCode] = errorCode;
    }
    if (innerError) {
        userinfo[FBErrorInnerErrorKey] = innerError;
    }
    userinfo[FBErrorSessionKey] = self;
   
    // create error object
    NSError *err = [NSError errorWithDomain:FacebookSDKDomain
                                      code:FBErrorLoginFailedOrCancelled
                                  userInfo:userinfo];
    [userinfo release];
    return err;
}

- (NSDictionary *)clientState {
    NSDictionary *clientState = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], FBLoginUXClientStateIsClientState,
                                 [NSNumber numberWithBool:YES], FBLoginUXClientStateIsOpenSession,
                                 [NSNumber numberWithBool:(self == g_activeSession)], FBLoginUXClientStateIsActiveSession,
                                 nil];
    return clientState;
}

+ (NSDictionary *)queryParamsFromLoginURL:(NSURL *)url appID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    if (appID) {
        NSString* expectedUrlPrefix = [FBUtility stringAppBaseUrlFromAppId:appID urlSchemeSuffix:urlSchemeSuffix];
        if (![[url absoluteString] hasPrefix:expectedUrlPrefix]) {
            return nil;
        }
    } else {
        // Don't have an App ID, just verify path.
        NSString *host = url.host;
        if (![host isEqualToString:@"authorize"]) {
            return nil;
        }
    }
    
    return [FBUtility queryParamsDictionaryFromFBURL:url];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    // these properties must manually notify for KVO
    if ([key isEqualToString:FBisOpenPropertyName] ||
        [key isEqualToString:FBaccessTokenPropertyName] ||
        [key isEqualToString:FBaccessTokenDataPropertyName] ||
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

+ (NSDate *)expirationDateFromResponseParams:(NSDictionary *)parameters {
    NSString *expTime = [parameters objectForKey:@"expires_in"];
    NSDate *expirationDate = nil;
    if (expTime) {
        // If we have an interval, it is assumed to be since now. (e.g. 60 days)
        expirationDate = [FBUtility expirationDateFromExpirationTimeIntervalString:expTime];
    } else {
        // If we have an actual timestamp, create the date from that instead.
        expirationDate = [FBUtility expirationDateFromExpirationUnixTimeString:parameters[@"expires"]];
    }
    
    if (!expirationDate) {
        expirationDate = [NSDate distantFuture];
    }
    
    return expirationDate;
}

#pragma mark -
#pragma mark Internal members

+ (BOOL)isOpenSessionResponseURL:(NSURL *)url {
    NSDictionary *params = [FBSession queryParamsFromLoginURL:url appID:nil urlSchemeSuffix:nil];
    NSDictionary *clientState = [FBUtility simpleJSONDecode:params[FBLoginUXClientState]];
    if (!clientState[FBLoginUXClientStateIsClientState]) {
        return NO;
    }
    
    NSNumber *isOpenSessionBit = clientState[FBLoginUXClientStateIsOpenSession];
    return [isOpenSessionBit boolValue];
}

- (BOOL)openFromAccessTokenData:(FBAccessTokenData *)accessTokenData
              completionHandler:(FBSessionStateHandler) handler
   raiseExceptionIfInvalidState:(BOOL)raiseException {
    if (accessTokenData == nil) {
        return NO;
    }
    
    // TODO : Need to support more states (possibly as simple as !isOpen) in the case that this is g_activeSession,
    // and ONLY in that case.
    if (!(self.state == FBSessionStateCreated)) {
        if (raiseException) {
            [[NSException exceptionWithName:FBInvalidOperationException
                                     reason:@"FBSession: cannot open a session from token data from its current state"
                                   userInfo:nil]
             raise];
        } else {
            return NO;
        }
    }
    
    BOOL result = NO;
    if ([self initializeFromCachedToken:accessTokenData withPermissions:nil]) {
        [self openWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView completionHandler:handler];
        result = self.isOpen;
        
        [self.tokenCachingStrategy cacheFBAccessTokenData:accessTokenData];
    }
    return result;
}

+ (BOOL)openActiveSessionWithPermissions:(NSArray*)permissions
                            allowLoginUI:(BOOL)allowLoginUI
                      allowSystemAccount:(BOOL)allowSystemAccount
                                  isRead:(BOOL)isRead
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                       completionHandler:(FBSessionStateHandler)handler {
    // is everything in good order?
    [FBSession validateRequestForPermissions:permissions
                             defaultAudience:defaultAudience
                          allowSystemAccount:allowSystemAccount
                                      isRead:isRead];
    BOOL result = NO;
    FBSession *session = [[[FBSession alloc] initWithAppID:nil
                                               permissions:permissions
                                           defaultAudience:defaultAudience
                                           urlSchemeSuffix:nil
                                        tokenCacheStrategy:nil]
                          autorelease];
    if (allowLoginUI || session.state == FBSessionStateCreatedTokenLoaded) {
        [FBSession setActiveSession:session];
        // we open after the fact, in order to avoid overlapping close
        // and open handler calls for blocks
        FBSessionLoginBehavior howToBehave = allowSystemAccount ?
                                                FBSessionLoginBehaviorUseSystemAccountIfPresent :
                                                    FBSessionLoginBehaviorWithFallbackToWebView;
        [session openWithBehavior:howToBehave
                completionHandler:handler];
        result = session.isOpen;
    }
    return result;
}

+ (FBSession*)activeSessionIfExists {
    return g_activeSession;
}

+ (FBSession*)activeSessionIfOpen {
    if (g_activeSession.isOpen) {
        return FBSession.activeSession;
    }
    return nil;
}

+ (void)validateRequestForPermissions:(NSArray*)permissions
                      defaultAudience:(FBSessionDefaultAudience)defaultAudience
                   allowSystemAccount:(BOOL)allowSystemAccount
                               isRead:(BOOL)isRead {
    // validate audience argument
    if ([permissions count]) {
        if (allowSystemAccount && !isRead) {
            switch (defaultAudience) {
                case FBSessionDefaultAudienceEveryone:
                case FBSessionDefaultAudienceFriends:
                case FBSessionDefaultAudienceOnlyMe:
                    break;
                default:
                    [[NSException exceptionWithName:FBInvalidOperationException
                                             reason:@"FBSession: Publish permissions were requested "
                      @"without specifying an audience; use FBSessionDefaultAudienceJustMe, "
                      @"FBSessionDefaultAudienceFriends, or FBSessionDefaultAudienceEveryone"
                                           userInfo:nil]
                     raise];
                    break;
            }
        }
        // log unexpected permissions, and throw on read w/publish permissions
        if (allowSystemAccount &&
            [FBSession logIfFoundUnexpectedPermissions:permissions isRead:isRead] &&
            isRead) {
            [[NSException exceptionWithName:FBInvalidOperationException
                                     reason:@"FBSession: Publish or manage permissions are not permitted to "
              @"to be requested with read permissions."
                                   userInfo:nil]
             raise];
        }
    }
}

// This method is used to support early versions of native login that were using the
// platform module's error domain to pass through server errors. The goal is to put those
// errors in a separate domain to avoid collisions.
+ (NSError *)sdkSurfacedErrorForNativeLoginError:(NSError *)nativeLoginError {
    NSError *error = nativeLoginError;
    if ([nativeLoginError.domain isEqualToString:FacebookNativeApplicationDomain]) {
        error = [NSError errorWithDomain:FacebookNativeApplicationLoginDomain
                                    code:nativeLoginError.code
                                userInfo:nativeLoginError.userInfo];
    }
    
    return error;
}

+ (BOOL)logIfFoundUnexpectedPermissions:(NSArray*)permissions
                                 isRead:(BOOL)isRead {
    BOOL publishPermissionFound = NO;
    BOOL readPermissionFound = NO;
    BOOL result = NO;
    for (NSString *p in permissions) {
        if ([FBUtility isPublishPermission:p]) {
            publishPermissionFound = YES;
        } else {
            readPermissionFound = YES;
        }

        // If we've found one of each we can stop looking.
        if (publishPermissionFound && readPermissionFound) {
            break;
        }
    }

    if (!isRead && readPermissionFound) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"FBSession: a permission request for publish or manage permissions contains unexpected read permissions"];
        result = YES;
    }
    if (isRead && publishPermissionFound) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"FBSession: a permission request for read permissions contains unexpected publish or manage permissions"];
        result = YES;
    }
    
    return result;
}



+ (void)deleteFacebookCookies {
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:FBDialogBaseURL]];

    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

- (void)closeAndClearTokenInformation:(NSError*) error {
    [self checkThreadAffinity];
    
    [[FBDataDiskCache sharedCache] removeDataForSession:self];
    [self.tokenCachingStrategy clearToken];
    
    // If we are not already in a terminal state, go to Closed.
    if (!FB_ISSESSIONSTATETERMINAL(self.state)) {
        [self transitionAndCallHandlerWithState:FBSessionStateClosed
                                          error:error
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO
                                      loginType:FBSessionLoginTypeNone];
    }
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
        case FBSessionStateCreatedOpening:
            stateDescription = @"FBSessionStateCreatedOpening";
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
            self.accessTokenData.expirationDate,
            self.accessTokenData.refreshDate,
            self.attemptedRefreshDate,
            [self.accessTokenData.permissions description]];    
}

#pragma mark -

@end
