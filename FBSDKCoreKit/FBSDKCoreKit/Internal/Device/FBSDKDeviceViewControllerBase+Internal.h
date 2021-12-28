/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKDeviceViewControllerBase.h>

@class FBSDKDeviceDialogView;

NS_ASSUME_NONNULL_BEGIN

/*
  An internal base class for device related flows.

 This is an internal API that should not be used directly and is subject to change.
*/
@interface FBSDKDeviceViewControllerBase () <
  UIViewControllerAnimatedTransitioning,
  UIViewControllerTransitioningDelegate
>

@property (nonatomic, readonly, strong) FBSDKDeviceDialogView *deviceDialogView;

@end

NS_ASSUME_NONNULL_END

#endif
