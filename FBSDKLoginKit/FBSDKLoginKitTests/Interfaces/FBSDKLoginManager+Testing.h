/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKCoreKit;

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginKit+Internal.h>
#else
 #import "FBSDKLoginManager+Internal.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginManager (Testing)

@property (nonatomic) FBSDKLoginManagerLoginResultBlock handler;
@property (nonatomic) FBSDKLoginConfiguration *configuration;
@property (nonatomic) id<FBSDKKeychainStore> keychainStore;
@property (nonatomic) Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting> tokenWallet;
@property (nonatomic) Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting> authenticationToken;
@property (nonatomic) Class<FBSDKProfileProviding> profile;
@property (nonatomic)  id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nonatomic) id<FBSDKURLHosting, FBSDKAppURLSchemeProviding, FBSDKAppAvailabilityChecker> internalUtility;
@property (nonatomic) id<FBSDKURLOpener> urlOpener;

- (nullable NSDictionary<NSString *, id> *)logInParametersFromURL:(NSURL *)url;

- (nullable NSString *)loadExpectedNonce;

- (void)storeExpectedNonce:(nullable NSString *)nonceExpected keychainStore:(FBSDKKeychainStore *)keychainStore;

- (FBSDKLoginConfiguration *)configuration;

- (void)storeExpectedNonce:(nullable NSString *)nonceExpected;

- (NSSet<FBSDKPermission *> *)recentlyGrantedPermissionsFromGrantedPermissions:(NSSet<FBSDKPermission *> *)grantedPermissions;

- (NSSet<FBSDKPermission *> *)recentlyDeclinedPermissionsFromDeclinedPermissions:(NSSet<FBSDKPermission *> *)declinedPermissions;

- (void)validateReauthenticationWithGraphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                                                        withToken:(FBSDKAccessToken *)currentToken
                                                       withResult:(FBSDKLoginManagerLoginResult *)loginResult;

- (void)validateReauthentication:(FBSDKAccessToken *)currentToken
                      withResult:(nullable FBSDKLoginManagerLoginResult *)loginResult;

- (nullable NSDictionary<NSString *, id> *)logInParametersWithConfiguration:(FBSDKLoginConfiguration *)configuration;

- (void)logInWithPermissions:(NSArray<NSString *> *)permissions
          fromViewController:(UIViewController *)viewController
                     handler:(FBSDKLoginManagerLoginResultBlock)handler;

- (instancetype)initWithInternalUtility:(id<FBSDKURLHosting, FBSDKAppURLSchemeProviding, FBSDKAppAvailabilityChecker>)internalUtility
                   keychainStoreFactory:(id<FBSDKKeychainStoreProviding>)keychainStoreFactory
                            tokenWallet:(Class<FBSDKAccessTokenProviding, FBSDKAccessTokenSetting>)tokenWallet
          graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                    authenticationToken:(Class<FBSDKAuthenticationTokenProviding, FBSDKAuthenticationTokenSetting>)authenticationToken
                                profile:(Class<FBSDKProfileProviding>)profile
                              urlOpener:(id<FBSDKURLOpener>)urlOpener;

@end

NS_ASSUME_NONNULL_END
