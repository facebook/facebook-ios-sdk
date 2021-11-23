/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestPiggybackManager+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKGraphRequestConnecting+Internal.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKSettings+Internal.h"

static int const FBSDKTokenRefreshThresholdSeconds = 24 * 60 * 60; // day
static int const FBSDKTokenRefreshRetrySeconds = 60 * 60; // hour

@interface FBSDKGraphRequestPiggybackManager ()

@property (nullable, nonatomic) NSDate *lastRefreshTry;

@end

@implementation FBSDKGraphRequestPiggybackManager

static NSDate *_lastRefreshTry;

static Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> _tokenWallet;
static id<FBSDKSettings> _settings;
static id<FBSDKServerConfigurationProviding> _serverConfigurationProvider;
static id<FBSDKGraphRequestFactory> _graphRequestFactory;

+ (nullable Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
{
  return _tokenWallet;
}

+ (void)setTokenWallet:(nullable Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
{
  _tokenWallet = tokenWallet;
}

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (nullable id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  return _serverConfigurationProvider;
}

+ (void)setServerConfigurationProvider:(nullable id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  _serverConfigurationProvider = serverConfigurationProvider;
}

+ (nullable id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  return _graphRequestFactory;
}

+ (void)setGraphRequestFactory:(nullable id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  _graphRequestFactory = graphRequestFactory;
}

+ (void)configureWithTokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
                        settings:(id<FBSDKSettings>)settings
     serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
             graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  if (self == FBSDKGraphRequestPiggybackManager.class) {
    self.tokenWallet = tokenWallet;
    self.settings = settings;
    self.serverConfigurationProvider = serverConfigurationProvider;
    self.graphRequestFactory = graphRequestFactory;
  }
}

+ (void)addPiggybackRequests:(id<FBSDKGraphRequestConnecting>)connection
{
  if ([self.settings appID].length > 0) {
    BOOL safeForPiggyback = YES;
    id<_FBSDKGraphRequestConnecting> internalConnection = FBSDK_CAST_TO_PROTOCOL_OR_NIL(connection, _FBSDKGraphRequestConnecting);

    for (FBSDKGraphRequestMetadata *metadata in internalConnection.requests) {
      if (![self isRequestSafeForPiggyback:metadata.request]) {
        safeForPiggyback = NO;
        break;
      }
    }
    if (safeForPiggyback) {
      [self.class addRefreshPiggybackIfStale:connection];
      [self.class addServerConfigurationPiggyback:connection];
    }
  }
}

+ (void)addRefreshPiggyback:(id<FBSDKGraphRequestConnecting>)connection permissionHandler:(nullable FBSDKGraphRequestCompletion)permissionHandler
{
  FBSDKAccessToken *expectedToken = [self.tokenWallet currentAccessToken];
  if (!expectedToken) {
    return;
  }
  __block NSMutableSet<NSString *> *permissions = nil;
  __block NSMutableSet<NSString *> *declinedPermissions = nil;
  __block NSMutableSet<NSString *> *expiredPermissions = nil;
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
          : NSDate.distantFuture);
      }
      NSDate *dataExpirationDate = currentToken.dataAccessExpirationDate;
      if (dataAccessExpirationDateNumber != nil) {
        dataExpirationDate = (dataAccessExpirationDateNumber.doubleValue > 0
          ? [NSDate dateWithTimeIntervalSince1970:dataAccessExpirationDateNumber.doubleValue]
          : NSDate.distantFuture);
      }

      FBSDKAccessToken *refreshedToken = [[FBSDKAccessToken alloc] initWithTokenString:tokenString ?: currentToken.tokenString
                                                                           permissions:(permissions ?: currentToken.permissions).allObjects
                                                                   declinedPermissions:(declinedPermissions ?: currentToken.declinedPermissions).allObjects
                                                                    expiredPermissions:(expiredPermissions ?: currentToken.expiredPermissions).allObjects
                                                                                 appID:currentToken.appID
                                                                                userID:currentToken.userID
                                                                        expirationDate:expirationDate
                                                                           refreshDate:[NSDate date]
                                                              dataAccessExpirationDate:dataExpirationDate];

      if (expectedToken == currentToken) {
        [self.tokenWallet setCurrentAccessToken:refreshedToken];
      }
    }
  };
  id<FBSDKGraphRequest> extendRequest = [self.graphRequestFactory createGraphRequestWithGraphPath:@"oauth/access_token"
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
  id<FBSDKGraphRequest> permissionsRequest = [self.graphRequestFactory createGraphRequestWithGraphPath:@"me/permissions"
                                                                                            parameters:@{@"fields" : @""}
                                                                                                 flags:FBSDKGraphRequestFlagDisableErrorRecovery];

  [connection addRequest:permissionsRequest completion:^(id<FBSDKGraphRequestConnecting> innerConnection, id result, NSError *error) {
    if (!error) {
      permissions = [NSMutableSet set];
      declinedPermissions = [NSMutableSet set];
      expiredPermissions = [NSMutableSet set];

      [FBSDKInternalUtility.sharedUtility extractPermissionsFromResponse:result
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
      && [now timeIntervalSinceDate:self.lastRefreshTry] > self.tokenRefreshRetryInSeconds
      && [now timeIntervalSinceDate:tokenRefreshDate] > self.tokenRefreshThresholdInSeconds) {
    [self addRefreshPiggyback:connection permissionHandler:NULL];
    self.lastRefreshTry = [NSDate date];
  }
}

+ (void)addServerConfigurationPiggyback:(id<FBSDKGraphRequestConnecting>)connection
{
  id<FBSDKServerConfigurationProviding> serverConfigurationProvider = self.serverConfigurationProvider;
  if (!serverConfigurationProvider) {
    return;
  }

  if (![serverConfigurationProvider cachedServerConfiguration].isDefaults
      && [[NSDate date] timeIntervalSinceDate:[serverConfigurationProvider cachedServerConfiguration].timestamp]
      < FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT) {
    return;
  }

  NSString *appID = [self.settings appID];
  if (appID) {
    id<FBSDKGraphRequest> serverConfigurationRequest = [serverConfigurationProvider requestToLoadServerConfiguration:appID];
    if (serverConfigurationRequest) {
      [connection addRequest:serverConfigurationRequest
                  completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {
                    [self.serverConfigurationProvider processLoadRequestResponse:result error:error appID:appID];
                  }];
    }
  }
}

+ (BOOL)isRequestSafeForPiggyback:(id<FBSDKGraphRequest>)request
{
  BOOL isVersionSafe = [request.version isEqualToString:self.settings.graphAPIVersion];
  BOOL hasAttachments = [(id<FBSDKGraphRequest>)request hasAttachments];
  return isVersionSafe && !hasAttachments;
}

+ (int)tokenRefreshThresholdInSeconds
{
  return FBSDKTokenRefreshThresholdSeconds;
}

+ (int)tokenRefreshRetryInSeconds
{
  return FBSDKTokenRefreshRetrySeconds;
}

+ (NSDate *)lastRefreshTry
{
  if (!_lastRefreshTry) {
    _lastRefreshTry = NSDate.distantPast;
  }
  return _lastRefreshTry;
}

+ (void)setLastRefreshTry:(NSDate *)lastRefreshTry
{
  _lastRefreshTry = lastRefreshTry;
}

#if DEBUG && FBTEST

+ (void)reset
{
  self.tokenWallet = nil;
  self.settings = nil;
  self.serverConfigurationProvider = nil;
  self.graphRequestFactory = nil;

  _lastRefreshTry = nil;
}

#endif

@end
