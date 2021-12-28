/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKLoginKit/FBSDKLoginManager.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKLoginConfiguration;

NS_SWIFT_NAME(LoginProviding)
@protocol FBSDKLoginProviding

@property (nonatomic, assign) FBSDKDefaultAudience defaultAudience;

- (void)logInFromViewController:(nullable UIViewController *)viewController
                  configuration:(FBSDKLoginConfiguration *)configuration
                     completion:(FBSDKLoginManagerLoginResultBlock)completion;

- (void)logInWithPermissions:(NSArray<NSString *> *)permissions
          fromViewController:(nullable UIViewController *)viewController
                     handler:(FBSDKLoginManagerLoginResultBlock)handler;

- (void)logOut;

@end

NS_ASSUME_NONNULL_END
