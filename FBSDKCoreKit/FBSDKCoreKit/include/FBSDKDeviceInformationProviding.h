/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_DeviceInformationProviding)
@protocol FBSDKDeviceInformationProviding

@property (nonatomic, readonly) NSString *storageKey;
@property (nullable, nonatomic, readonly) NSString *encodedDeviceInfo;

@end

NS_ASSUME_NONNULL_END
