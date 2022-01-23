/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKDeviceDialogView.h>

NS_ASSUME_NONNULL_BEGIN

/*
  An internal base class for device related flows.

 This is an internal API that should not be used directly and is subject to change.
 */
NS_SWIFT_NAME(FBDeviceViewControllerBase)
@interface FBSDKDeviceViewControllerBase : UIViewController <FBSDKDeviceDialogViewDelegate>
@end

NS_ASSUME_NONNULL_END

#endif
