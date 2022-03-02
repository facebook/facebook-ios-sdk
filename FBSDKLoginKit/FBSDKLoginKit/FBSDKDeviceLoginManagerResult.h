/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class FBSDKAccessToken;

NS_ASSUME_NONNULL_BEGIN

/**
 Represents the results of the a device login flow.
 This is used by `FBSDKDeviceLoginManager`.
 */
NS_SWIFT_NAME(DeviceLoginManagerResult)
@interface FBSDKDeviceLoginManagerResult : NSObject

// There is no public initializer.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// The token.
@property (nullable, nonatomic, readonly, strong) FBSDKAccessToken *accessToken;

/**
 Indicates if the login was cancelled by the user, or if the device
  login code has expired.
 */
@property (nonatomic, readonly, getter = isCancelled, assign) BOOL cancelled;

@end

NS_ASSUME_NONNULL_END
