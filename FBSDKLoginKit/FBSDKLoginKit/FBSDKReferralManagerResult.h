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

 #import <FBSDKLoginKit/FBSDKReferralCode.h>

NS_ASSUME_NONNULL_BEGIN

/**
  Describes the result of a referral request.
 */
NS_SWIFT_NAME(ReferralManagerResult)
DEPRECATED_MSG_ATTRIBUTE("`FBSDKReferralCode` is deprecated and will be removed in the next major release")
@interface FBSDKReferralManagerResult : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  whether the referral was cancelled by the user.
 */
@property (nonatomic, readonly) BOOL isCancelled;

/**
  An array of referral codes for each referral made by the user
 */
@property (nonatomic, copy) NSArray<FBSDKReferralCode *> *referralCodes;

/** Initializes a new instance.
 @param referralCodes the referral codes
 @param isCancelled whether the referral was cancelled by the user
 */
- (instancetype)initWithReferralCodes:(nullable NSArray<FBSDKReferralCode *> *)referralCodes
                          isCancelled:(BOOL)isCancelled
  NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END

#endif
