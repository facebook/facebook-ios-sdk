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
// group1
@property (nullable, nonatomic) NSString *carrierName;
@property (nullable, nonatomic) NSString *timeZoneAbbrev;
@property (nonatomic) unsigned long long remainingDiskSpaceGB;
@property (nullable, nonatomic) NSString *timeZoneName;

// Persistent data, but we maintain it to make rebuilding the device info as fast as possible.
@property (nullable, nonatomic) NSString *bundleIdentifier;
@property (nullable, nonatomic) NSString *longVersion;
@property (nullable, nonatomic) NSString *shortVersion;
@property (nullable, nonatomic) NSString *sysVersion;
@property (nullable, nonatomic) NSString *machine;
@property (nullable, nonatomic) NSString *language;
@property (nonatomic) unsigned long long totalDiskSpaceGB;
@property (nonatomic) unsigned long long coreCount;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat density;

@end

NS_ASSUME_NONNULL_END
