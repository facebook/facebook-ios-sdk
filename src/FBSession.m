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

// the sooner we can remove these the better
#import "Facebook.h"
#import "FBLoginDialog.h"

// these are helpful macros for testing various login methods, should always checkin as NO/NO
#define TEST_DISABLE_MULTITASKING_LOGIN NO
#define TEST_DISABLE_FACEBOOKLOGIN NO

// extern const strings
NSString *const FBErrorLoginFailedReasonInlineCancelledValue = @"com.facebook.sdk:InlineLoginCancelled";
NSString *const FBErrorLoginFailedReasonInlineNotCancelledValue = @"com.facebook.sdk:ErrorLoginNotCancelled";

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

// the following constant strings are used by NSNotificationCenter
NSString *const FBSessionDidSetActiveSessionNotification = @"com.facebook.sdk:FBSessionDidSetActiveSessionNotification";
NSString *const FBSessionDidUnsetActiveSessionNotification = @"com.facebook.sdk:FBSessionDidUnsetActiveSessionNotification";
NSString *const FBSessionDidBecomeOpenActiveSessionNotification = @"com.facebook.sdk:FBSessionDidBecomeOpenActiveSessionNotification";
NSString *const FBSessionDidBecomeClosedActiveSessionNotification = @"com.facebook.sdk:FBSessionDidBecomeClosedActiveSessionNotification";

// the following const strings name properties for which KVO is manually handled
// if name changes occur, these strings must be modified to match, else KVO will fail
static NSString *const FBisOpenPropertyName = @"isOpen";
static NSString *const FBstatusPropertyName = @"status";
static NSString *const FBaccessTokenPropertyName = @"accessToken";
static NSString *const FBexpirationDatePropertyName = @"expirationDate";

static int const FBTokenExtendThresholdSeconds = 24 * 60 * 60;  // day
static int const FBTokenRetryExtendSeconds = 60 * 60;           // hour

// module scoped globals
static NSString *g_defaultAppID = nil;
static FBSession *g_activeSession = nil;

@interface FBSession () <FBLoginDialogDelegate> {
    @private
    // public-property ivars
    NSString *_urlSchemeSuffix;

    // private property and non-property ivars
    BOOL _isInStateTransition;
    BOOL _isFacebookLoginToken;
    BOOL _isOSIntegratedFacebookLoginToken;
    FBSessionLoginType _loginTypeOfPendingOpenUrlCallback;
    FBSessionDefaultAudience _defaultDefaultAudience;
}

// private setters
@property(readwrite)            FBSessionState state;
@property(readwrite, copy)      NSString *appID;
@property(readwrite, copy)      NSString *urlSchemeSuffix;
@property(readwrite, copy)      NSString *accessToken;
@property(readwrite, copy)      NSDate *expirationDate;
@property(readwrite, copy)      NSArray *permissions;
@property(readwrite)            FBSessionLoginType loginType;

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
- (void)authorizeWithPermissions:(NSArray*)permissions
                 defaultAudience:(FBSessionDefaultAudience)audience
                  integratedAuth:(BOOL)tryIntegratedAuth
                       FBAppAuth:(BOOL)tryFBAppAuth
                      safariAuth:(BOOL)trySafariAuth
                        fallback:(BOOL)tryFallback
                   isReauthorize:(BOOL)isReauthorize;
- (void)authorizeUsingSystemAccountStore:(id)accountStore
                             accountType:(id)accountType
                             permissions:(NSArray*)permissions
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                           isReauthorize:(BOOL)isReauthorize;
- (BOOL)handleOpenURLPreOpen:(NSDictionary*)parameters
                 accessToken:(NSString*)accessToken
                   loginType:(FBSessionLoginType)loginType;
- (BOOL)handleOpenURLReauthorize:(NSDictionary*)parameters
                     accessToken:(NSString*)accessToken;
- (void)completeReauthorizeWithAccessToken:(NSString*)accessToken
                            expirationDate:(NSDate*)expirationDate
                               permissions:(NSArray*)permissions;
- (void)reauthorizeWithPermissions:(NSArray*)permissions
                            isRead:(BOOL)isRead
                          behavior:(FBSessionLoginBehavior)behavior
                   defaultAudience:(FBSessionDefaultAudience)audience
                 completionHandler:(FBSessionReauthorizeResultHandler)handler;
