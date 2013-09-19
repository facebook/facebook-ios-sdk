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
#import "FBSessionAppSwitchingLoginStategy.h"
#import "FBSessionInlineWebViewLoginStategy.h"
#import "FBSessionSystemLoginStategy.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBSessionUtility.h"
#import "FBSettings.h"
#import "FBSettings+Internal.h"
#import "FBError.h"
#import "FBLogger.h"
#import "FBUtility.h"
#import "FBDataDiskCache.h"
#import "FBSystemAccountStoreAdapter.h"
#import "FBAccessTokenData+Internal.h"
#import "FBAppEvents.h"
#import "FBAppEvents+Internal.h"
#import "FBLoginDialogParams.h"
#import "FBAppCall+Internal.h"
#import "FBDialogs+Internal.h"
#import "FBAppBridge.h"
#import "FBSessionAuthLogger.h"

// the sooner we can remove these the better
#import "Facebook.h"
#import "FBLoginDialog.h"

// for unit testing mode only (DO NOT store application secrets in a published application plist)
static NSString *const FBAuthURLScheme = @"fbauth";
static NSString *const FBAuthURLPath = @"authorize";
static NSString *const FBRedirectURL = @"fbconnect://success";
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
// A hack to the session state machine to enable repairing of sessions
// (i.e., for sessions whose token have been invalidated such as by
// expiration or password change was NOT un-tossed). We use this flag
// to avoid changing the FBSessionState surface area and to re-use
// the re-auth flow.
@property(atomic, assign)       BOOL isRepairing;

// private properties
@property(readwrite, retain)    FBSessionTokenCachingStrategy *tokenCachingStrategy;
@property(readwrite, copy)      NSDate *attemptedRefreshDate;
@property(readwrite, copy)      NSDate *attemptedPermissionsRefreshDate;
@property(readwrite, copy)      FBSessionStateHandler loginHandler;
@property(readwrite, copy)      FBSessionRequestPermissionResultHandler reauthorizeHandler;
@property(readonly)             NSString *appBaseUrl;
@property(readwrite, retain)    FBLoginDialog *loginDialog;
@property(readwrite, retain)    NSThread *affinitizedThread;
@property(readwrite, retain)    FBSessionAppEventsState *appEventsState;
@property(readwrite, retain)    FBSessionAuthLogger *authLogger;

@end

@implementation FBSession : NSObject

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
        _appID = [appID copy];
        _initializedPermissions = [permissions copy];
        _urlSchemeSuffix = [urlSchemeSuffix copy];
        _tokenCachingStrategy = [tokenCachingStrategy retain];

        // additional setup
        _isInStateTransition = NO;
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
        _defaultDefaultAudience = defaultAudience;
        _appEventsState = [[FBSessionAppEventsState alloc] init];

        _attemptedRefreshDate = [[NSDate distantPast] copy];
        _attemptedPermissionsRefreshDate = [[NSDate distantPast] copy];
        _state = FBSessionStateCreated;
        _affinitizedThread = [[NSThread currentThread] retain];

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
        BOOL isSubset = [FBSessionUtility areRequiredPermissions:permissions
                                            aSubsetOfPermissions:cachedToken.permissions];
        
        if (isSubset && (NSOrderedDescending == [cachedToken.expirationDate compare:[NSDate date]])) {
            [self transitionToState:FBSessionStateCreatedTokenLoaded
                withAccessTokenData:cachedToken
                        shouldCache:NO];
            return YES;
        }
    }
    return NO;
}

- (void)dealloc {
    [_loginDialog release]; 
    [_attemptedRefreshDate release];
    [_attemptedPermissionsRefreshDate release];
    [_accessTokenData release];
    [_reauthorizeHandler release];
    [_loginHandler release];
    [_appID release];
    [_urlSchemeSuffix release];
    [_initializedPermissions release];
    [_tokenCachingStrategy release];
    [_affinitizedThread release];
    [_appEventsState release];
    [_authLogger release];

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

    switch (behavior) {
        case FBSessionLoginBehaviorForcingWebView:
        case FBSessionLoginBehaviorUseSystemAccountIfPresent:
        case FBSessionLoginBehaviorWithFallbackToWebView:
        case FBSessionLoginBehaviorWithNoFallbackToWebView:
            // valid behavior; no-op.
            break;
        default:
            [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors formatString:@"%d is not a valid FBSessionLoginBehavior. Ignoring open call.", behavior];
            return;
    }
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
            withAccessTokenData:nil
                    shouldCache:NO];
        
        [self authorizeWithPermissions:self.initializedPermissions
                              behavior:behavior
                       defaultAudience:_defaultDefaultAudience
                         isReauthorize:NO];
        
    } else { // self.status == FBSessionStateLoadedValidToken
        
        // this case implies that a valid cached token was found, and preserves the
        // "1-session-1-identity" rule, by transitioning to logged in, without a transition to login UX
        [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                          error:nil
                                      tokenData:nil
                                    shouldCache:NO];
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
                                  tokenData:nil
                                shouldCache:NO];
}

