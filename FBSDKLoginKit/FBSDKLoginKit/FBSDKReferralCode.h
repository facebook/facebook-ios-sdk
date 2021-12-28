/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represent a referral code used in the referral process
*/
NS_SWIFT_NAME(ReferralCode)
DEPRECATED_MSG_ATTRIBUTE("`FBSDKReferralCode` is deprecated and will be removed in the next major release")
@interface FBSDKReferralCode : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 The string value of the referral code
*/
@property (nonatomic) NSString *value;

/**
 Initializes a new instance if the referral code is valid. Otherwise returns nil.
 A code is valid if it is non-empty and contains only alphanumeric characters.
 @param string the raw string referral code
*/
+ (nullable instancetype)initWithString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END

#endif
