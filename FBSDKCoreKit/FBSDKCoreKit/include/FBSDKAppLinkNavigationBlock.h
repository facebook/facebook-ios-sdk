/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKAppLinkNavigationType.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Describes the callback for appLinkFromURLInBackground.
 @param navType the FBSDKAppLink representing the deferred App Link
 @param error the error during the request, if any
 */
typedef void (^ FBSDKAppLinkNavigationBlock)(FBSDKAppLinkNavigationType navType, NSError *_Nullable error)
NS_SWIFT_NAME(AppLinkNavigationBlock);

NS_ASSUME_NONNULL_END

#endif