- (void)closeAndClearTokenInformation {
    [self closeAndClearTokenInformation:nil];
}

// Helper method to transistion token state correctly when
// the app is called back in cases of either app switch
// or FBLoginDialog
- (BOOL)handleAuthorizationCallbacks:(NSString *)accessToken params:(NSDictionary *)params loginType:(FBSessionLoginType)loginType {
    // Make sure our logger is setup to finish up the authorization roundtrip
    if (!self.authLogger) {
        NSDictionary *clientState = [FBSessionUtility clientStateFromQueryParams:params];
        NSString *ID = clientState[FBSessionAuthLoggerParamIDKey];
        NSString *authMethod = clientState[FBSessionAuthLoggerParamAuthMethodKey];
        if (ID || authMethod) {
            self.authLogger = [[[FBSessionAuthLogger alloc] initWithSession:self ID:ID authMethod:authMethod] autorelease];
        }
    }
    
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
    
    NSDictionary *params = [FBSessionUtility queryParamsFromLoginURL:url
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
                                                           session:self
                                                   fallbackHandler:^(FBAppCall *call) {
                                                       completionHandlerFound = NO;
                                                   }];
        return handled && completionHandlerFound;
    }
    FBSessionLoginType loginType = _loginTypeOfPendingOpenUrlCallback;
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
    
    NSString *accessToken = [params objectForKey:@"access_token"];
    
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
                                       defaultAudience:FBSessionDefaultAudienceNone
                                     completionHandler:handler];
}