- (void)callReauthorizeHandlerAndClearState:(NSError*)error;

// class members
+ (BOOL)areRequiredPermissions:(NSArray*)requiredPermissions
          aSubsetOfPermissions:(NSArray*)cachedPermissions;
+ (NSString *)sessionStateDescription:(FBSessionState)sessionState;
+ (BOOL)openActiveSessionWithPermissions:(NSArray*)permissions
                            allowLoginUI:(BOOL)allowLoginUI
                      allowSystemAccount:(BOOL)allowSystemAccount
                                  isRead:(BOOL)isRead
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                       completionHandler:(FBSessionStateHandler)handler;
+ (void)validateRequestForPermissions:(NSArray*)permissions
                      defaultAudience:(FBSessionDefaultAudience)defaultAudience
                   allowSystemAccount:(BOOL)allowSystemAccount
                               isRead:(BOOL)isRead;
+ (BOOL)logIfFoundUnexpectedPermissions:(NSArray*)permissions
                                 isRead:(BOOL)isRead;
+ (NSArray*)addBasicInfoPermission:(NSArray*)permissions;
+ (BOOL)isPublishPermission:(NSString*)permission;
+ (BOOL)areAllPermissionsReadPermissions:(NSArray*)permissions;

@end

@implementation FBSession : NSObject

@synthesize
            // public properties
            appID = _appID,
            permissions = _permissions,
            loginType = _loginType,

            // following properties use manual KVO -- changes to names require
            // changes to static property name variables (e.g. FBisOpenPropertyName)
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
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
        _isOSIntegratedFacebookLoginToken = NO;
        _defaultDefaultAudience = defaultAudience;
        self.attemptedRefreshDate = [NSDate distantPast];
        self.refreshDate = nil;
        self.state = FBSessionStateCreated;
        self.loginType = FBSessionLoginTypeNone;
        self.affinitizedThread = [NSThread currentThread];
        [FBLogger registerCurrentTime:FBLoggingBehaviorPerformanceCharacteristics
                              withTag:self];

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
                FBSessionLoginType loginType = [[tokenInfo objectForKey:FBTokenInformationLoginTypeLoginKey] intValue];
                _isOSIntegratedFacebookLoginToken = loginType == FBSessionLoginTypeSystemAccount;
                
                // set the state and token info
                [self transitionToState:FBSessionStateCreatedTokenLoaded
                         andUpdateToken:cachedToken
                      andExpirationDate:cachedTokenExpirationDate
                            shouldCache:NO
                              loginType:loginType];
            } else {
                // else this token is expired and should be cleared from cache
                [tokenCachingStrategy clearToken];
            }
        }

        [FBSettings autoPublishInstall:self.appID];
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
                                 reason:@"FBSession: an attempt was made to open an already opened or closed session"
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
                    shouldCache:NO
                      loginType:FBSessionLoginTypeNone];

        [self authorizeWithPermissions:self.permissions
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
    [self reauthorizeWithPermissions:readPermissions
                              isRead:YES
                            behavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     defaultAudience:FBSessionDefaultAudienceNone
                   completionHandler:handler];
}

- (void)reauthorizeWithPublishPermissions:(NSArray*)writePermissions
                        defaultAudience:(FBSessionDefaultAudience)audience
                      completionHandler:(FBSessionReauthorizeResultHandler)handler {
    [self reauthorizeWithPermissions:writePermissions
                              isRead:NO
                            behavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                     defaultAudience:audience
                   completionHandler:handler];
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
                                shouldCache:NO
                                  loginType:FBSessionLoginTypeNone];
}

- (void)closeAndClearTokenInformation {
    [self closeAndClearTokenInformation:nil];
}

- (BOOL)handleOpenURL:(NSURL *)url {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");

    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    if (![[url absoluteString] hasPrefix:self.appBaseUrl]) {
        return NO;
    }
    FBSessionLoginType loginType = _loginTypeOfPendingOpenUrlCallback;
    _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
    
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
                                  accessToken:accessToken
                                    loginType:loginType];
        case FBSessionStateOpen:
        case FBSessionStateOpenTokenExtended:
            return [self handleOpenURLReauthorize:params
                                      accessToken:accessToken];
        default:
            FBConditionalLog(NO, @"handleOpenURL should not be called once a session has closed");
            return NO;
    }
}

