/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKDeviceInformationProviding.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsDeviceInfo)
@interface FBSDKAppEventsDeviceInfo : NSObject <FBSDKDeviceInformationProviding>

@property (class, nonnull, nonatomic, readonly) FBSDKAppEventsDeviceInfo *shared;

@property (nullable, nonatomic, readonly) id<FBSDKSettings> settings;

// Ephemeral data, may change during the lifetime of an app.  We collect them in different
// 'group' frequencies - group1 may gets collected once every 30 minutes.

// group1
@property (nonatomic) NSString *carrierName;
@property (nonatomic) NSString *timeZoneAbbrev;
@property (nonatomic) NSString *timeZoneName;

// Persistent data, but we maintain it to make rebuilding the device info as fast as possible.
@property (nonatomic) NSString *bundleIdentifier;
@property (nonatomic) NSString *longVersion;
@property (nonatomic) NSString *shortVersion;
@property (nonatomic) NSString *sysVersion;
@property (nonatomic) NSString *machine;
@property (nonatomic) NSString *language;
@property (nonatomic) unsigned long long coreCount;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat density;

#if !DEBUG
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
#endif

- (void)configureWithSettings:(id<FBSDKSettings>)settings
NS_SWIFT_NAME(configure(settings:));

#if DEBUG
- (void)resetDependencies;
#endif

@end

NS_ASSUME_NONNULL_END
