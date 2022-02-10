/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(UserAgeRange)
@interface FBSDKUserAgeRange : NSObject <NSCopying, NSObject, NSSecureCoding>

/// The user's minimun age, nil if unspecified
@property (nullable, nonatomic, readonly, strong) NSNumber *min;
/// The user's maximun age, nil if unspecified
@property (nullable, nonatomic, readonly, strong) NSNumber *max;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Returns a UserAgeRange object from a dinctionary containing valid user age range.
  @param dictionary The dictionary containing raw user age range

  Valid user age range will consist of "min" and/or "max" values that are
  positive integers, where "min" is smaller than or equal to "max".
 */
+ (nullable instancetype)ageRangeFromDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary;

@end

NS_ASSUME_NONNULL_END
