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

NS_SWIFT_NAME(FBSmartDeviceDialogView)
DEPRECATED_MSG_ATTRIBUTE("Support for tvOS is deprecated and will be removed in the next major release.")
@interface FBSDKSmartDeviceDialogView : FBSDKDeviceDialogView
@end

NS_ASSUME_NONNULL_END

#endif
