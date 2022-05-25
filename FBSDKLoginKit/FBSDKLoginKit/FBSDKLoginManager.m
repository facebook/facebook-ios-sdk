/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginManager+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <FBSDKLoginKit/FBSDKLoginError.h>
#import <FBSDKLoginKit/FBSDKLoginErrorDomain.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKCodeVerifier.h"
#import "FBSDKLoginCompleterFactory.h"
#import "FBSDKLoginErrorFactory.h"
#import "FBSDKMonotonicTime.h"

static int const FBClientStateChallengeLength = 20;
static NSString *const FBSDKExpectedChallengeKey = @"expected_login_challenge";
static NSString *const FBSDKExpectedNonceKey = @"expected_login_nonce";
static NSString *const FBSDKExpectedCodeVerifierKey = @"expected_login_code_verifier";
static NSString *const FBSDKOauthPath = @"/dialog/oauth";
static NSString *const SFVCCanceledLogin = @"com.apple.SafariServices.Authentication";
static NSString *const ASCanceledLogin = @"com.apple.AuthenticationServices.WebAuthenticationSession";

NSString *const FBSDKLoginManagerLoggerAuthMethod_Browser = @"browser_auth";
NSString *const FBSDKLoginManagerLoggerAuthMethod_SFVC = @"sfvc_auth";
NSString *const FBSDKLoginManagerLoggerAuthMethod_Applink = @"applink_auth";

@implementation FBSDKLoginManager

+ (void)initialize
{
  if (self == [FBSDKLoginManager class]) {
    FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
    [provider loadServerConfigurationWithCompletionBlock:NULL];
  }
}

- (instancetype)init
{
  return [self initWithInternalUtility:FBSDKInternalUtility.sharedUtility
                  keychainStoreFactory:[FBSDKKeychainStoreFactory new]
                     accessTokenWallet:FBSDKAccessToken.class
                   authenticationToken:FBSDKAuthenticationToken.class
                               profile:FBSDKProfile.class
                             urlOpener:FBSDKBridgeAPI.sharedInstance
                              settings:FBSDKSettings.sharedSettings
                 loginCompleterFactory:[FBSDKLoginCompleterFactory new]
                   graphRequestFactory:[FBSDKGraphRequestFactory new]];
}

- (instancetype)initWithInternalUtility:(id<FBSDKURLHosting, FBSDKAppURLSchemeProviding, FBSDKAppAvailabilityChecker>)internalUtility
                   keychainStoreFactory:(id<FBSDKKeychainStoreProviding>)keychainStoreFactory
                      accessTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)accessTokenWallet
                    authenticationToken:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationToken
                                profile:(Class<FBSDKProfileProviding>)profile
                              urlOpener:(id<FBSDKURLOpener>)urlOpener
                               settings:(id<FBSDKSettings>)settings
                  loginCompleterFactory:(id<FBSDKLoginCompleterFactory>)loginCompleterFactory
                    graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  if ((self = [super init])) {
    _internalUtility = internalUtility;
    _accessTokenWallet = accessTokenWallet;
    _authenticationToken = authenticationToken;
    _profile = profile;
    _urlOpener = urlOpener;
    NSString *keyChainServiceIdentifier = [NSString stringWithFormat:@"com.facebook.sdk.loginmanager.%@", NSBundle.mainBundle.bundleIdentifier];

    _keychainStore = [keychainStoreFactory createKeychainStoreWithService:keyChainServiceIdentifier
                                                              accessGroup:nil];
    _settings = settings;
    _loginCompleterFactory = loginCompleterFactory;
    _graphRequestFactory = graphRequestFactory;
  }
  return self;
}

- (void)logInFromViewController:(UIViewController *)viewController
                  configuration:(FBSDKLoginConfiguration *)configuration
                     completion:(FBSDKLoginManagerLoginResultBlock)completion
{
  if (![self validateLoginStartState]) {
    return;
  }

  [self logInFromViewControllerImpl:viewController
                      configuration:configuration
                         completion:completion];
}

