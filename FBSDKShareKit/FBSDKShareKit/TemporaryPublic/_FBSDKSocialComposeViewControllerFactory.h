/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKShareKit/_FBSDKSocialComposeViewControllerFactoryProtocol.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_SocialComposeViewControllerFactory)
@interface _FBSDKSocialComposeViewControllerFactory : NSObject <_FBSDKSocialComposeViewControllerFactory>
@end

NS_ASSUME_NONNULL_END

#endif
