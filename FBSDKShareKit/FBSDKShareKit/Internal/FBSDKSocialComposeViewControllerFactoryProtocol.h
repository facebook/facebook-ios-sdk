/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSocialComposeViewController.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SocialComposeViewControllerFactoryProtocol)
@protocol FBSDKSocialComposeViewControllerFactory

@property (nonatomic, readonly) BOOL canMakeSocialComposeViewController;

- (nullable id<FBSDKSocialComposeViewController>)makeSocialComposeViewController;

@end

NS_ASSUME_NONNULL_END

#endif