- (void)logInFromViewControllerImpl:(UIViewController *)viewController
                      configuration:(FBSDKLoginConfiguration *)configuration
                         completion:(FBSDKLoginManagerLoginResultBlock)completion
{
  if (!configuration) {
    NSString *failureMessage = @"Cannot login without a valid login configuration. Please make sure the `LoginConfiguration` provided is non-nil";
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:failureMessage];
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    NSError *error = [errorFactory errorWithCode:FBSDKErrorInvalidArgument
                                        userInfo:nil
                                         message:failureMessage
                                 underlyingError:nil];

    _handler = [completion copy];
    [self invokeHandler:nil error:error];
    return;
  }

  self.fromViewController = viewController;
  _configuration = configuration;
  _requestedPermissions = configuration.requestedPermissions;

  [self logInWithPermissions:configuration.requestedPermissions handler:completion];
}

- (void)logInWithPermissions:(NSArray<NSString *> *)permissions
          fromViewController:(UIViewController *)viewController
                     handler:(FBSDKLoginManagerLoginResultBlock)handler
{
  FBSDKLoginConfiguration *configuration = [[FBSDKLoginConfiguration alloc] initWithPermissions:permissions
                                                                                       tracking:FBSDKLoginTrackingEnabled];
  [self logInFromViewController:viewController
                  configuration:configuration
                     completion:handler];
}

- (void)reauthorizeDataAccess:(UIViewController *)fromViewController
                      handler:(FBSDKLoginManagerLoginResultBlock)handler
{
  if (![self validateLoginStartState]) {
    return;
  }

  if (![self.accessTokenWallet currentAccessToken]) {
    NSString *errorMessage = @"Must have an access token for which to reauthorize data access";
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    NSError *error = [errorFactory errorWithDomain:FBSDKLoginErrorDomain
                                              code:FBSDKLoginErrorMissingAccessToken
                                          userInfo:nil
                                           message:errorMessage
                                   underlyingError:nil];
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:errorMessage];
    handler(nil, error);
    return;
  }

  FBSDKLoginConfiguration *configuration = [[FBSDKLoginConfiguration alloc] initWithPermissions:@[] // Don't need to pass permissions for data reauthorization.
                                                                                       tracking:FBSDKLoginTrackingEnabled
                                                                                messengerPageId:nil
                                                                                       authType:FBSDKLoginAuthTypeReauthorize];
  [self logInFromViewControllerImpl:fromViewController configuration:configuration completion:handler];
}

- (void)logOut
{
  [self.accessTokenWallet setCurrentAccessToken:nil];
  [self.authenticationToken setCurrentAuthenticationToken:nil];
  [self.profile setCurrentProfile:nil];
}

- (void)logInWithURL:(NSURL *)url
             handler:(nullable FBSDKLoginManagerLoginResultBlock)handler
{
  FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
  _logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:provider.loggingToken
                                                         tracking:FBSDKLoginTrackingEnabled];
  _handler = [handler copy];

  [_logger startSessionForLoginManager:self];
  [_logger startAuthMethod:FBSDKLoginManagerLoggerAuthMethod_Applink];

  NSDictionary<NSString *, NSString *> *loginUrlParameters = [self logInParametersFromURL:url];
  if (loginUrlParameters) {
    id<FBSDKLoginCompleting> completer = [self.loginCompleterFactory createLoginCompleterWithURLParameters:loginUrlParameters
                                                                                                     appID:self.settings.appID
                                                                                authenticationTokenCreator:[FBSDKAuthenticationTokenFactory new]

                                                                                       graphRequestFactory:self.graphRequestFactory
                                                                                           internalUtility:self.internalUtility];
    [completer completeLoginWithHandler:^(FBSDKLoginCompletionParameters *completionParameters) {
      [self completeAuthentication:completionParameters expectChallenge:NO];
    }];
  }
}

#pragma mark - Private

- (void)handleImplicitCancelOfLogIn
{
  FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:nil
                                                                         authenticationToken:nil
                                                                                 isCancelled:YES
                                                                          grantedPermissions:NSSet.set
                                                                         declinedPermissions:NSSet.set];
  [result addLoggingExtra:@YES forKey:@"implicit_cancel"];
  [self invokeHandler:result error:nil];
}

