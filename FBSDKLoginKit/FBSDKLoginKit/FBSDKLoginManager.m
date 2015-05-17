// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKLoginManager+Internal.h"

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKSettings.h>

#import "_FBSDKLoginRecoveryAttempter.h"
#import "FBSDKCoreKit+Internal.h"
#import "FBSDKLoginCompletion.h"
#import "FBSDKLoginConstants.h"
#import "FBSDKLoginError.h"
#import "FBSDKLoginManagerLogger.h"
#import "FBSDKLoginManagerLoginResult.h"
#import "FBSDKLoginUtility.h"

@implementation FBSDKLoginManager
{
  FBSDKLoginManagerRequestTokenHandler _handler;
  NSSet *_requestedPermissions;
  FBSDKLoginManagerLogger *_logger;
  // YES if we're calling out to the Facebook app or Safari to perform a log in
  BOOL _performingLogIn;
}

+ (void)initialize
{
  if (self == [FBSDKLoginManager class]) {
    [_FBSDKLoginRecoveryAttempter class];
  }
}

- (void)logInWithReadPermissions:(NSArray *)permissions handler:(FBSDKLoginManagerRequestTokenHandler)handler
{
  [self assertPermissions:permissions];
  NSSet *permissionSet = [NSSet setWithArray:permissions];
  if (![FBSDKLoginUtility areAllPermissionsReadPermissions:permissionSet]) {
    [[NSException exceptionWithName:NSInvalidArgumentException
                             reason:@"Publish or manage permissions are not permitted to be requested with read permissions."
                           userInfo:nil]
     raise];
  }
  [self logInWithPermissions:permissionSet handler:handler];
}

- (void)logInWithPublishPermissions:(NSArray *)permissions handler:(FBSDKLoginManagerRequestTokenHandler)handler
{
  [self assertPermissions:permissions];
  NSSet *permissionSet = [NSSet setWithArray:permissions];
  if (![FBSDKLoginUtility areAllPermissionsPublishPermissions:permissionSet]) {
    [[NSException exceptionWithName:NSInvalidArgumentException
                             reason:@"Read permissions are not permitted to be requested with publish or manage permissions."
                           userInfo:nil]
     raise];
  }
  [self logInWithPermissions:permissionSet handler:handler];
}

- (void)logOut
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  [FBSDKProfile setCurrentProfile:nil];
}

+ (void)renewSystemCredentials:(void (^)(ACAccountCredentialRenewResult result, NSError *error))handler
{
  FBSDKSystemAccountStoreAdapter *adapter = [FBSDKSystemAccountStoreAdapter sharedInstance];

  if (!adapter.accountType) {
    handler(ACAccountCredentialRenewResultFailed, [FBSDKLoginError errorForFailedLoginWithCode:FBSDKLoginSystemAccountUnavailableErrorCode]);
  } else if (!adapter.accountType.accessGranted) {
    handler(ACAccountCredentialRenewResultFailed, [FBSDKLoginError errorForFailedLoginWithCode:FBSDKLoginSystemAccountAppDisabledErrorCode]);
  } else {
    [[FBSDKSystemAccountStoreAdapter sharedInstance] renewSystemAuthorization:handler];
  }
}

#pragma mark - Private

- (void)assertPermissions:(NSArray *)permissions
{
  for (NSString *permission in permissions) {
    if (![permission isKindOfClass:[NSString class]]) {
      [[NSException exceptionWithName:NSInvalidArgumentException
                               reason:@"Permissions must be string values."
                             userInfo:nil]
       raise];
    }
    if ([permission rangeOfString:@","].location != NSNotFound) {
      [[NSException exceptionWithName:NSInvalidArgumentException
                               reason:@"Permissions should each be specified in separate string values in the array."
                             userInfo:nil]
       raise];
    }
  }
}

