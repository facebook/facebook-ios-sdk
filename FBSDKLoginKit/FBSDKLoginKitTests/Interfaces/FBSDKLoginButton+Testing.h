/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginButton (Testing)

@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

- (FBSDKLoginConfiguration *)loginConfiguration;
- (BOOL)_isAuthenticated;
- (void)_fetchAndSetContent;
- (void)_initializeContent;
- (void)_updateContentForAccessToken;
- (void)_updateContentForUserProfile:(nullable FBSDKProfile *)profile;
- (void)_accessTokenDidChangeNotification:(NSNotification *)notification;
- (void)_profileDidChangeNotification:(NSNotification *)notification;
- (nullable NSString *)userName;
- (nullable NSString *)userID;
- (void)setLoginProvider:(id<FBSDKLoginProviding>)loginProvider;
- (void)_buttonPressed:(id)sender;
- (void)_logout;
- (void)setGraphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestFactory;

@end

NS_ASSUME_NONNULL_END