- (BOOL)validateLoginStartState
{
  switch (_state) {
    case FBSDKLoginManagerStateStart: {
      if (self->_usedSFAuthSession) {
        // Using SFAuthenticationSession makes an interestitial dialog that blocks the app, but in certain situations such as
        // screen lock it can be dismissed and have the control returned to the app without invoking the completionHandler.
        // In this case, the viewcontroller has the control back and tried to reinvoke the login. This is acceptable behavior
        // and we should pop up the dialog again
        return YES;
      }

      NSString *errorStr = @"** WARNING: You are trying to start a login while a previous login has not finished yet."
      "This is unsupported behavior. You should wait until the previous login handler gets called to start a new login.";
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             logEntry:errorStr];
      return NO;
    }
    case FBSDKLoginManagerStatePerformingLogin: {
      [self handleImplicitCancelOfLogIn];
      return YES;
    }
    case FBSDKLoginManagerStateIdle:
      _state = FBSDKLoginManagerStateStart;
      return YES;
  }
}

- (BOOL)isPerformingLogin
{
  return _state == FBSDKLoginManagerStatePerformingLogin;
}

- (void)completeAuthentication:(FBSDKLoginCompletionParameters *)parameters expectChallenge:(BOOL)expectChallenge
{
  FBSDKLoginManagerLoginResult *result = nil;

  NSError *error = parameters.error;
  NSString *accessTokenString = parameters.accessTokenString;
  BOOL cancelled = ((accessTokenString == nil) && (parameters.authenticationToken == nil));

  if (expectChallenge && !cancelled && !error) {
    error = [self _verifyChallengeWithCompletionParameters:parameters];
  }
  [self storeExpectedChallenge:nil];

  if (!error) {
    if (!cancelled) {
      result = [self successResultFromParameters:parameters];

      if (result.token && [self.accessTokenWallet currentAccessToken]) {
        [self validateReauthentication:[self.accessTokenWallet currentAccessToken] withResult:result];
        // in a reauth, short circuit and let the login handler be called when the validation finishes.
        return;
      }
    } else {
      result = [self cancelledResultFromParameters:parameters];
    }
  }

  [self _setGlobalPropertiesWithParameters:parameters result:result];

  [self invokeHandler:result error:error];
}

- (void)_setGlobalPropertiesWithParameters:(FBSDKLoginCompletionParameters *)parameters
                                    result:(FBSDKLoginManagerLoginResult *)result
{
  BOOL hasNewAuthenticationToken = (parameters.authenticationToken != nil);
  BOOL hasNewOrUpdatedAccessToken = (result.token != nil);

  if (!hasNewAuthenticationToken && !hasNewOrUpdatedAccessToken) {
    // Assume cancellation. Don't do anything
  } else {
    [self _setSharedAuthenticationToken:parameters.authenticationToken
                            accessToken:result.token
                                profile:parameters.profile];
  }
}

/// Helper for setting global properties
- (void)_setSharedAuthenticationToken:(FBSDKAuthenticationToken *_Nullable)authToken
                          accessToken:(FBSDKAccessToken *_Nullable)accessToken
                              profile:(FBSDKProfile *_Nullable)profile
{
  [self.authenticationToken setCurrentAuthenticationToken:authToken];
  [self.accessTokenWallet setCurrentAccessToken:accessToken];
  [self.profile setCurrentProfile:profile];
}