- (void)completeAuthentication:(FBSDKLoginCompletionParameters *)parameters
{
  FBSDKLoginManagerLoginResult *result = nil;
  NSError *error = parameters.error;

  if (!error) {
    NSString *tokenString = parameters.accessTokenString;
    BOOL cancelled = (tokenString == nil);

    if (!cancelled) {
      NSSet *grantedPermissions = parameters.permissions;
      NSSet *declinedPermissions = parameters.declinedPermissions;

      NSSet *recentlyGrantedPermissions = nil;
      NSSet *recentlyDeclinedPermissions = nil;

      [self determineRecentlyGrantedPermissions:&recentlyGrantedPermissions
                    recentlyDeclinedPermissions:&recentlyDeclinedPermissions
                           forGrantedPermission:grantedPermissions
                            declinedPermissions:declinedPermissions];

      if (recentlyGrantedPermissions.count > 0) {
        FBSDKAccessToken *token = [[FBSDKAccessToken alloc] initWithTokenString:tokenString
                                                                    permissions:[grantedPermissions allObjects]
                                                            declinedPermissions:[declinedPermissions allObjects]
                                                                          appID:parameters.appID
                                                                         userID:parameters.userID
                                                                 expirationDate:parameters.expirationDate
                                                                    refreshDate:[NSDate date]];
        result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:token
                                                         isCancelled:NO
                                                  grantedPermissions:recentlyGrantedPermissions
                                                 declinedPermissions:recentlyDeclinedPermissions];

        if ([FBSDKAccessToken currentAccessToken]) {
          [self validateReauthentication:[FBSDKAccessToken currentAccessToken] withResult:result];
          // in a reauth, short circuit and let the login handler be called when the validation finishes.
          return;
        }
      } else {
        cancelled = YES;
      }
    }

    if (cancelled) {
      NSSet *declinedPermissions = nil;

      // If a System Account reauthorization was cancelled by the user tapping Don't Allow
      // then add the declined permissions to the login result. The Accounts framework
      // doesn't register the decline with Facebook, which is why we don't update the
      // access token.
      if ([FBSDKAccessToken currentAccessToken] != nil && parameters.isSystemAccount) {
        declinedPermissions = parameters.declinedPermissions;
      }

      result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:nil
                                                       isCancelled:YES
                                                grantedPermissions:nil
                                               declinedPermissions:declinedPermissions];
    }
  }

  if (result.token) {
    [FBSDKAccessToken setCurrentAccessToken:result.token];
  }

  [self invokeHandler:result error:error];
}

- (void)determineRecentlyGrantedPermissions:(NSSet **)recentlyGrantedPermissionsRef
                recentlyDeclinedPermissions:(NSSet **)recentlyDeclinedPermissionsRef
                       forGrantedPermission:(NSSet *)grantedPermissions
                        declinedPermissions:(NSSet *)declinedPermissions
{
  NSMutableSet *recentlyGrantedPermissions = [grantedPermissions mutableCopy];
  NSSet *previouslyGrantedPermissions = ([FBSDKAccessToken currentAccessToken] ?
                                         [FBSDKAccessToken currentAccessToken].permissions :
                                         nil);
  if (previouslyGrantedPermissions.count > 0) {
    // this is a reauth, so recentlyGranted should be a subset of what was requested.
    [recentlyGrantedPermissions intersectSet:_requestedPermissions];
  }

  NSMutableSet *recentlyDeclinedPermissions = [_requestedPermissions mutableCopy];
  [recentlyDeclinedPermissions intersectSet:declinedPermissions];

  if (recentlyGrantedPermissionsRef != NULL) {
    *recentlyGrantedPermissionsRef = [recentlyGrantedPermissions copy];
  }
  if (recentlyDeclinedPermissionsRef != NULL) {
    *recentlyDeclinedPermissionsRef = [recentlyDeclinedPermissions copy];
  }
}

- (void)invokeHandler:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error
{
  FBSDKLoginManagerLoggerResult authorizationResult = FBSDKLoginManagerLoggerResultSuccess;
  if (error != nil) {
    authorizationResult = FBSDKLoginManagerLoggerResultError;
  } else if (result == nil || result.isCancelled) {
    authorizationResult = FBSDKLoginManagerLoggerResultCancel;
  }

  [_logger endLoginWithResult:authorizationResult error:error];
  [_logger endEvent];

  if (_handler) {
    _handler(result, error);
  }
  _logger = nil;
  _handler = nil;
}

- (NSDictionary *)logInParametersWithPermissions:(NSSet *)permissions
{
  [FBSDKInternalUtility validateURLSchemes];

  NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
  loginParams[@"client_id"] = [FBSDKSettings appID];
  loginParams[@"response_type"] = @"token,signed_request";
  loginParams[@"redirect_uri"] = @"fbconnect://success";
  loginParams[@"display"] = @"touch";
  loginParams[@"sdk"] = @"ios";
  loginParams[@"return_scopes"] = @"true";
  loginParams[@"sdk_version"] = FBSDK_VERSION_STRING;
  if ([FBSDKAccessToken currentAccessToken]) {
    loginParams[@"auth_type"] = @"rerequest";
  }
  [FBSDKInternalUtility dictionary:loginParams setObject:[FBSDKSettings appURLSchemeSuffix] forKey:@"local_client_id"];
  [FBSDKInternalUtility dictionary:loginParams setObject:[FBSDKLoginUtility stringForAudience:self.defaultAudience] forKey:@"default_audience"];
  [FBSDKInternalUtility dictionary:loginParams setObject:[[permissions allObjects] componentsJoinedByString:@","] forKey:@"scope"];
  return loginParams;
}

