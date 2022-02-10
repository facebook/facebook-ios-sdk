/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Describes the initial response when starting the device login flow.
 This is used by `FBSDKDeviceLoginManager`.
 */
NS_SWIFT_NAME(DeviceLoginCodeInfo)
@interface FBSDKDeviceLoginCodeInfo : NSObject

// There is no public initializer.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// The unique id for this login flow.
@property (nonatomic, readonly, copy) NSString *identifier;

/// The short "user_code" that should be presented to the user.
@property (nonatomic, readonly, copy) NSString *loginCode;

/// The verification URL.
@property (nonatomic, readonly, copy) NSURL *verificationURL;

/// The expiration date.
@property (nonatomic, readonly, copy) NSDate *expirationDate;

/// The polling interval
@property (nonatomic, readonly, assign) NSUInteger pollingInterval;

@end

NS_ASSUME_NONNULL_END