/// Returns an error if a stored challenge cannot be obtained from the completion parameters
- (nullable NSError *)_verifyChallengeWithCompletionParameters:(FBSDKLoginCompletionParameters *)parameters
{
  NSString *challengeReceived = parameters.challenge;
  NSString *challengeExpected = [[self loadExpectedChallenge] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  if (![challengeExpected isEqualToString:challengeReceived]) {
    return [FBSDKLoginErrorFactory fbErrorForFailedLoginWithCode:FBSDKLoginErrorBadChallengeString];
  } else {
    return nil;
  }
}

- (void)invokeHandler:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{
  [_logger endLoginWithResult:result error:error];
  [_logger endSession];
  [_logger postLoginHeartbeat];
  _logger = nil;
  _state = FBSDKLoginManagerStateIdle;

  if (_handler) {
    FBSDKLoginManagerLoginResultBlock handler = _handler;
    _handler(result, error);
    if (handler == _handler) {
      _handler = nil;
    } else {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             logEntry:@"** WARNING: You are requesting permissions inside the completion block of an existing login."
       "This is unsupported behavior. You should request additional permissions only when they are needed, such as requesting for publish_actions"
       "when the user performs a sharing action."];
    }
  }
}

- (nullable NSDictionary<NSString *, id> *)logInParametersWithConfiguration:(FBSDKLoginConfiguration *)configuration
                                                               loggingToken:(NSString *)loggingToken
                                                                     logger:(FBSDKLoginManagerLogger *)logger
                                                                 authMethod:(NSString *)authMethod
{
  // Making sure configuration is not nil in case this method gets called
  // internally without specifying a cofiguration.
  if (!configuration) {
    NSString *failureMessage = @"Unable to perform login.";
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    NSError *error = [errorFactory errorWithCode:FBSDKErrorUnknown
                                        userInfo:nil
                                         message:failureMessage
                                 underlyingError:nil];
    [self invokeHandler:nil error:error];
    return nil;
  }

  [self.internalUtility validateURLSchemes];

  NSMutableDictionary<NSString *, NSString *> *loginParams = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:loginParams setObject:self.settings.appID forKey:@"client_id"];
  [FBSDKTypeUtility dictionary:loginParams setObject:@"touch" forKey:@"display"];
  [FBSDKTypeUtility dictionary:loginParams setObject:@"ios" forKey:@"sdk"];
  [FBSDKTypeUtility dictionary:loginParams setObject:@"true" forKey:@"return_scopes"];
  loginParams[@"sdk_version"] = FBSDK_VERSION_STRING;
  [FBSDKTypeUtility dictionary:loginParams setObject:@([self.internalUtility isFacebookAppInstalled]).stringValue forKey:@"fbapp_pres"];
  [FBSDKTypeUtility dictionary:loginParams setObject:configuration.authType forKey:@"auth_type"];
  [FBSDKTypeUtility dictionary:loginParams setObject:loggingToken forKey:@"logging_token"];
  long long cbtInMilliseconds = round(1000 * [NSDate date].timeIntervalSince1970);
  [FBSDKTypeUtility dictionary:loginParams setObject:@(cbtInMilliseconds).stringValue forKey:@"cbt"];
  [FBSDKTypeUtility dictionary:loginParams setObject:@(self.settings.isAutoLogAppEventsEnabled).stringValue forKey:@"ies"];
  [FBSDKTypeUtility dictionary:loginParams setObject:self.settings.appURLSchemeSuffix forKey:@"local_client_id"];
  [FBSDKTypeUtility dictionary:loginParams setObject:[FBSDKLoginUtility stringForAudience:self.defaultAudience] forKey:@"default_audience"];

  NSSet<FBSDKPermission *> *permissions = [configuration.requestedPermissions setByAddingObject:[[FBSDKPermission alloc] initWithString:@"openid"]];
  [FBSDKTypeUtility dictionary:loginParams setObject:[permissions.allObjects componentsJoinedByString:@","] forKey:@"scope"];

  if (configuration.messengerPageId) {
    [FBSDKTypeUtility dictionary:loginParams setObject:configuration.messengerPageId forKey:@"messenger_page_id"];
  }

  NSError *error;
  NSURL *redirectURL = [self.internalUtility appURLWithHost:@"authorize" path:@"" queryParameters:@{} error:&error];
  if (!error) {
    [FBSDKTypeUtility dictionary:loginParams
                       setObject:redirectURL.absoluteString
                          forKey:@"redirect_uri"];
  }

  NSString *expectedChallenge = [FBSDKLoginManager stringForChallenge];
  NSDictionary<NSString *, id> *state = @{@"challenge" : [FBSDKUtility URLEncode:expectedChallenge]};
  NSString *clientState = [FBSDKLoginManagerLogger clientStateForAuthMethod:authMethod andExistingState:state logger:logger];
  [FBSDKTypeUtility dictionary:loginParams setObject:clientState forKey:@"state"];
  [self storeExpectedChallenge:expectedChallenge];

  NSString *responseType;
  NSString *tp;

  switch (configuration.tracking) {
    case FBSDKLoginTrackingLimited:
      responseType = @"id_token,graph_domain";
      tp = @"ios_14_do_not_track";
      break;
    case FBSDKLoginTrackingEnabled:
      responseType = @"id_token,token_or_nonce,signed_request,graph_domain";
      [FBSDKTypeUtility dictionary:loginParams setObject:configuration.codeVerifier.challenge forKey:@"code_challenge"];
      [FBSDKTypeUtility dictionary:loginParams setObject:@"S256" forKey:@"code_challenge_method"];
      [self storeExpectedCodeVerifier:configuration.codeVerifier];
      break;
  }

  [FBSDKTypeUtility dictionary:loginParams setObject:responseType forKey:@"response_type"];
  [FBSDKTypeUtility dictionary:loginParams setObject:tp forKey:@"tp"];

  [FBSDKTypeUtility dictionary:loginParams setObject:configuration.nonce forKey:@"nonce"];
  [self storeExpectedNonce:configuration.nonce];

  NSTimeInterval timeValue = (NSTimeInterval)FBSDKMonotonicTimeGetCurrentSeconds();
  NSString *e2eTimestampString = [FBSDKBasicUtility JSONStringForObject:@{ @"init" : @(timeValue) }
                                                                  error:NULL
                                                   invalidObjectHandler:NULL];
  [FBSDKTypeUtility dictionary:loginParams setObject:e2eTimestampString forKey:@"e2e"];

  return loginParams;
}