- (void)logInWithPermissions:(NSSet *)permissions handler:(FBSDKLoginManagerRequestTokenHandler)handler
{
  _logger = [[FBSDKLoginManagerLogger alloc] init];

  _handler = [handler copy];
  _requestedPermissions = permissions;

  [_logger startEventWithBehavior:self.loginBehavior isReauthorize:([FBSDKAccessToken currentAccessToken] != nil)];

  [self logInWithBehavior:self.loginBehavior];
}

- (void)logInWithBehavior:(FBSDKLoginBehavior)loginBehavior
{
  NSDictionary *loginParams = [self logInParametersWithPermissions:_requestedPermissions];

  NSError *error = nil;
  FBSDKLoginBehavior loginBehaviorUsed = loginBehavior;
  BOOL didPerformLogIn = NO;

  switch (loginBehavior) {
    case FBSDKLoginBehaviorNative:
      didPerformLogIn = [self performNativeLogInWithParameters:loginParams error:&error];
      if (didPerformLogIn) {
        break;
      }
      // else fall through
      loginBehaviorUsed = FBSDKLoginBehaviorBrowser;

    case FBSDKLoginBehaviorBrowser:
      if (error) {
        [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           formatString:@"FBSDKLoginBehaviorNative failed : %@\nTrying FBSDKLoginBehaviorBrowser", error];
      }
      didPerformLogIn = [self performBrowserLogInWithParameters:loginParams error:&error];
      break;

    case FBSDKLoginBehaviorSystemAccount: {
      didPerformLogIn = YES; // log in will continue asynchronously but will proceed (or fail later)

      [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *serverConfiguration, NSError *loadError) {
        if (serverConfiguration.isSystemAuthenticationEnabled && error == nil) {
          [self beginSystemLogIn];
        } else {
          [self logInWithBehavior:FBSDKLoginBehaviorNative];
        }
      }];
      break;
    }

    case FBSDKLoginBehaviorWeb:
      didPerformLogIn = [self performWebLogInWithParameters:loginParams];
      break;
  }

  if (didPerformLogIn) {
    [_logger startLoginWithBehavior:loginBehaviorUsed];
  } else {
    if (!error) {
      error = [NSError errorWithDomain:FBSDKLoginErrorDomain code:FBSDKLoginUnknownErrorCode userInfo:nil];
    }
    [self invokeHandler:nil error:error];
  }
}

- (void)validateReauthentication:(FBSDKAccessToken *)currentToken withResult:(FBSDKLoginManagerLoginResult *)loginResult
{
  FBSDKGraphRequest *requestMe = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:nil
                                                                  tokenString:loginResult.token.tokenString
                                                                   HTTPMethod:nil
                                                                        flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  [requestMe startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    NSString *actualID = result[@"id"];
    if ([currentToken.userID isEqualToString:actualID]) {
      [FBSDKAccessToken setCurrentAccessToken:loginResult.token];
      [self invokeHandler:loginResult error:nil];
    } else {
      NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
      [FBSDKInternalUtility dictionary:userInfo setObject:error forKey:NSUnderlyingErrorKey];
      NSError *resultError = [NSError errorWithDomain:FBSDKLoginErrorDomain
                                                 code:FBSDKLoginUserMismatchErrorCode
                                             userInfo:userInfo];
       [self invokeHandler:nil error:resultError];
    }
  }];
}

#pragma mark - Test Methods

- (void)setHandler:(FBSDKLoginManagerRequestTokenHandler)handler
{
  _handler = [handler copy];
}

- (void)setRequestedPermissions:(NSSet *)requestedPermissions
{
  _requestedPermissions = [requestedPermissions copy];
}

@end

#pragma mark -

@implementation FBSDKLoginManager (Native)

