/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKDeviceLoginCodeInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKDeviceLoginCodeInfo ()

// UNCRUSTIFY_FORMAT_OFF
/*!
 @abstract Initializes a new instance
 @param identifier the unique id for this login flow instance.
 @param loginCode the short "user_code".
 @param verificationURL the verification URL.
 @param expirationDate expiration date.
 @param pollingInterval time between polling.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                         loginCode:(NSString *)loginCode
                   verificationURL:(NSURL *)verificationURL
                    expirationDate:(NSDate *)expirationDate
                   pollingInterval:(NSUInteger)pollingInterval
NS_SWIFT_NAME(init(identifier:loginCode:verificationURL:expirationDate:pollingInterval:))
NS_DESIGNATED_INITIALIZER;

@end
// UNCRUSTIFY_FORMAT_ON

NS_ASSUME_NONNULL_END