- (void)logInWithPermissions:(NSSet<FBSDKPermission *> *)permissions handler:(FBSDKLoginManagerLoginResultBlock)handler
{
  if (_configuration) {
    FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
    _logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:provider.loggingToken
                                                           tracking:_configuration.tracking];
  }
  _handler = [handler copy];

  [_logger startSessionForLoginManager:self];

  [self logIn];
}

- (nullable NSDictionary<NSString *, NSString *> *)logInParametersFromURL:(NSURL *)url
{
  NSError *error = nil;
  FBSDKURL *parsedUrl = [FBSDKURL URLWithURL:url];
  NSDictionary<NSString *, id> *extras = parsedUrl.appLinkExtras;

  if (extras) {
    NSString *fbLoginDataString = extras[@"fb_login"];
    NSDictionary<id, id> *fbLoginData = [FBSDKTypeUtility dictionaryValue:[FBSDKBasicUtility objectForJSONString:fbLoginDataString error:&error]];
    if (!error && fbLoginData) {
      return fbLoginData;
    }
  }
  if (!error) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    error = [errorFactory errorWithCode:FBSDKLoginErrorUnknown
                               userInfo:nil
                                message:@"Failed to parse deep link url for login data"
                        underlyingError:nil];
  }

  [self invokeHandler:nil error:error];
  return nil;
}

- (void)logIn
{
  self->_usedSFAuthSession = NO;

  void (^completion)(BOOL, NSError *) = ^void (BOOL didPerformLogIn, NSError *error) {
    if (didPerformLogIn) {
      self->_state = FBSDKLoginManagerStatePerformingLogin;
    } else if ([error.domain isEqualToString:SFVCCanceledLogin]
               || [error.domain isEqualToString:ASCanceledLogin]) {
      [self handleImplicitCancelOfLogIn];
    } else {
      if (!error) {
        error = [NSError errorWithDomain:FBSDKLoginErrorDomain code:FBSDKLoginErrorUnknown userInfo:nil];
      }
      [self invokeHandler:nil error:error];
    }
  };

  [self performBrowserLogInWithHandler:^(BOOL openedURL,
                                         NSError *openedURLError) {
                                           completion(openedURL, openedURLError);
                                         }];
}

