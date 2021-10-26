/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@class FBSDKAccessToken;

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract Represents the results of the a device login flow.
 @discussion This is used by `FBSDKDeviceLoginManager`.
 */
NS_SWIFT_NAME(DeviceLoginManagerResult)
@interface FBSDKDeviceLoginManagerResult : NSObject

/*!
 @abstract There is no public initializer.
 */
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*!
 @abstract The token.
 */
@property (nullable, nonatomic, readonly, strong) FBSDKAccessToken *accessToken;

/*!
 @abstract Indicates if the login was cancelled by the user, or if the device
  login code has expired.
 */
@property (nonatomic, readonly, getter = isCancelled, assign) BOOL cancelled;

@end

NS_ASSUME_NONNULL_END