// This should only be used by internal code that needs to support mixed
// permissions backwards compability and specify an audience.
+ (BOOL)openActiveSessionWithPermissions:(NSArray*)permissions
                            allowLoginUI:(BOOL)allowLoginUI
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                       completionHandler:(FBSessionStateHandler)handler {
    return [FBSession openActiveSessionWithPermissions:permissions
                                          allowLoginUI:allowLoginUI
                                    allowSystemAccount:NO
                                                isRead:NO
                                       defaultAudience:defaultAudience
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
// `tokenData` will NOT be retained, it will be used to construct a
// new instance - the difference is for things that should not change
// if the session already had a token (e.g., loginType).
- (BOOL)transitionToState:(FBSessionState)state
      withAccessTokenData:(FBAccessTokenData *)tokenData
              shouldCache:(BOOL)shouldCache {
    
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
                                      [FBSessionUtility sessionStateDescription:statePrior],
                                      [FBSessionUtility sessionStateDescription:state]]];
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
                           [FBSessionUtility sessionStateDescription:statePrior],
                           [FBSessionUtility sessionStateDescription:state]];
    [FBLogger singleShotLogEntry:FBLoggingBehaviorSessionStateTransitions logEntry:logString];
    
    [FBLogger singleShotLogEntry:FBLoggingBehaviorPerformanceCharacteristics 
                    timestampTag:self
                    formatString:@"%@", logString];
    
    // Re-start session transition timer for the next time around.
    [FBLogger registerCurrentTime:FBLoggingBehaviorPerformanceCharacteristics
                          withTag:self];
    
    // identify whether we will update token and date, and what the values will be
    BOOL changingTokenAndDate = NO;
    if (tokenData.accessToken && tokenData.expirationDate) {
        changingTokenAndDate = YES;
    } else if (!FB_ISSESSIONOPENWITHSTATE(state) &&
               FB_ISSESSIONOPENWITHSTATE(statePrior)) {
        changingTokenAndDate = YES;
        tokenData = nil;
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
        FBSessionLoginType newLoginType = tokenData.loginType;
        // if we are just about to transition to open or token loaded, and the caller
        // wants to specify a login type other than none, then we set the login type
        FBSessionLoginType loginTypeUpdated = self.accessTokenData.loginType;
        if (isValidTransition &&
            (state == FBSessionStateOpen || state == FBSessionStateCreatedTokenLoaded) &&
            newLoginType != FBSessionLoginTypeNone) {
            loginTypeUpdated = newLoginType;
        }

        // KVO property will-change notifications for token and date
        [self willChangeValueForKey:FBaccessTokenPropertyName];
        [self willChangeValueForKey:FBaccessTokenDataPropertyName];
        [self willChangeValueForKey:FBexpirationDatePropertyName];
       
        // set the new access token as a copy of any existing token with the updated
        // token string and expiration date.
        if (tokenData.accessToken) {
            FBAccessTokenData *fbAccessToken = [FBAccessTokenData createTokenFromString:tokenData.accessToken
                                                                            permissions:tokenData.permissions
                                                                         expirationDate:tokenData.expirationDate
                                                                              loginType:loginTypeUpdated
                                                                            refreshDate:tokenData.refreshDate
                                                                 permissionsRefreshDate:tokenData.permissionsRefreshDate];
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
    self.authLogger = [[[FBSessionAuthLogger alloc] initWithSession:self] autorelease];
    [self.authLogger addExtrasForNextEvent:@{
     @"tryIntegratedAuth": [NSNumber numberWithBool:tryIntegratedAuth],
     @"tryFBAppAuth": [NSNumber numberWithBool:tryFBAppAuth],
     @"trySafariAuth": [NSNumber numberWithBool:trySafariAuth],
     @"tryFallback": [NSNumber numberWithBool:tryFallback],
     @"isReauthorize": [NSNumber numberWithBool:isReauthorize]
     }];
    
    [self.authLogger logStartAuth];
    
    [self retryableAuthorizeWithPermissions:permissions
                            defaultAudience:defaultAudience
                             integratedAuth:tryIntegratedAuth
                                  FBAppAuth:tryFBAppAuth
                                 safariAuth:trySafariAuth
                                   fallback:tryFallback
                              isReauthorize:isReauthorize
                        canFetchAppSettings:canFetchAppSettings];
}

// NOTE: This method should not be used as the "first" call in the auth-stack. It makes no assumptions about being
// the first either.
- (void)retryableAuthorizeWithPermissions:(NSArray*)permissions
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
    if (permissions != nil) {
        params[@"scope"] = [permissions componentsJoinedByString:@","];
    }
    if (_urlSchemeSuffix) {
        params[@"local_client_id"] = _urlSchemeSuffix;
    }
    
    // To avoid surprises, delete any cookies we currently have.
    [FBUtility deleteFacebookCookies];
    
    BOOL didRequestAuthorize = NO;
    NSString *authMethod = nil;
    
    FBSessionLoginStrategyParams *authorizeParams = [[[FBSessionLoginStrategyParams alloc] init] autorelease];
    authorizeParams.tryIntegratedAuth = tryIntegratedAuth;
    authorizeParams.tryFBAppAuth = tryFBAppAuth;
    authorizeParams.trySafariAuth = trySafariAuth;
    authorizeParams.tryFallback = tryFallback;
    authorizeParams.isReauthorize = isReauthorize;
    authorizeParams.defaultAudience = defaultAudience;
    authorizeParams.permissions = permissions;
    authorizeParams.canFetchAppSettings = canFetchAppSettings;
    authorizeParams.webParams = params;

    // Note ordering is significant here.
    NSArray *loginStrategies = @[ [[[FBSessionSystemLoginStategy alloc] init] autorelease],
                                  [[[FBSessionAppSwitchingLoginStategy alloc] init] autorelease],
                                  [[[FBSessionInlineWebViewLoginStategy alloc] init] autorelease]
                                  ];
    
    for (id<FBSessionLoginStrategy> loginStrategy in loginStrategies) {
        if ([loginStrategy tryPerformAuthorizeWithParams:authorizeParams session:self logger:self.authLogger]) {
            didRequestAuthorize = YES;
            authMethod = loginStrategy.methodName;
            break;
        }
    }
   
    if (didRequestAuthorize) {
        if (authMethod) { // This is a nested-if, because we might not have an authmethod yet if waiting on fetchedAppSettings
            // Some method of authentication was kicked off
            [self.authLogger logStartAuthMethod:authMethod];
        }
    } else {
        // Can't fallback and Facebook Login failed, so transition to an error state
        NSError *error = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonInlineNotCancelledValue
                                                errorCode:nil
                                               innerError:nil];
        
        // state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                          error:error
                                      tokenData:nil
                                    shouldCache:NO];
    }
}

- (void)setLoginTypeOfPendingOpenUrlCallback:(FBSessionLoginType)loginType {
    _loginTypeOfPendingOpenUrlCallback = loginType;
}

