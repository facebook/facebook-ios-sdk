/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestPiggybackManager.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGraphRequestConnecting+Internal.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKServerConfigurationManager.h"

@implementation FBSDKGraphRequestPiggybackManager

- (instancetype)initWithTokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet
                           settings:(id<FBSDKSettings>)settings
        serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  if ((self = [super init])) {
    _tokenWallet = tokenWallet;
    _settings = settings;
    _serverConfigurationProvider = serverConfigurationProvider;
    _graphRequestFactory = graphRequestFactory;
    _lastRefreshTry = NSDate.distantPast;
    _tokenRefreshThresholdInSeconds = 24 * 60 * 60; // one day
    _tokenRefreshRetryInSeconds = 60 * 60; // one hour
  }

  return self;
}

- (void)addPiggybackRequests:(id<FBSDKGraphRequestConnecting>)connection
{
  if (self.settings.appID.length > 0) {
    BOOL safeForPiggyback = YES;

    id<_FBSDKGraphRequestConnecting> internalConnection;
    if ([((NSObject *)connection) conformsToProtocol:@protocol(_FBSDKGraphRequestConnecting)]) {
      internalConnection = (id<_FBSDKGraphRequestConnecting>)connection;
    }

    for (FBSDKGraphRequestMetadata *metadata in internalConnection.requests) {
      if (![self isRequestSafeForPiggyback:metadata.request]) {
        safeForPiggyback = NO;
        break;
      }
    }

    if (safeForPiggyback) {
      [self addRefreshPiggybackIfStale:connection];
      [self addServerConfigurationPiggyback:connection];
    }
  }
}

- (void)addRefreshPiggyback:(id<FBSDKGraphRequestConnecting>)connection
          permissionHandler:(nullable FBSDKGraphRequestCompletion)permissionHandler
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

- (void)addRefreshPiggybackIfStale:(id<FBSDKGraphRequestConnecting>)connection
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

- (void)addServerConfigurationPiggyback:(id<FBSDKGraphRequestConnecting>)connection
{
  id<FBSDKServerConfigurationProviding> serverConfigurationProvider = self.serverConfigurationProvider;
  if (!serverConfigurationProvider) {
    return;
  }

  if (![serverConfigurationProvider cachedServerConfiguration].isDefaults
      && [[NSDate date] timeIntervalSinceDate:serverConfigurationProvider.cachedServerConfiguration.timestamp]
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

- (BOOL)isRequestSafeForPiggyback:(id<FBSDKGraphRequest>)request
{
  BOOL isVersionSafe = [request.version isEqualToString:self.settings.graphAPIVersion];
  BOOL hasAttachments = [request hasAttachments];
  return isVersionSafe && !hasAttachments;
}

@end
