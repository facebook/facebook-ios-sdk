/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FBSDKCoreKit;

#import "FBSDKLoginManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginManager (Testing)

- (nullable NSDictionary<NSString *, id> *)logInParametersFromURL:(NSURL *)url;

- (nullable NSString *)loadExpectedNonce;

- (void)storeExpectedNonce:(nullable NSString *)nonceExpected keychainStore:(FBSDKKeychainStore *)keychainStore;

- (void)storeExpectedNonce:(nullable NSString *)nonceExpected;

- (NSSet<FBSDKPermission *> *)recentlyGrantedPermissionsFromGrantedPermissions:(NSSet<FBSDKPermission *> *)grantedPermissions;

- (NSSet<FBSDKPermission *> *)recentlyDeclinedPermissionsFromDeclinedPermissions:(NSSet<FBSDKPermission *> *)declinedPermissions;

- (void)validateReauthenticationWithGraphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                                                        withToken:(FBSDKAccessToken *)currentToken
                                                       withResult:(FBSDKLoginManagerLoginResult *)loginResult;

// UNCRUSTIFY_FORMAT_OFF
- (void)validateReauthentication:(FBSDKAccessToken *)currentToken
                      withResult:(nullable FBSDKLoginManagerLoginResult *)loginResult
NS_SWIFT_NAME(validateReauthentication(accessToken:result:));
// UNCRUSTIFY_FORMAT_ON

- (nullable NSDictionary<NSString *, id> *)logInParametersWithConfiguration:(FBSDKLoginConfiguration *)configuration;

- (void)logInWithPermissions:(NSArray<NSString *> *)permissions
          fromViewController:(UIViewController *)viewController
                     handler:(FBSDKLoginManagerLoginResultBlock)handler;

@end

NS_ASSUME_NONNULL_END