- (void)logIntegratedAuthAppEvent:(NSString *)dialogOutcome
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
    
    [FBAppEvents logImplicitEvent:FBAppEventNamePermissionsUILaunch
                      valueToSum:nil
                      parameters:@{ @"ui_dialog_type" : @"iOS integrated auth",
                                    @"permissions_requested" : sortedPermissions }
                         session:self];
    
    [FBAppEvents logImplicitEvent:FBAppEventNamePermissionsUIDismiss
                      valueToSum:nil
                      parameters:@{ @"ui_dialog_type" : @"iOS integrated auth",
                                    FBAppEventParameterDialogOutcome : dialogOutcome,
                                    @"permissions_requested" : sortedPermissions }
                         session:self];
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
            
            unsigned long millisecondsSinceUIWasPotentiallyShown = [FBUtility currentTimeInMilliseconds] - timePriorToShowingUI;
            
            // There doesn't appear to be a reliable way to determine whether or not a UI was invoked
            // to get us here, or whether the cached token was sufficient.  So we use a timer heuristic
            // assuming that human response time couldn't complete a dialog in under the interval
            // given here, but the process will return here fast enough if the token is cached.  The threshold was
            // chosen empirically, so there may be some edge cases that are false negatives or false positives.
            BOOL dialogWasShown = millisecondsSinceUIWasPotentiallyShown > 350;

            [self.authLogger addExtrasForNextEvent:@{
             @"isUntosedDevice": [NSNumber numberWithBool:isUntosedDevice],
             @"dialogShown": [NSNumber numberWithBool:dialogWasShown]
             }];
            
            // initial auth case
            if (!isReauthorize) {
                if (oauthToken) {
                    
                    if (dialogWasShown) {
                        [self logIntegratedAuthAppEvent:@"Authorization succeeded"
                                            permissions:permissions];
                    }
                    
                    [self.authLogger logEndAuthMethodWithResult:FBSessionAuthLoggerResultSuccess error:nil];
                    
                     // BUG: we need a means for fetching the expiration date of the token
                    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:oauthToken
                                                                                permissions:permissions
                                                                             expirationDate:[NSDate distantFuture]
                                                                                  loginType:FBSessionLoginTypeSystemAccount
                                                                                refreshDate:[NSDate date]];
                    [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                                      error:nil
                                                  tokenData:tokenData
                                                shouldCache:YES];

                } else if (isUntosedDevice) {
                    
                    // Don't invoke logIntegratedAuthAppEvent, since this is not an 'integrated dialog' case.
                    
                    [self.authLogger logEndAuthMethodWithResult:FBSessionAuthLoggerResultSkipped error:nil];
                    
                    // even when OS integrated auth is possible we use native-app/safari
                    // login if the user has not signed on to Facebook via the OS
                    [self retryableAuthorizeWithPermissions:permissions
                                            defaultAudience:defaultAudience
                                             integratedAuth:NO
                                                  FBAppAuth:YES
                                                 safariAuth:YES
                                                   fallback:YES
                                              isReauthorize:NO
                                        canFetchAppSettings:YES];
                } else {
                    
                    [self logIntegratedAuthAppEvent:@"Authorization cancelled"
                                        permissions:permissions];

                    NSError *err = nil;
                    NSString *authLoggerResult = FBSessionAuthLoggerResultError;
                    if ([accountStoreError.domain isEqualToString:FacebookSDKDomain]){
                        // If the requestAccess call results in a Facebook error, surface it as a top-level
                        // error. This implies it is not the typical user "disallows" case.
                        err = accountStoreError;
                    } else if ([accountStoreError.domain isEqualToString:@"com.apple.accounts"] && accountStoreError.code == 7) {
                        // code 7 is for user cancellations, see ACErrorCode, except that iOS can also
                        // re-use code 7 for other cases like a sandboxed app. In those other cases,
                        // they do provide a NSLocalizedDescriptionKey entry so we'll inspect for that.
                        if (!accountStoreError.userInfo[NSLocalizedDescriptionKey] ||
                            [accountStoreError.userInfo[NSLocalizedDescriptionKey] rangeOfString:@"Invalid application"
                                                                                         options:NSCaseInsensitiveSearch].location == NSNotFound) {
                                err = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonUserCancelledSystemValue
                                                             errorCode:nil
                                                            innerError:accountStoreError];
                                authLoggerResult = FBSessionAuthLoggerResultCancelled;
                            }
                    }
                    
                    if (err == nil) {
                        // create an error object with additional info regarding failed login as a fallback.
                        err = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonSystemError
                                                     errorCode:nil
                                                    innerError:accountStoreError];
                    }
                    
                    [self.authLogger logEndAuthMethodWithResult:authLoggerResult error:err];
                    
                    // state transition, and call the handler if there is one
                    [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                                      error:err
                                                  tokenData:nil
                                                shouldCache:NO];
                }
            } else { // reauth case
                if (oauthToken) {
                    
                    if (dialogWasShown) {
                        [self logIntegratedAuthAppEvent:@"Reauthorization succeeded"
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
                    self.isRepairing = NO;
                    if (dialogWasShown) {
                        [self logIntegratedAuthAppEvent:@"Reauthorization cancelled"
                                            permissions:permissions];
                    }
                    
                    NSError *err;
                    NSString* authLoggerResult = FBSessionAuthLoggerResultSuccess;
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
                        authLoggerResult = FBSessionAuthLoggerResultCancelled;
                    } else {
                        // create an error object with additional info regarding failed login
                        err = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonSystemError
                                                     errorCode:nil
                                                    innerError:accountStoreError];
                    }
                    
                    [self.authLogger logEndAuthMethodWithResult:authLoggerResult error:err];

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

- (FBAppCall *)authorizeUsingFacebookNativeLoginWithPermissions:(NSArray*)permissions
                                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                                             clientState:(NSDictionary *)clientState {
    FBLoginDialogParams *params = [[[FBLoginDialogParams alloc] init] autorelease];
    params.permissions = permissions;
    params.writePrivacy = defaultAudience;
    params.session = self;
    
    FBAppCall *call = [FBDialogs presentLoginDialogWithParams:params
                                                  clientState:clientState
                                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                          [self handleDidCompleteNativeLoginForAppCall:call];
                                                      }];
    if (call) {
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookApplication;
    }
    return call;
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
    // log the time the control was returned to the app for profiling reasons
    [FBAppEvents logImplicitEvent:FBAppEventNameFBDialogsNativeLoginDialogEnd
                    valueToSum:nil
                    parameters:@{
                        FBAppEventsNativeLoginDialogEndTime : [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])],
                        @"action_id" : [call ID],
                        @"app_id" : [FBSettings defaultAppID]
                    }
                    session:nil];
    
    FBSessionLoginType loginType = _loginTypeOfPendingOpenUrlCallback;
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
    
    [self handleAuthorizationCallbacks:params[@"access_token"]
                                params:params
                             loginType:loginType];
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
    [FBSessionUtility addWebLoginStartTimeToParams:params];
    
    NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, FBAuthURLPath];
    NSString *fbAppUrl = [FBRequest serializeURL:urlPrefix params:params];
    
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookApplication;
    return [self tryOpenURL:[NSURL URLWithString:fbAppUrl]];
}

