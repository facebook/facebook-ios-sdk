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

NS_SWIFT_NAME(DeviceUtilities)
@interface FBSDKDeviceUtilities : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (UIImage *)buildQRCodeWithAuthorizationCode:(nullable NSString *)authorizationCode;

@end

NS_ASSUME_NONNULL_END

#endif
