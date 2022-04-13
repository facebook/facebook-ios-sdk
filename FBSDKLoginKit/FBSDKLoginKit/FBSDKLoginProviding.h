/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#if !TARGET_OS_TV

 #import <FBSDKLoginKit/FBSDKDefaultAudience.h>
 #import <FBSDKLoginKit/FBSDKLoginManagerLoginResultBlock.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKLoginConfiguration;

NS_SWIFT_NAME(_LoginProviding)
@protocol FBSDKLoginProviding

@property (nonatomic, assign) FBSDKDefaultAudience defaultAudience;

- (void)logInFromViewController:(nullable UIViewController *)viewController
                  configuration:(FBSDKLoginConfiguration *)configuration
                     completion:(FBSDKLoginManagerLoginResultBlock)completion NS_REFINED_FOR_SWIFT;

// UNCRUSTIFY_FORMAT_OFF
- (void)logInWithPermissions:(NSArray<NSString *> *)permissions
          fromViewController:(nullable UIViewController *)viewController
                     handler:(FBSDKLoginManagerLoginResultBlock)handler
NS_SWIFT_NAME(logIn(permissions:from:handler:));
// UNCRUSTIFY_FORMAT_ON

- (void)logOut;

@end

NS_ASSUME_NONNULL_END

#endif