- (BOOL)performNativeLogInWithParameters:(NSDictionary *)loginParams error:(NSError **)error
{
  [_logger willAttemptAppSwitchingBehavior];
  loginParams = [_logger parametersWithTimeStampAndClientState:loginParams forLoginBehavior:FBSDKLoginBehaviorNative];

  NSString *scheme = ([FBSDKSettings appURLSchemeSuffix] ? @"fbauth2" : @"fbauth");
  NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:loginParams];
  mutableParams[@"legacy_override"] = FBSDK_TARGET_PLATFORM_VERSION;
  NSURL *authURL = [FBSDKInternalUtility URLWithScheme:scheme host:@"authorize" path:@"" queryParameters:mutableParams error:error];

  // if native log in is possible, a strong reference will be maintained by FBSDKApplicationDelegate during the the asynchronous operation
  return !*error && [self tryOpenURL:authURL];
}

- (BOOL)performBrowserLogInWithParameters:(NSDictionary *)loginParams error:(NSError **)error
{
  [_logger willAttemptAppSwitchingBehavior];
  loginParams = [_logger parametersWithTimeStampAndClientState:loginParams forLoginBehavior:FBSDKLoginBehaviorBrowser];

  NSURL *authURL = nil;
  NSURL *redirectURL = [FBSDKInternalUtility appURLWithHost:@"authorize" path:nil queryParameters:nil error:error];
  if (!*error) {
    NSMutableDictionary *browserParams = [loginParams mutableCopy];
    [FBSDKInternalUtility dictionary:browserParams
                           setObject:redirectURL
                              forKey:@"redirect_uri"];
    authURL = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m."
                                                         path:@"/dialog/oauth"
                                              queryParameters:browserParams
                                                        error:error];
  }

  // if browser log in is possible, a strong reference will be maintained by FBSDKApplicationDelegate during the the asynchronous operation
  return !*error && [self tryOpenURL:authURL];
}

- (BOOL)tryOpenURL:(NSURL *)url
{
  // FBSDKApplicationDelegate will maintain a strong reference and call -application:openURL:sourceApplication:annotation: below
  if ([[FBSDKApplicationDelegate sharedInstance] openURL:url sender:self]) {
    _performingLogIn = YES;
    return YES;
  }
  return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  // verify the URL is intended as a callback for the SDK's log in
  BOOL isFacebookURL = [[url scheme] hasPrefix:[NSString stringWithFormat:@"fb%@", [FBSDKSettings appID]]] &&
    [[url host] isEqualToString:@"authorize"];

  BOOL isExpectedSourceApplication = [sourceApplication hasPrefix:@"com.facebook"] || [sourceApplication hasPrefix:@"com.apple"];

  if (!isFacebookURL && _performingLogIn) {
    [self handleImplicitCancelOfLogIn];
  }
  _performingLogIn = NO;

  if (isFacebookURL && isExpectedSourceApplication) {
    NSDictionary *urlParameters = [FBSDKLoginUtility queryParamsFromLoginURL:url];
    id<FBSDKLoginCompleting> completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:urlParameters appID:[FBSDKSettings appID]];

    if (_logger == nil) {
      _logger = [FBSDKLoginManagerLogger loggerFromParameters:urlParameters];
    }

    // any necessary strong reference is maintained by the FBSDKLoginURLCompleter handler
    [completer completeLogIn:self withHandler:^(FBSDKLoginCompletionParameters *parameters) {
      [self completeAuthentication:parameters];
    }];
  }

  return isFacebookURL;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if (_performingLogIn) {
    _performingLogIn = NO;
    [self handleImplicitCancelOfLogIn];
  }
}

- (void)handleImplicitCancelOfLogIn {
  FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:nil
                                                                                 isCancelled:YES
                                                                          grantedPermissions:nil
                                                                         declinedPermissions:nil];
  [self invokeHandler:result error:nil];
}

@end

@implementation FBSDKLoginManager (Accounts)

- (void)beginSystemLogIn
{
  // First, we need to validate the current access token. The user may have uninstalled the
  // app, changed their password, etc., or the acceess token may have expired, which
  // requires us to renew the account before asking for additional permissions.
  NSString *accessTokenString = [FBSDKSystemAccountStoreAdapter sharedInstance].accessTokenString;
  if (accessTokenString.length > 0) {
    FBSDKGraphRequest *meRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                     parameters:@{ @"fields" : @"id" }
                                                                    tokenString:accessTokenString
                                                                     HTTPMethod:nil
                                                                          flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
    [meRequest startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
      if (!error) {
        // If there was no error, make an explicit renewal call anyway to cover cases where user has revoked some read permission like email.
        // Otherwise, iOS system account may continue to think email was granted and never prompt UI again.
        [[FBSDKSystemAccountStoreAdapter sharedInstance] renewSystemAuthorization:^(ACAccountCredentialRenewResult renewResult, NSError *renewError) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self performSystemLogIn];
          });
        }];
      } else {
        // If there was an error, FBSDKGraphRequestConnection would have already done work already (like renewal calls)
        [self performSystemLogIn];
      }
    }];
  } else {
    [self performSystemLogIn];
  }
}