- (BOOL)authorizeUsingSafari:(NSMutableDictionary *)params {
    // add a timestamp for tracking GDP e2e time
    [FBSessionUtility addWebLoginStartTimeToParams:params];

    NSString *loginDialogURL = [[FBUtility dialogBaseURL] stringByAppendingString:FBLoginDialogMethod];

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
    [FBSessionUtility addWebLoginStartTimeToParams:params];

    NSString *loginDialogURL = [[FBUtility dialogBaseURL] stringByAppendingString:FBLoginDialogMethod];
    
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
        
        // the facebook app may return an error_code parameter in case it
        // encounters a UIWebViewDelegate error
        NSString *errorCode = [parameters objectForKey:@"error_code"];
        
        // create an error object with additional info regarding failed login
        // making sure the top level error reason is defined there.
        // If an inner error or another errorReason is present, pass it along
        // as an inner error for the top level error
        NSError *innerError = parameters[FBInnerErrorObjectKey];
        
        NSError *errorToSurface = nil;
        // If we either have an inner error (typically from another source like the native
        // Facebook application), or if we have an error_message, then this is not a
        // cancellation.
        if (innerError) {
            errorToSurface = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonOtherError
                                                    errorCode:errorCode
                                                   innerError:innerError];
        } else if (parameters[@"error_message"]) {
            // If there's no inner error, then we can check for error_message as a signal for
            // other (non-user cancelled) login failures.
            errorToSurface = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonOtherError
                                                    errorCode:errorCode
                                                   innerError:nil
                                         localizedDescription:parameters[@"error_message"]];
        }
        
        NSString *authLoggerResult = FBSessionAuthLoggerResultError;
        if (!errorToSurface) {
            // We must have a cancellation
            authLoggerResult = FBSessionAuthLoggerResultCancelled;
            if (errorReason) {
                // Legacy auth responses have 'error' (or here, errorReason) for cancellations.
                // Store that in an inner error so it isn't lost
                innerError = [self errorLoginFailedWithReason:errorReason errorCode:nil innerError:nil];
            }
            errorToSurface = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonUserCancelledValue
                                                    errorCode:errorCode
                                                   innerError:innerError];
        }
        
        [self.authLogger logEndAuthMethodWithResult:authLoggerResult error:errorToSurface];
        
        // if the error response indicates that we should try again using Safari, open
        // the authorization dialog in Safari.
        if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
            [self retryableAuthorizeWithPermissions:self.initializedPermissions
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
            [self retryableAuthorizeWithPermissions:self.initializedPermissions
                                    defaultAudience:_defaultDefaultAudience
                                     integratedAuth:NO
                                          FBAppAuth:NO
                                         safariAuth:NO
                                           fallback:NO
                                      isReauthorize:NO
                                canFetchAppSettings:YES];
            return YES;
        }
        
        // state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                          error:errorToSurface
                                      tokenData:nil
                                    shouldCache:NO];
    } else {
        [self.authLogger logEndAuthMethodWithResult:FBSessionAuthLoggerResultSuccess error:nil];
        
        // we have an access token, so parse the expiration date.
        NSDate *expirationDate = [FBSessionUtility expirationDateFromResponseParams:parameters];
        
        // set token and date, state transition, and call the handler if there is one
        FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:accessToken
                                                                    permissions:self.initializedPermissions
                                                                 expirationDate:expirationDate
                                                                      loginType:loginType
                                                                    refreshDate:[NSDate date]];
        [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                          error:nil
                                      tokenData:tokenData
                                    shouldCache:YES];
    }
    return YES;
}

