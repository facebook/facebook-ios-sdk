/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef NS_ENUM(NSUInteger, FBSDKAdvertisingTrackingStatus) {
  FBSDKAdvertisingTrackingAllowed,
  FBSDKAdvertisingTrackingDisallowed,
  FBSDKAdvertisingTrackingUnspecified,
} NS_SWIFT_NAME(AdvertisingTrackingStatus);

NS_ASSUME_NONNULL_END