+ (NSString *)stringForChallenge
{
  NSString *challenge = fb_randomString(FBClientStateChallengeLength);

  return [challenge stringByReplacingOccurrencesOfString:@"+" withString:@"="];
}

- (void)validateReauthentication:(FBSDKAccessToken *)currentToken
                      withResult:(FBSDKLoginManagerLoginResult *)loginResult
{
  id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:@"me"
                                                                                 parameters:@{@"fields" : @""}
                                                                                tokenString:loginResult.token.tokenString
                                                                                 HTTPMethod:nil
                                                                                      flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  FBSDKGraphRequestCompletion handler = ^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    NSString *actualID = result[@"id"];
    if ([currentToken.userID isEqualToString:actualID]) {
      [self->_accessTokenWallet setCurrentAccessToken:loginResult.token];
      [self invokeHandler:loginResult error:nil];
    } else {
      NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
      [FBSDKTypeUtility dictionary:userInfo setObject:error forKey:NSUnderlyingErrorKey];
      NSError *resultError = [NSError errorWithDomain:FBSDKLoginErrorDomain
                                                 code:FBSDKLoginErrorUserMismatch
                                             userInfo:userInfo];
      [self invokeHandler:nil error:resultError];
    }
  };

  [request startWithCompletion:handler];
}

// change bool to auth method string.
- (void)performBrowserLogInWithHandler:(FBSDKBrowserLoginSuccessBlock)handler
{
  NSString *urlScheme = [NSString stringWithFormat:@"fb%@%@", self.settings.appID, self.settings.appURLSchemeSuffix ?: @""];
  [_logger willAttemptAppSwitchingBehaviorWithUrlScheme:urlScheme];
  FBSDKServerConfigurationProvider *provider = [FBSDKServerConfigurationProvider new];
  BOOL useSafariViewController = [provider useSafariViewControllerForDialogName:@"login"];
  NSString *authMethod = (useSafariViewController ? FBSDKLoginManagerLoggerAuthMethod_SFVC : FBSDKLoginManagerLoggerAuthMethod_Browser);

  NSDictionary<NSString *, NSString *> *loginParams = [self logInParametersWithConfiguration:_configuration
                                                                                loggingToken:provider.loggingToken
                                                                                      logger:_logger
                                                                                  authMethod:authMethod];
  NSError *error;
  NSURL *authURL = nil;
  if (loginParams[@"redirect_uri"]) {
    authURL = [self.internalUtility facebookURLWithHostPrefix:@"m."
                                                         path:FBSDKOauthPath
                                              queryParameters:loginParams
                                                        error:&error];
  }

  [_logger startAuthMethod:authMethod];

  if (authURL) {
    void (^handlerWrapper)(BOOL, NSError *) = ^(BOOL didOpen, NSError *anError) {
      if (handler) {
        handler(didOpen, anError);
      }
    };

    if (useSafariViewController) {
      // Note based on above, authURL must be a http scheme. If that changes, add a guard, otherwise SFVC can throw
      self->_usedSFAuthSession = YES;
      [self.urlOpener openURLWithSafariViewController:authURL
                                               sender:self
                                   fromViewController:self.fromViewController
                                              handler:handlerWrapper];
    } else {
      [self.urlOpener openURL:authURL sender:self handler:handlerWrapper];
    }
  } else {
    if (!error) {
      id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
      error = [errorFactory errorWithCode:FBSDKLoginErrorUnknown
                                 userInfo:nil
                                  message:@"Failed to construct oauth browser url"
                          underlyingError:nil];
    }
    if (handler) {
      handler(NO, error);
    }
  }
}

- (FBSDKLoginManagerLoginResult *)cancelledResultFromParameters:(FBSDKLoginCompletionParameters *)parameters
{
  NSSet<NSString *> *declinedPermissions = [NSSet set];
  if ([self.accessTokenWallet currentAccessToken] != nil) {
    // Always include the list of declined permissions from this login request
    // if an access token is already cached by the SDK
    declinedPermissions = [FBSDKPermission rawPermissionsFromPermissions:parameters.declinedPermissions];
  }

  return [[FBSDKLoginManagerLoginResult alloc] initWithToken:nil
                                         authenticationToken:nil
                                                 isCancelled:YES
                                          grantedPermissions:[NSSet set]
                                         declinedPermissions:declinedPermissions];
}