- (BOOL)handleReauthorize:(NSDictionary*)parameters
              accessToken:(NSString*)accessToken {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        // no token in this case implies that the user cancelled the permissions upgrade
        NSError *innerError = parameters[FBInnerErrorObjectKey];
        NSString *errorCode = parameters[@"error_code"];
        NSString *authLoggerResult = FBSessionAuthLoggerResultError;

        NSError *errorToSurface = nil;
        // If we either have an inner error (typically from another source like the native
        // Facebook application), or if we have an error_message, then this is not a
        // cancellation.
        if (innerError) {
            errorToSurface = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonOtherError
                                                    errorCode:errorCode
                                                   innerError:innerError];
        } else if (parameters[@"error_message"]) {
            // If there's no inner error, then we can check for error_message as a signal for
            // other (non-user cancelled) login failures.
            errorToSurface = [self errorLoginFailedWithReason:FBErrorLoginFailedReasonOtherError
                                                    errorCode:errorCode
                                                   innerError:nil
                                         localizedDescription:parameters[@"error_message"]];
        }

        if (!errorToSurface) {
            // We must have a cancellation
            authLoggerResult = FBSessionAuthLoggerResultCancelled;
            errorToSurface = [self errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                errorCode:nil
                                               innerError:innerError];
        }
        // in the reauth failure flow, we turn off the repairing flag immediately
        // so that the handler can process the state correctly (i.e., so that
        // the retryManager can close the session).
        self.isRepairing = NO;
        [self.authLogger logEndAuthMethodWithResult:authLoggerResult error:errorToSurface];
        
        [self callReauthorizeHandlerAndClearState:errorToSurface];
    } else {
        
        // we have an access token, so parse the expiration date.
        NSDate *expirationDate = [FBSessionUtility expirationDateFromResponseParams:parameters];
        
        [self validateReauthorizedAccessToken:accessToken expirationDate:expirationDate];
    }

    return YES;    
}