- (void)handleDidBecomeActive{
    //Unexpected to calls to app delegate's applicationDidBecomeActive are
    // handled by this method. If a pending fast-app-switch [re]authorization
    // is in flight, it is cancelled. Otherwise, this method is a no-op.

    const FBSessionState state = FBSession.activeSession.state;
    
    if (state == FBSessionStateCreated ||
        state == FBSessionStateClosed ||
        state == FBSessionStateClosedLoginFailed){
        return;
    }
    
    if (_loginTypeOfPendingOpenUrlCallback != FBSessionLoginTypeNone){
        if (state == FBSessionStateCreatedOpening){
            //if we're here, user had declined a fast app switch login.
            [FBSession.activeSession close];
        } else {
            //this means the user declined a 'reauthorization' so we need
            // to clean out the in-flight request.
            NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                         errorCode:nil
                                                        innerError:nil];
            [self callReauthorizeHandlerAndClearState:error];
        }
        _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
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

//calls ios6 renewCredentialsForAccount in order to update ios6's worldview of authorization state.
// if not using ios6 system auth, this is a no-op.
+ (void)renewSystemAuthorization {
    id accountStore = nil;
    id accountTypeFB = nil;
    
    if ((accountStore = [[[ACAccountStore alloc] init] autorelease]) &&
        (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] ) ){
        
        NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
        id account;
        if (fbAccounts && [fbAccounts count] > 0 &&
            (account = [fbAccounts objectAtIndex:0])){
            
            [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                //we don't actually need to inspect renewResult or error.
                if (error){
                    [FBLogger singleShotLogEntry:FBLoggingBehaviorAccessTokens
                                        logEntry:[NSString stringWithFormat:@"renewCredentialsForAccount result:%d, error: %@",
                                                  renewResult,
                                                  error]];
                }
            }];
        }
    }
}

#pragma mark -
#pragma mark Private Members

// private methods are broken into two categories: core session and helpers

// core session members

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
    
    // if we are just about to transition to open or token loaded, and the caller
    // wants to specify a login type other than none, then we set the login type
    if (isValidTransition &&
        (state == FBSessionStateOpen || state == FBSessionStateCreatedTokenLoaded) &&
        loginType != FBSessionLoginTypeNone) {
        self.loginType = loginType;
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
            
            [tokenInfo setObject:[NSNumber numberWithInt:self.loginType] forKey:FBTokenInformationLoginTypeLoginKey];
            
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
                     isReauthorize:isReauthorize];
}

