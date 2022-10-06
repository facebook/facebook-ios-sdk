/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DeviceDialogViewDelegate)
@protocol FBSDKDeviceDialogViewDelegate;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

NS_SWIFT_NAME(FBDeviceDialogView)
DEPRECATED_MSG_ATTRIBUTE("Support for tvOS is deprecated and will be removed in the next major release.")
@interface FBSDKDeviceDialogView : UIView

@property (nonatomic, weak) id<FBSDKDeviceDialogViewDelegate> delegate;
@property (nonatomic, copy) NSString *confirmationCode;

// override point for subclasses.
- (void)buildView;

@end

NS_SWIFT_NAME(DeviceDialogViewDelegate)
DEPRECATED_MSG_ATTRIBUTE("Support for tvOS is deprecated and will be removed in the next major release.")
@protocol FBSDKDeviceDialogViewDelegate <NSObject>

- (void)deviceDialogViewDidCancel:(FBSDKDeviceDialogView *)deviceDialogView;

@end

NS_ASSUME_NONNULL_END

#endif