- (void)performSystemLogIn
{
  if (![FBSDKSystemAccountStoreAdapter sharedInstance].accountType) {
    // There is no Facebook system account type. Fallback to Native behavior
    [self fallbackToNativeBehavior];
    return;
  }

  // app may be asking for nothing, but we will always have a set here
  NSMutableSet *permissionsToUse = _requestedPermissions ? [_requestedPermissions mutableCopy] : [NSMutableSet set];
  // Ensure that basic info is among the permissions requested so that the app will install if necessary.
  // "email" is used as a proxy for basic_info permission.
  [permissionsToUse addObject:@"email"];

  [permissionsToUse removeObject:@"public_profile"];
  [permissionsToUse removeObject:@"user_friends"];

  NSString *audience;
  switch (self.defaultAudience) {
    case FBSDKDefaultAudienceOnlyMe:
      audience = fbsdkdfl_ACFacebookAudienceOnlyMe();
      break;
    case FBSDKDefaultAudienceFriends:
      audience = fbsdkdfl_ACFacebookAudienceFriends();
      break;
    case FBSDKDefaultAudienceEveryone:
      audience = fbsdkdfl_ACFacebookAudienceEveryone();
      break;
    default:
      audience = nil;
  }

  unsigned long timePriorToSystemAuthUI = [FBSDKInternalUtility currentTimeInMilliseconds];
  BOOL isReauthorize = [FBSDKAccessToken currentAccessToken] != nil;

  // the FBSDKSystemAccountStoreAdapter completion handler maintains the strong reference during the the asynchronous operation
  [[FBSDKSystemAccountStoreAdapter sharedInstance]
   requestAccessToFacebookAccountStore:permissionsToUse
   defaultAudience:audience
   isReauthorize:isReauthorize
   appID:[FBSDKSettings appID]
   handler:^(NSString *oauthToken, NSError *accountStoreError) {

     // There doesn't appear to be a reliable way to determine whether UI was shown or
     // whether the cached token was sufficient. So we use a timer heuristic assuming that
     // human response time couldn't complete a dialog in under the interval given here, but
     // the process will return here fast enough if the token is cached. The threshold was
     // chosen empirically, so there may be some edge cases that are false negatives or
     // false positives.
     BOOL didShowDialog = [FBSDKInternalUtility currentTimeInMilliseconds] - timePriorToSystemAuthUI > 350;
     BOOL isUnTOSedDevice = !oauthToken && accountStoreError.code == ACErrorAccountNotFound;
     [_logger systemAuthDidShowDialog:didShowDialog isUnTOSedDevice:isUnTOSedDevice];

     if (accountStoreError && [FBSDKSystemAccountStoreAdapter sharedInstance].forceBlockingRenew) {
       accountStoreError = [FBSDKLoginError errorForSystemPasswordChange:accountStoreError];
     }
     if (!oauthToken && !accountStoreError) {
       // This means iOS did not give an error nor granted, even after a renew. In order to
       // surface this to users, stuff in our own error that can be inspected.
       accountStoreError = [FBSDKLoginError errorForFailedLoginWithCode:FBSDKLoginSystemAccountAppDisabledErrorCode];
     }

     FBSDKLoginManagerSystemAccountState *state = [[FBSDKLoginManagerSystemAccountState alloc] init];
     state.didShowDialog = didShowDialog;
     state.reauthorize = isReauthorize;
     state.unTOSedDevice = isUnTOSedDevice;

     [self continueSystemLogInWithTokenString:oauthToken error:accountStoreError state:state];
   }];
}