- (void)validateReauthorizedAccessToken:(NSString *)accessToken expirationDate:(NSDate *)expirationDate {
    // If we're coming back from a repair scenario, we skip validation
    if (self.isRepairing) {
        self.isRepairing = NO;
        // Assume permissions are unchanged at this point.
        [self completeReauthorizeWithAccessToken:accessToken
                                  expirationDate:expirationDate
                                     permissions:self.permissions];
        return;
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
                
                [self.authLogger logEndAuthMethodWithResult:FBSessionAuthLoggerResultError error:error];
                
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
    [FBSessionUtility validateRequestForPermissions:permissions
                             defaultAudience:audience
                          allowSystemAccount:behavior == FBSessionLoginBehaviorUseSystemAccountIfPresent
                                      isRead:isRead];
    
    // setup handler and permissions and perform the actual reauthorize
    self.reauthorizeHandler = handler;
    [self authorizeWithPermissions:permissions
                          behavior:behavior
                   defaultAudience:audience
                     isReauthorize:YES];
}

// Internal method for "repairing" a session that has an invalid access token
// by issuing a reauthorize call. If this gets exposed or invoked from more places,
// seriously consider more validation (such as state checking).
// This method will no-op if we're already repairing.
- (void)repairWithHandler:(FBSessionRequestPermissionResultHandler) handler {
    @synchronized (self) {
        if (!self.isRepairing) {
            self.isRepairing = YES;
            FBSessionLoginBehavior loginBehavior;
            switch (self.accessTokenData.loginType) {
                case FBSessionLoginTypeSystemAccount: loginBehavior = FBSessionLoginBehaviorUseSystemAccountIfPresent; break;
                case FBSessionLoginTypeFacebookApplication:
                case FBSessionLoginTypeFacebookViaSafari: loginBehavior = FBSessionLoginBehaviorWithFallbackToWebView; break;
                case FBSessionLoginTypeWebView: loginBehavior = FBSessionLoginBehaviorForcingWebView; break;
                default: loginBehavior = FBSessionLoginBehaviorUseSystemAccountIfPresent;
            }
            
            if (self.reauthorizeHandler) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                    logEntry:@"Warning: a session is being reconnected while there might have been an existing reauthorization in progress. The pre-existing reauthorization will be ignored."];
            }
            self.reauthorizeHandler = handler;
            
            [self authorizeWithPermissions:nil
                                  behavior:loginBehavior
                           defaultAudience:FBSessionDefaultAudienceNone
                             isReauthorize:YES];
        } else {
            // We're already repairing so further attempts at repairs
            // (by other FBRequestConnection instances) should simply
            // be treated as errors (i.e., we do not support queueing
            // until the repair is resolved).
            if (handler) {
                handler(self, [NSError errorWithDomain:FacebookSDKDomain code:FBErrorSessionReconnectInProgess userInfo:nil]);
            }
        }
    }
}

- (void)completeReauthorizeWithAccessToken:(NSString*)accessToken
                            expirationDate:(NSDate*)expirationDate
                               permissions:(NSArray*)permissions {
    [self.authLogger logEndAuthMethodWithResult:FBSessionAuthLoggerResultSuccess error:nil];
    
    // set token and date, state transition, and call the handler if there is one
    NSDate *now = [NSDate date];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:accessToken
                                                                permissions:permissions
                                                             expirationDate:expirationDate
                                                                  loginType:FBSessionLoginTypeNone
                                                                refreshDate:now
                                                     permissionsRefreshDate:now];
    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                      error:nil
                                  tokenData:tokenData
                                shouldCache:YES];
    
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
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:token ?: self.accessTokenData.accessToken
                                                                permissions:self.accessTokenData.permissions
                                                             expirationDate:expireDate
                                                                  loginType:FBSessionLoginTypeNone
                                                                refreshDate:[NSDate date]
                                                     permissionsRefreshDate:self.accessTokenData.permissionsRefreshDate];
    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                      error:nil
                                  tokenData:tokenData
                                shouldCache:YES];
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

// For simplicity, checking `shouldRefreshPermission` will toggle the flag
// such that future calls within the next hour (as defined by the threshold constant)
// will return NO. Therefore, you should only call this method if you are also
// prepared to actually `refreshPermissions`.
- (BOOL)shouldRefreshPermissions {
    @synchronized(self.attemptedPermissionsRefreshDate) {
        NSDate *now = [NSDate date];
        
        if (self.isOpen &&
            // Share the same thresholds as the access token string for convenience, we may change in the future.
            [now timeIntervalSinceDate:self.attemptedPermissionsRefreshDate] > FBTokenRetryExtendSeconds &&
            [now timeIntervalSinceDate:self.accessTokenData.permissionsRefreshDate] > FBTokenExtendThresholdSeconds) {
            self.attemptedPermissionsRefreshDate = now;
            return YES;
        }
    }
    return NO;
}