- (void)authorizeWithPermissions:(NSArray*)permissions
                 defaultAudience:(FBSessionDefaultAudience)defaultAudience
                  integratedAuth:(BOOL)tryIntegratedAuth
                       FBAppAuth:(BOOL)tryFBAppAuth
                      safariAuth:(BOOL)trySafariAuth 
                        fallback:(BOOL)tryFallback
                   isReauthorize:(BOOL)isReauthorize {
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
    
    // we prefer OS-integrated Facebook login if supported by the device
    // attempt to open an account store with the type Facebook; and if successful authorize
    // using the OS
    BOOL didAuthNWithSystemAccount = NO;
    
    id accountStore = nil;
    id accountTypeFB = nil;
    // do we want and have the ability to attempt integrated authn
    if (tryIntegratedAuth &&
        (!isReauthorize || _isOSIntegratedFacebookLoginToken) &&
        (accountStore = [[[NSClassFromString(@"ACAccountStore") alloc] init] autorelease]) &&
        (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:@"com.apple.facebook"])) {
                
        // looks like we will get to attempt a login with integrated authn
        didAuthNWithSystemAccount = YES;
        
        [self authorizeUsingSystemAccountStore:accountStore
                                   accountType:accountTypeFB
                                   permissions:permissions
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
            
            _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookApplication;
            didAuthNWithSystemAccount = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }

        if (trySafariAuth && !didAuthNWithSystemAccount) {
            NSString *nextUrl = self.appBaseUrl;
            [params setValue:nextUrl forKey:@"redirect_uri"];

            NSString *fbAppUrl = [FBRequest serializeURL:loginDialogURL params:params];
            _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeFacebookViaSafari;
            didAuthNWithSystemAccount = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }
        //In case openURL failed, make sure we don't still expect a openURL callback.
        if (!didAuthNWithSystemAccount){
            _loginTypeOfPendingOpenUrlCallback = FBSessionLoginTypeNone;
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

- (void)authorizeUsingSystemAccountStore:(ACAccountStore*)accountStore
                             accountType:(ACAccountType*)accountType
                             permissions:(NSArray*)permissions
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                           isReauthorize:(BOOL)isReauthorize {
    
    // app may be asking for nothing, but we will always have an array here
    NSArray *permissionsToUse = permissions ? permissions : [NSArray array];
    if ([FBSession areAllPermissionsReadPermissions:permissions]) {
        // If we have only read permissions being requested, ensure that basic info
        //  is among the permissions requested.
        permissionsToUse = [FBSession addBasicInfoPermission:permissionsToUse];
    }
    
    NSString *audience;
    switch (defaultAudience) {
        case FBSessionDefaultAudienceOnlyMe:
            audience = ACFacebookAudienceOnlyMe;
            break;
        case FBSessionDefaultAudienceFriends:
            audience = ACFacebookAudienceFriends;
            break;
        case FBSessionDefaultAudienceEveryone:
            audience = ACFacebookAudienceEveryone;
            break;
        default:
            audience = nil;
    }
    
    // no publish_* permissions are permitted with a nil audience
    if (!audience && isReauthorize) {
        for (NSString *p in permissions) {
            if ([p hasPrefix:@"publish"]) {
                [[NSException exceptionWithName:FBInvalidOperationException
                                         reason:@"FBSession: One or more publish permission was requested "
                  @"without specifying an audience; use FBSessionDefaultAudienceJustMe, "
                  @"FBSessionDefaultAudienceFriends, or FBSessionDefaultAudienceEveryone"
                                       userInfo:nil]
                 raise];
            }
        }
    }
    
    // construct access options
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             self.appID, ACFacebookAppIdKey,
                             permissionsToUse, ACFacebookPermissionsKey,
                             audience, ACFacebookAudienceKey, // must end on this key/value due to audience possibly being nil
                             nil];
    
    // we will attempt an iOS integrated facebook login
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:^(BOOL granted, NSError *error) {
                                           FBConditionalLog(granted || error.code != ACErrorPermissionDenied ||
                                                            [error.description rangeOfString:
                                                                @"remote_app_id does not match stored id"].location == NSNotFound,
                                                            @"System authorization failed:'%@'. This may be caused by a mismatch between"
                                                            @" the bundle identifier and your app configuration on the server"
                                                            @" at developers.facebook.com/apps.",
                                                            error.localizedDescription);
                                           
                                           // this means the user has not signed-on to Facebook via the OS
                                           BOOL isUntosedDevice = (!granted && error.code == ACErrorAccountNotFound);
                                           
                                           // requestAccessToAccountsWithType:options:completion: completes on an
                                           // arbitrary thread; let's process this back on our main thread
                                           dispatch_async( dispatch_get_main_queue(), ^{
                                               NSString *oauthToken = nil;
                                               if (granted) {
                                                   NSArray *fbAccounts = [accountStore accountsWithAccountType:accountType];
                                                   id account = [fbAccounts objectAtIndex:0];
                                                   id credential = [account credential];
                                                   
                                                   oauthToken = [credential oauthToken];
                                               }
                                               
                                               // initial auth case
                                               if (!isReauthorize) {
                                                   if (oauthToken) {
                                                       _isFacebookLoginToken = YES;
                                                       _isOSIntegratedFacebookLoginToken = YES;
                                                       
                                                       // we received a token just now
                                                       self.refreshDate = [NSDate date];
                                                       
                                                       // set token and date, state transition, and call the handler if there is one
                                                       [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                                                                         error:nil
                                                                                         token:oauthToken
                                                        // BUG: we need a means for fetching the expiration date of the token
                                                                                expirationDate:[NSDate distantFuture]
                                                                                   shouldCache:YES
                                                                                     loginType:FBSessionLoginTypeSystemAccount];
                                                   } else if (isUntosedDevice) {
                                                       // even when OS integrated auth is possible we use native-app/safari
                                                       // login if the user has not signed on to Facebook via the OS
                                                       [self authorizeWithPermissions:permissions
                                                                      defaultAudience:defaultAudience
                                                                       integratedAuth:NO
                                                                            FBAppAuth:YES
                                                                           safariAuth:YES
                                                                             fallback:YES
                                                                        isReauthorize:NO];
                                                   } else {
                                                       // create an error object with additional info regarding failed login
                                                       NSError *err = [FBSession errorLoginFailedWithReason:FBErrorLoginFailedReason
                                                                                                    errorCode:nil
                                                                                                   innerError:error];
                                                       
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
                                                       // union the requested permissions with the already granted permissions
                                                       NSMutableSet *set = [NSMutableSet setWithArray:self.permissions];
                                                       [set addObjectsFromArray:permissions];
                                                       
                                                       // complete the operation: success
                                                       [self completeReauthorizeWithAccessToken:oauthToken
                                                                                 expirationDate:[NSDate distantFuture]
                                                                                    permissions:[set allObjects]];
                                                   } else {
                                                       // no token in this case implies that the user cancelled the permissions upgrade
                                                       NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                                                                    errorCode:nil
                                                                                                   innerError:nil];
                                                       // complete the operation: failed
                                                       [self callReauthorizeHandlerAndClearState:error];
                                                       
                                                       // if we made it this far into the reauth case with an untosed device, then
                                                       // it is time to invalidate the session
                                                       if (isUntosedDevice) {
                                                           [self closeAndClearTokenInformation];
                                                       }
                                                   }
                                               }
                                           });
                                       }];

}