- (void)continueSystemLogInWithTokenString:(NSString *)oauthToken error:(NSError *)accountStoreError state:(FBSDKLoginManagerSystemAccountState *)state
{
  id<FBSDKLoginCompleting> completer = nil;

  if (!oauthToken && accountStoreError.code == ACErrorAccountNotFound) {
    // Even with the Accounts framework we use the Facebook app or Safari to log in if
    // the user has not signed in. This condition can only be detected by attempting to
    // log in because the framework does not otherwise indicate whether a Facebook account
    // exists on the device unless the user has granted the app permissions.

    // Do this asynchronously so the logger correctly notes the system account was skipped
    dispatch_async(dispatch_get_main_queue(), ^{
      [self fallbackToNativeBehavior];
    });
  } else if (oauthToken) {
    completer = [[FBSDKLoginSystemAccountCompleter alloc] initWithTokenString:oauthToken appID:[FBSDKSettings appID]];
  } else {
    completer = [[FBSDKLoginSystemAccountErrorCompleter alloc] initWithError:accountStoreError permissions:_requestedPermissions];
  }

  // any necessary strong reference is maintained by the FBSDKLoginSystemAccount[Error]Completer handler
  [completer completeLogIn:self withHandler:^(FBSDKLoginCompletionParameters *parameters) {
    NSString *eventName = nil;

    if (state.isReauthorize) {
      BOOL cancelled = parameters.accessTokenString == nil && parameters.error == nil;
      if (state.didShowDialog) {
        eventName = @"Reauthorization succeeded";
      } else if (cancelled) {
        eventName = @"Reauthorization cancelled";
      }
    } else {
      if (state.didShowDialog) {
        eventName = @"Authorization succeeded";
      } else if (!state.isUnTOSedDevice) {
        eventName = @"Authorization cancelled";
      }
    }

    [self completeAuthentication:parameters];

    if (eventName != nil) {
      NSString *sortedPermissions = (_requestedPermissions.count == 0)
        ? @"<NoPermissionsSpecified>"
        : [[_requestedPermissions.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] componentsJoinedByString:@","];

        [FBSDKAppEvents logImplicitEvent:FBSDKAppEventNamePermissionsUILaunch
                              valueToSum:nil
                              parameters:@{ @"ui_dialog_type" : @"iOS integrated auth",
                                            @"permissions_requested" : sortedPermissions }
                             accessToken:nil];

        [FBSDKAppEvents logImplicitEvent:FBSDKAppEventNamePermissionsUIDismiss
                              valueToSum:nil
                              parameters:@{ @"ui_dialog_type" : @"iOS integrated auth",
                                         FBSDKAppEventParameterDialogOutcome : eventName,
                                         @"permissions_requested" : sortedPermissions }
                             accessToken:nil];
    }
  }];
}

- (void)fallbackToNativeBehavior
{
  [_logger endLoginWithResult:FBSDKLoginManagerLoggerResultSkipped error:nil];
  // any necessary strong reference will be maintained by the mechanism that is used
  [self logInWithBehavior:FBSDKLoginBehaviorNative];
}

@end

@implementation FBSDKLoginManager (WebDialog)

- (BOOL)performWebLogInWithParameters:(NSDictionary *)loginParams
{
  [FBSDKInternalUtility registerTransientObject:self];
  [FBSDKInternalUtility deleteFacebookCookies];
  NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:loginParams];
  parameters[@"title"] = NSLocalizedStringWithDefaultValue(@"LoginWeb.LogInTitle",
                                                           @"FacebookSDK",
                                                           [NSBundle mainBundle],
                                                           @"Log In",
                                                           @"Title of the web dialog that prompts the user to log in to Facebook.");
  [FBSDKWebDialog showWithName:@"oauth" parameters:loginParams delegate:self];

  return YES;
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didCompleteWithResults:(NSDictionary *)results
{
  NSString *token = results[@"access_token"];

  if (token.length == 0) {
    [self webDialogDidCancel:webDialog];
  } else {
    id<FBSDKLoginCompleting> completer = [[FBSDKLoginURLCompleter alloc] initWithURLParameters:results appID:[FBSDKSettings appID]];
    [completer completeLogIn:self withHandler:^(FBSDKLoginCompletionParameters *parameters) {
      [self completeAuthentication:parameters];
    }];
  }
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)webDialog:(FBSDKWebDialog *)webDialog didFailWithError:(NSError *)error
{
  FBSDKLoginCompletionParameters *parameters = [[FBSDKLoginCompletionParameters alloc] initWithError:error];
  [self completeAuthentication:parameters];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

- (void)webDialogDidCancel:(FBSDKWebDialog *)webDialog
{
  FBSDKLoginCompletionParameters *parameters = [[FBSDKLoginCompletionParameters alloc] init];
  [self completeAuthentication:parameters];
  [FBSDKInternalUtility unregisterTransientObject:self];
}

@end

@implementation FBSDKLoginManagerSystemAccountState
@end