- (void)refreshPermissions:(NSArray *)permissions {
    NSDate *now = [NSDate date];
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:self.accessTokenData.accessToken
                                                                permissions:permissions
                                                             expirationDate:self.accessTokenData.expirationDate
                                                                  loginType:self.accessTokenData.loginType
                                                                refreshDate:self.accessTokenData.refreshDate
                                                     permissionsRefreshDate:now];
    self.attemptedPermissionsRefreshDate = now;
    // Note we intentionally do not notify KVO that `accessTokenData `is changing since
    // the implied contract is for that to only occur during state transitions.
    self.accessTokenData = tokenData;
    [self.tokenCachingStrategy cacheFBAccessTokenData:self.accessTokenData];
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
                                tokenData:(FBAccessTokenData *)tokenData
                              shouldCache:(BOOL)shouldCache {

    
    // lets get the state transition out of the way
    BOOL didTransition = [self transitionToState:status
                             withAccessTokenData:tokenData
                                     shouldCache:shouldCache];
    
    NSString *authLoggerResult = FBSessionAuthLoggerResultError;
    if (!error) {
        authLoggerResult = ((status == FBSessionStateClosedLoginFailed) ?
                            FBSessionAuthLoggerResultCancelled :
                            FBSessionAuthLoggerResultSuccess);
    } else if ([error.userInfo[FBErrorLoginFailedReason] isEqualToString:FBErrorLoginFailedReasonUserCancelledValue]) {
        authLoggerResult = FBSessionAuthLoggerResultCancelled;
    }
    
    [self.authLogger logEndAuthWithResult:authLoggerResult error:error];
    self.authLogger = nil; // Nil out the logger so there aren't any rogue events logged.

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
    NSString *authLoggerResult = FBSessionAuthLoggerResultSuccess;
    if (error) {
        authLoggerResult = ([error.userInfo[FBErrorLoginFailedReason] isEqualToString:FBErrorReauthorizeFailedReasonUserCancelled] ?
                            FBSessionAuthLoggerResultCancelled :
                            FBSessionAuthLoggerResultError);
    }
    
    [self.authLogger logEndAuthWithResult:authLoggerResult error:error];
    self.authLogger = nil; // Nil out the logger so there aren't any rogue events logged.

    // clear state and call handler
    FBSessionRequestPermissionResultHandler reauthorizeHandler = [self.reauthorizeHandler retain];
    @try {
        self.reauthorizeHandler = nil;
        
        if (reauthorizeHandler) {
            reauthorizeHandler(self, error);
        }
    }
    @finally {
        [reauthorizeHandler release];
    }

    self.isRepairing = NO;
}

- (NSString *)appBaseUrl {
    return [FBUtility stringAppBaseUrlFromAppId:self.appID urlSchemeSuffix:self.urlSchemeSuffix];
}

- (NSError*)errorLoginFailedWithReason:(NSString*)errorReason
                             errorCode:(NSString*)errorCode
                            innerError:(NSError*)innerError {
    return [self errorLoginFailedWithReason:errorReason errorCode:errorCode innerError:innerError localizedDescription:nil];
}

- (NSError*)errorLoginFailedWithReason:(NSString*)errorReason
                             errorCode:(NSString*)errorCode
                            innerError:(NSError*)innerError
                  localizedDescription:(NSString*)localizedDescription {
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
    if (localizedDescription) {
        userinfo[NSLocalizedDescriptionKey] = localizedDescription;
    }
    userinfo[FBErrorSessionKey] = self;
    
    // create error object
    NSError *err = [NSError errorWithDomain:FacebookSDKDomain
                                       code:FBErrorLoginFailedOrCancelled
                                   userInfo:userinfo];
    [userinfo release];
    return err;
}

- (NSString *)jsonClientStateWithDictionary:(NSDictionary *)dictionary{
    NSMutableDictionary *clientState = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], FBLoginUXClientStateIsClientState,
                                 [NSNumber numberWithBool:YES], FBLoginUXClientStateIsOpenSession,
                                 [NSNumber numberWithBool:(self == g_activeSession)], FBLoginUXClientStateIsActiveSession,
                                 nil];
    [clientState addEntriesFromDictionary:dictionary];
    NSString *clientStateString = [FBUtility simpleJSONEncode:clientState];
    
    return clientStateString ?: @"{}";
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

#pragma mark -
#pragma mark Internal members

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
    [FBSessionUtility validateRequestForPermissions:permissions
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

- (void)closeAndClearTokenInformation:(NSError*) error {
    [self checkThreadAffinity];
    
    [[FBDataDiskCache sharedCache] removeDataForSession:self];
    [self.tokenCachingStrategy clearToken];
    
    // If we are not already in a terminal state, go to Closed.
    if (!FB_ISSESSIONSTATETERMINAL(self.state)) {
        [self transitionAndCallHandlerWithState:FBSessionStateClosed
                                          error:error
                                      tokenData:nil
                                    shouldCache:NO];
    }
}

#pragma mark -
#pragma mark Debugging helpers

- (NSString*)description {
    NSString *stateDescription = [FBSessionUtility sessionStateDescription:self.state];
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