- (BOOL)handleOpenURLPreOpen:(NSDictionary*)parameters
                 accessToken:(NSString*)accessToken
                   loginType:(FBSessionLoginType)loginType {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [parameters objectForKey:@"error"];
        
        // if the error response indicates that we should try again using Safari, open
        // the authorization dialog in Safari.
        if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
            [self authorizeWithPermissions:self.permissions
                           defaultAudience:_defaultDefaultAudience
                            integratedAuth:NO
                                 FBAppAuth:NO
                                safariAuth:YES
                                  fallback:NO
                             isReauthorize:NO];
            return YES;
        }
        
        // if the error response indicates that we should try the authorization flow
        // in an inline dialog, do that.
        if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
            [self authorizeWithPermissions:self.permissions
                           defaultAudience:_defaultDefaultAudience
                            integratedAuth:NO
                                 FBAppAuth:NO
                                safariAuth:NO
                                  fallback:NO
                             isReauthorize:NO];
            return YES;
        }
        
        // the facebook app may return an error_code parameter in case it
        // encounters a UIWebViewDelegate error
        NSString *errorCode = [parameters objectForKey:@"error_code"];
        
        // create an error object with additional info regarding failed login
        NSError *error = [FBSession errorLoginFailedWithReason:errorReason
                                                     errorCode:errorCode
                                                    innerError:nil];
        
        // state transition, and call the handler if there is one
        [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                          error:error
                                          token:nil
                                 expirationDate:nil
                                    shouldCache:NO
                                      loginType:FBSessionLoginTypeNone];
    } else {
        
        // we have an access token, so parse the expiration date.
        NSString *expTime = [parameters objectForKey:@"expires_in"];
        NSDate *expirationDate = [FBSession expirationDateFromExpirationTimeString:expTime];
        if (!expirationDate) {
            expirationDate = [NSDate distantFuture];
        }
        
        _isFacebookLoginToken = YES;
        _isOSIntegratedFacebookLoginToken = NO;
        
        // we received a token just now
        self.refreshDate = [NSDate date];
        
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

- (BOOL)handleOpenURLReauthorize:(NSDictionary*)parameters
                     accessToken:(NSString*)accessToken {
    // if the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        // no token in this case implies that the user cancelled the permissions upgrade
        NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonUserCancelled
                                                     errorCode:nil
                                                    innerError:nil];
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
                    id newPermissions = [[permissionsRefreshed objectAtIndex:0] allKeys];
                    if (![newPermissions isKindOfClass:[NSArray class]]) {
                        newPermissions = nil;
                    }
                    [self completeReauthorizeWithAccessToken:accessToken
                                              expirationDate:expirationDate
                                                 permissions:newPermissions];
                } else {
                    // no we don't have matching FBIDs, then we fail on these grounds
                    NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonWrongUser
                                                                 errorCode:nil
                                                                innerError:nil];
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