- (FBSDKLoginManagerLoginResult *)successResultFromParameters:(FBSDKLoginCompletionParameters *)parameters
{
  NSSet<FBSDKPermission *> *grantedPermissions = parameters.permissions;
  NSSet<FBSDKPermission *> *declinedPermissions = parameters.declinedPermissions;

  // Recent permissions are largely based on the existence of an access token
  // without an access token the 'recent' permissions will match the
  // intersect of the granted permissions and the requested permissions.
  // This is important because we want to create a 'result' that accurately reflects
  // the currently granted permissions even when there is no access token.
  NSSet<FBSDKPermission *> *recentlyGrantedPermissions = [self recentlyGrantedPermissionsFromGrantedPermissions:grantedPermissions];
  NSSet<FBSDKPermission *> *recentlyDeclinedPermissions = [self recentlyDeclinedPermissionsFromDeclinedPermissions:declinedPermissions];

  if (recentlyGrantedPermissions.count > 0) {
    NSSet<NSString *> *rawGrantedPermissions = [FBSDKPermission rawPermissionsFromPermissions:grantedPermissions];
    NSSet<NSString *> *rawDeclinedPermissions = [FBSDKPermission rawPermissionsFromPermissions:declinedPermissions];
    NSSet<NSString *> *rawRecentlyGrantedPermissions = [FBSDKPermission rawPermissionsFromPermissions:recentlyGrantedPermissions];
    NSSet<NSString *> *rawRecentlyDeclinedPermissions = [FBSDKPermission rawPermissionsFromPermissions:recentlyDeclinedPermissions];

    FBSDKAccessToken *token;
    if (parameters.accessTokenString) {
      token = [[FBSDKAccessToken alloc] initWithTokenString:parameters.accessTokenString
                                                permissions:rawGrantedPermissions.allObjects
                                        declinedPermissions:rawDeclinedPermissions.allObjects
                                         expiredPermissions:@[]
                                                      appID:parameters.appID
                                                     userID:parameters.userID
                                             expirationDate:parameters.expirationDate
                                                refreshDate:[NSDate date]
                                   dataAccessExpirationDate:parameters.dataAccessExpirationDate];
    }

    return [[FBSDKLoginManagerLoginResult alloc] initWithToken:token
                                           authenticationToken:parameters.authenticationToken
                                                   isCancelled:NO
                                            grantedPermissions:rawRecentlyGrantedPermissions
                                           declinedPermissions:rawRecentlyDeclinedPermissions];
  } else {
    return [self cancelledResultFromParameters:parameters];
  }
}

#pragma mark - Permissions Helpers

- (NSSet<FBSDKPermission *> *)recentlyGrantedPermissionsFromGrantedPermissions:(NSSet<FBSDKPermission *> *)grantedPermissions
{
  NSMutableSet<FBSDKPermission *> *recentlyGrantedPermissions = grantedPermissions.mutableCopy;
  NSSet<NSString *> *previouslyGrantedPermissions = [[self.accessTokenWallet currentAccessToken] permissions];

  // If there were no requested permissions for this auth, or no previously granted permissions - treat all permissions as recently granted.
  // Otherwise this is a reauth, so recentlyGranted should be a subset of what was requested.
  if (previouslyGrantedPermissions.count > 0 && _requestedPermissions.count != 0) {
    [recentlyGrantedPermissions intersectSet:_requestedPermissions];
  }

  return recentlyGrantedPermissions;
}

- (NSSet<FBSDKPermission *> *)recentlyDeclinedPermissionsFromDeclinedPermissions:(NSSet<FBSDKPermission *> *)declinedPermissions
{
  NSMutableSet<FBSDKPermission *> *recentlyDeclinedPermissions = _requestedPermissions.mutableCopy;
  [recentlyDeclinedPermissions intersectSet:declinedPermissions];
  return recentlyDeclinedPermissions;
}

