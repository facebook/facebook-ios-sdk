/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKLoginButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginButton (Testing)

@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKUserInterfaceElementProviding> elementProvider;
@property (nonatomic) id<FBSDKUserInterfaceStringProviding> stringProvider;
@property (nonatomic) id<FBSDKLoginProviding> loginProvider;
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
- (void)_buttonPressed:(id)sender;
- (void)_logout;
// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithElementProvider:(nonnull id<FBSDKUserInterfaceElementProviding>)elementProvider
                      stringProvider:(nonnull id<FBSDKUserInterfaceStringProviding>)stringProvider
                       loginProvider:(nonnull id<FBSDKLoginProviding>)loginProvider
                 graphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestFactory
NS_SWIFT_NAME(configure(elementProvider:stringProvider:loginProvider:graphRequestFactory:));
// UNCRUSTIFY_FORMAT_ON
@end

NS_ASSUME_NONNULL_END
