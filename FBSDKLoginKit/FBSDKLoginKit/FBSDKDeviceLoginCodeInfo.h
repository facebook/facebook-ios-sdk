/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract Describes the initial response when starting the device login flow.
 @discussion This is used by `FBSDKDeviceLoginManager`.
 */
NS_SWIFT_NAME(DeviceLoginCodeInfo)
@interface FBSDKDeviceLoginCodeInfo : NSObject

/*!
 @abstract There is no public initializer.
 */
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*!
 @abstract the unique id for this login flow.
*/
@property (nonatomic, readonly, copy) NSString *identifier;

/*!
 @abstract the short "user_code" that should be presented to the user.
*/
@property (nonatomic, readonly, copy) NSString *loginCode;

/*!
 @abstract the verification URL.
*/
@property (nonatomic, readonly, copy) NSURL *verificationURL;

/*!
 @abstract the expiration date.
*/
@property (nonatomic, readonly, copy) NSDate *expirationDate;

/*!
 @abstract the polling interval
*/
@property (nonatomic, readonly, assign) NSUInteger pollingInterval;

@end

NS_ASSUME_NONNULL_END