- (void)reauthorizeWithPermissions:(NSArray*)permissions
                            isRead:(BOOL)isRead
                          behavior:(FBSessionLoginBehavior)behavior
                   defaultAudience:(FBSessionDefaultAudience)audience
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
    // we received a token just now
    self.refreshDate = [NSDate date];
    
    if (permissions) {
        self.permissions = permissions;
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

- (void)refreshAccessToken:(NSString*)token 
            expirationDate:(NSDate*)expireDate {
    // refreshing now
    self.refreshDate = [NSDate date];
    
    // refresh token and date, state transition, and call the handler if there is one
    [self transitionAndCallHandlerWithState:FBSessionStateOpenTokenExtended
                                      error:nil
                                      token:token ? token : self.accessToken
                             expirationDate:expireDate
                                shouldCache:YES
                                  loginType:FBSessionLoginTypeNone];
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
                                shouldCache:YES
                                  loginType:FBSessionLoginTypeWebView];
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

// private helpers

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

    // release the object's count on the handler, but copy (not retain, since it is a block)
    // a stack ref to use as our callback outside of the lock
    FBSessionStateHandler handler = [self.loginHandler retain];

    // the moment we transition to a terminal state, we release our handlers, and possibly fail-call reauthorize
    if (didTransition && FB_ISSESSIONSTATETERMINAL(self.state)) {
        self.loginHandler = nil;

        NSError *error = [FBSession errorLoginFailedWithReason:FBErrorReauthorizeFailedReasonSessionClosed
                                                     errorCode:nil
                                                    innerError:nil];
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
                             errorCode:(NSString*)errorCode
                            innerError:(NSError*)innerError {
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
    if (innerError) {
        [userinfo setObject:innerError
                     forKey:FBErrorInnerErrorKey];
    }

    // create error object
    NSError *err = [NSError errorWithDomain:FacebookSDKDomain
                                      code:FBErrorLoginFailedOrCancelled
                                  userInfo:userinfo];
    [userinfo release];
    return err;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    // these properties must manually notify for KVO
    if ([key isEqualToString:FBisOpenPropertyName] ||
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
                                     reason:@"FBSession: Publish or manage permissions are not permited to "
              @"to be requested with read permissions."
                                   userInfo:nil]
             raise];
        }
    }
}

+ (BOOL)isPublishPermission:(NSString*)permission {
    return [permission hasPrefix:@"publish"] ||
        [permission hasPrefix:@"manage"] ||
        [permission isEqualToString:@"ads_management"] ||
        [permission isEqualToString:@"create_event"] ||
        [permission isEqualToString:@"rsvp_event"];
}

+ (BOOL)areAllPermissionsReadPermissions:(NSArray*)permissions {
    for (NSString *permission in permissions) {
        if ([self isPublishPermission:permission]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)logIfFoundUnexpectedPermissions:(NSArray*)permissions
                                 isRead:(BOOL)isRead {
    BOOL publishPermissionFound = NO;
    BOOL readPermissionFound = NO;
    BOOL result = NO;
    for (NSString *p in permissions) {
        if ([self isPublishPermission:p]) {
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
        FBConditionalLog(NO, @"FBSession: a permission request for publish or manage permissions contains unexpected read permissions");
        result = YES;
    }
    if (isRead && publishPermissionFound) {
        FBConditionalLog(NO, @"FBSession: a permission request for read permissions contains unexpected publish or manage permissions");
        result = YES;
    }
    
    return result;
}

+ (NSArray*)addBasicInfoPermission:(NSArray*)permissions {
    // When specifying read permissions, be sure basic info is included; "email" is used
    // as a proxy for basic info permission.
    for (NSString *p in permissions) {
        if ([p isEqualToString:@"email"]) {
            // Already requested, don't need to add it again.
            return permissions;
        }
    }

    NSMutableArray *newPermissions = [NSMutableArray arrayWithArray:permissions];
    [newPermissions addObject:@"email"];
    return newPermissions;
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

- (void)closeAndClearTokenInformation:(NSError*) error {
    NSAssert(self.affinitizedThread == [NSThread currentThread], @"FBSession: should only be used from a single thread");
    
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
            self.expirationDate,
            self.refreshDate,
            self.attemptedRefreshDate,
            [self.permissions description]];    
}

#pragma mark -

@end
