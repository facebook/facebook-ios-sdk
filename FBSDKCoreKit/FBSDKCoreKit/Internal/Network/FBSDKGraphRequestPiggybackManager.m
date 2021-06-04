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

#import "FBSDKGraphRequestPiggybackManager.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKGraphRequestConnecting+Internal.h"
#import "FBSDKServerConfigurationLoading.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSettings+SettingsLogging.h"
#import "FBSDKSettings+SettingsProtocols.h"

static int const FBSDKTokenRefreshThresholdSeconds = 24 * 60 * 60; // day
static int const FBSDKTokenRefreshRetrySeconds = 60 * 60; // hour

@implementation FBSDKGraphRequestPiggybackManager

static NSDate *_lastRefreshTry = nil;
static Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> _tokenWallet = nil;
static id<FBSDKSettings> _settings;
static Class<FBSDKServerConfigurationProviding, FBSDKServerConfigurationLoading> _serverConfiguration;
static id<FBSDKGraphRequestProviding> _requestProvider;

+ (Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
{
  return _tokenWallet;
}

+ (id<FBSDKSettings>)settings
{
  return _settings;
}

+ (Class<FBSDKServerConfigurationProviding, FBSDKServerConfigurationLoading>)serverConfiguration
{
  return _serverConfiguration;
}

+ (id<FBSDKGraphRequestProviding>)requestProvider
{
  return _requestProvider;
}

+ (void)configureWithTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                        settings:(id<FBSDKSettings>)settings
             serverConfiguration:(Class<FBSDKServerConfigurationProviding, FBSDKServerConfigurationLoading>)serverConfiguration
                 requestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
{
  if (self == [FBSDKGraphRequestPiggybackManager class]) {
    _tokenWallet = tokenWallet;
    _settings = settings;
    _serverConfiguration = serverConfiguration;
    _requestProvider = requestProvider;
  }
}

+ (void)addPiggybackRequests:(id<FBSDKGraphRequestConnecting>)connection
{
  if ([self.settings appID].length > 0) {
    BOOL safeForPiggyback = YES;
    id<_FBSDKGraphRequestConnecting> internalConnection = FBSDK_CAST_TO_PROTOCOL_OR_NIL(connection, _FBSDKGraphRequestConnecting);

    for (FBSDKGraphRequestMetadata *metadata in internalConnection.requests) {
      if (![self _safeForPiggyback:metadata.request]) {
        safeForPiggyback = NO;
        break;
      }
    }
    if (safeForPiggyback) {
      [[self class] addRefreshPiggybackIfStale:connection];
      [[self class] addServerConfigurationPiggyback:connection];
    }
  }
}

+ (void)addRefreshPiggyback:(id<FBSDKGraphRequestConnecting>)connection permissionHandler:(FBSDKGraphRequestCompletion)permissionHandler
{
  FBSDKAccessToken *expectedToken = [self.tokenWallet currentAccessToken];
  if (!expectedToken) {
    return;
  }
  __block NSMutableSet *permissions = nil;
  __block NSMutableSet *declinedPermissions = nil;
  __block NSMutableSet *expiredPermissions = nil;
  __block NSString *tokenString = nil;
  __block NSNumber *expirationDateNumber = nil;
  __block NSNumber *dataAccessExpirationDateNumber = nil;
  __block NSString *graphDomain = nil;
  __block int expectingCallbacksCount = 2;
  void (^expectingCallbackComplete)(void) = ^{
    if (--expectingCallbacksCount == 0) {
      FBSDKAccessToken *currentToken = [self.tokenWallet currentAccessToken];
      NSDate *expirationDate = currentToken.expirationDate;
      if (expirationDateNumber != nil) {
        expirationDate = (expirationDateNumber.doubleValue > 0
          ? [NSDate dateWithTimeIntervalSince1970:expirationDateNumber.doubleValue]
          : [NSDate distantFuture]);
      }
      NSDate *dataExpirationDate = currentToken.dataAccessExpirationDate;
      if (dataAccessExpirationDateNumber != nil) {
        dataExpirationDate = (dataAccessExpirationDateNumber.doubleValue > 0
          ? [NSDate dateWithTimeIntervalSince1970:dataAccessExpirationDateNumber.doubleValue]
          : [NSDate distantFuture]);
      }

      #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Wdeprecated-declarations"
      FBSDKAccessToken *refreshedToken = [[FBSDKAccessToken alloc] initWithTokenString:tokenString ?: currentToken.tokenString
                                                                           permissions:(permissions ?: currentToken.permissions).allObjects
                                                                   declinedPermissions:(declinedPermissions ?: currentToken.declinedPermissions).allObjects
                                                                    expiredPermissions:(expiredPermissions ?: currentToken.expiredPermissions).allObjects
                                                                                 appID:currentToken.appID
                                                                                userID:currentToken.userID
                                                                        expirationDate:expirationDate
                                                                           refreshDate:[NSDate date]
                                                              dataAccessExpirationDate:dataExpirationDate
                                                                           graphDomain:graphDomain ?: currentToken.graphDomain];
      #pragma clange diagnostic pop

      if (expectedToken == currentToken) {
        [self.tokenWallet setCurrentAccessToken:refreshedToken];
      }
    }
  };
  id<FBSDKGraphRequest> extendRequest = [self.requestProvider createGraphRequestWithGraphPath:@"oauth/access_token"
                                                                                   parameters:@{@"grant_type" : @"fb_extend_sso_token",
                                                                                                @"fields" : @"",
                                                                                                @"client_id" : expectedToken.appID}
                                                                                        flags:FBSDKGraphRequestFlagDisableErrorRecovery];

  [connection addRequest:extendRequest completion:^(id<FBSDKGraphRequestConnecting> innerConnection, id result, NSError *error) {
    tokenString = [FBSDKTypeUtility dictionary:result objectForKey:@"access_token" ofType:NSString.class];
    expirationDateNumber = [FBSDKTypeUtility dictionary:result objectForKey:@"expires_at" ofType:NSNumber.class];
    dataAccessExpirationDateNumber = [FBSDKTypeUtility dictionary:result objectForKey:@"data_access_expiration_time" ofType:NSNumber.class];
    graphDomain = [FBSDKTypeUtility dictionary:result objectForKey:@"graph_domain" ofType:NSString.class];
    expectingCallbackComplete();
  }];
  id<FBSDKGraphRequest> permissionsRequest = [self.requestProvider createGraphRequestWithGraphPath:@"me/permissions"
                                                                                        parameters:@{@"fields" : @""}
                                                                                             flags:FBSDKGraphRequestFlagDisableErrorRecovery];

  [connection addRequest:permissionsRequest completion:^(id<FBSDKGraphRequestConnecting> innerConnection, id result, NSError *error) {
    if (!error) {
      permissions = [NSMutableSet set];
      declinedPermissions = [NSMutableSet set];
      expiredPermissions = [NSMutableSet set];

      [FBSDKInternalUtility extractPermissionsFromResponse:result
                                        grantedPermissions:permissions
                                       declinedPermissions:declinedPermissions
                                        expiredPermissions:expiredPermissions];
    }
    expectingCallbackComplete();
    if (permissionHandler) {
      permissionHandler(innerConnection, result, error);
    }
  }];
}

+ (void)addRefreshPiggybackIfStale:(id<FBSDKGraphRequestConnecting>)connection
{
  // don't piggy back more than once an hour as a cheap way of
  // retrying in cases of errors and preventing duplicate refreshes.
  // obviously this is not foolproof but is simple and sufficient.
  NSDate *now = [NSDate date];
  NSDate *tokenRefreshDate = [self.tokenWallet currentAccessToken].refreshDate;
  if (tokenRefreshDate
      && [now timeIntervalSinceDate:[self _lastRefreshTry]] > [self _tokenRefreshRetryInSeconds]
      && [now timeIntervalSinceDate:tokenRefreshDate] > [self _tokenRefreshThresholdInSeconds]) {
    [self addRefreshPiggyback:connection permissionHandler:NULL];
    [self _setLastRefreshTry:[NSDate date]];
  }
}

+ (void)addServerConfigurationPiggyback:(id<FBSDKGraphRequestConnecting>)connection
{
  if (![self.serverConfiguration cachedServerConfiguration].isDefaults
      && [[NSDate date] timeIntervalSinceDate:[self.serverConfiguration cachedServerConfiguration].timestamp]
      < FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT) {
    return;
  }
  NSString *appID = [self.settings appID];
  id<FBSDKGraphRequest> serverConfigurationRequest = [self.serverConfiguration requestToLoadServerConfiguration:appID];
  [connection addRequest:serverConfigurationRequest
              completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {
                [self.serverConfiguration processLoadRequestResponse:result error:error appID:appID];
              }];
}

+ (BOOL)_safeForPiggyback:(id<FBSDKGraphRequest>)request
{
  BOOL isVersionSafe = [request.version isEqualToString:[self.settings graphAPIVersion]];
  BOOL hasAttachments = [(id<FBSDKGraphRequest>)request hasAttachments];
  return isVersionSafe && !hasAttachments;
}

+ (int)_tokenRefreshThresholdInSeconds
{
  return FBSDKTokenRefreshThresholdSeconds;
}

+ (int)_tokenRefreshRetryInSeconds
{
  return FBSDKTokenRefreshRetrySeconds;
}

+ (NSDate *)_lastRefreshTry
{
  if (!_lastRefreshTry) {
    _lastRefreshTry = [NSDate distantPast];
  }
  return _lastRefreshTry;
}

+ (void)_setLastRefreshTry:(NSDate *)date
{
  _lastRefreshTry = date;
}

#if DEBUG
 #if FBSDKTEST

+ (void)setTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
{
  _tokenWallet = tokenWallet;
}

+ (void)reset
{
  _tokenWallet = nil;
  _lastRefreshTry = nil;
}

 #endif
#endif

@end