#pragma mark - Keychain Storage

- (void)storeExpectedChallenge:(NSString *)challengeExpected
{
  [self.keychainStore setString:challengeExpected
                         forKey:FBSDKExpectedChallengeKey
                  accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

- (nullable NSString *)loadExpectedChallenge
{
  return [self.keychainStore stringForKey:FBSDKExpectedChallengeKey];
}

- (void)storeExpectedNonce:(NSString *)nonceExpected
{
  [self.keychainStore setString:nonceExpected
                         forKey:FBSDKExpectedNonceKey
                  accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

- (nullable NSString *)loadExpectedNonce
{
  return [self.keychainStore stringForKey:FBSDKExpectedNonceKey];
}

- (void)storeExpectedCodeVerifier:(FBSDKCodeVerifier *)codeVerifier
{
  [self.keychainStore setString:codeVerifier.value
                         forKey:FBSDKExpectedCodeVerifierKey
                  accessibility:[FBSDKDynamicFrameworkLoaderProxy loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

- (nullable NSString *)loadExpectedCodeVerifier
{
  return [self.keychainStore stringForKey:FBSDKExpectedCodeVerifierKey];
}

#pragma mark - Test Methods

- (void)setHandler:(FBSDKLoginManagerLoginResultBlock)handler
{
  _handler = [handler copy];
}

- (void)setRequestedPermissions:(NSSet<NSString *> *)requestedPermissions
{
  _requestedPermissions = [FBSDKPermission permissionsFromRawPermissions:requestedPermissions];
}

- (FBSDKLoginConfiguration *)configuration
{
  return _configuration;
}

#pragma mark - FBSDKURLOpening
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  BOOL isFacebookURL = [self canOpenURL:url forApplication:application sourceApplication:sourceApplication annotation:annotation];

  if (!isFacebookURL && [self isPerformingLogin]) {
    [self handleImplicitCancelOfLogIn];
  }

  if (isFacebookURL) {
    NSDictionary<NSString *, id> *urlParameters = [FBSDKLoginUtility queryParamsFromLoginURL:url] ?: @{};
    id<FBSDKLoginCompleting> completer = [self.loginCompleterFactory createLoginCompleterWithURLParameters:urlParameters
                                                                                                     appID:self.settings.appID
                                                                                authenticationTokenCreator:[FBSDKAuthenticationTokenFactory new]

                                                                                       graphRequestFactory:self.graphRequestFactory
                                                                                           internalUtility:self.internalUtility];

    // any necessary strong reference is maintained by the FBSDKLoginURLCompleter handler
    [completer completeLoginWithHandler:^(FBSDKLoginCompletionParameters *parameters) {
                 if ((self->_configuration) && (self->_logger == nil)) {
                   self->_logger = [[FBSDKLoginManagerLogger alloc] initWithParameters:urlParameters
                                                                              tracking:self->_configuration.tracking];
                 }
                 [self completeAuthentication:parameters expectChallenge:YES];
               }
                                  nonce:[self loadExpectedNonce]
                           codeVerifier:[self loadExpectedCodeVerifier]];
    [self storeExpectedNonce:nil];
    [self storeExpectedCodeVerifier:nil];
  }

  return isFacebookURL;
}

- (BOOL) canOpenURL:(NSURL *)url
     forApplication:(nullable UIApplication *)application
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation
{
  // verify the URL is intended as a callback for the SDK's log in
  return [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", self.settings.appID]]
  && [url.host isEqualToString:@"authorize"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if ([self isPerformingLogin]) {
    [self handleImplicitCancelOfLogIn];
  }
}

- (BOOL)isAuthenticationURL:(NSURL *)url
{
  return [url.path hasSuffix:FBSDKOauthPath];
}

- (BOOL)shouldStopPropagationOfURL:(NSURL *)url
{
  return
  [url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", self.settings.appID]]
  && [url.host isEqualToString:@"no-op"];
}

@end

#endif
