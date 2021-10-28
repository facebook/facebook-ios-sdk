/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKUserAgeRange.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKMath.h"

NSString *const FBSDKUserAgeRangeMinCodingKey = @"FBSDKUserAgeRangeMinCodingKey";
NSString *const FBSDKUserAgeRangeMaxCodingKey = @"FBSDKUserAgeRangeMaxCodingKey";

@implementation FBSDKUserAgeRange

- (instancetype)initMin:(NSNumber *)min
                    max:(NSNumber *)max
{
  if ((self = [super init])) {
    _min = min;
    _max = max;
  }

  return self;
}

+ (nullable instancetype)ageRangeFromDictionary:(NSDictionary<NSString *, id> *)dictionary
{
  if (![FBSDKTypeUtility dictionaryValue:dictionary]) {
    return nil;
  }

  NSNumber *min = [FBSDKTypeUtility numberValue:dictionary[@"min"]];
  NSNumber *max = [FBSDKTypeUtility numberValue:dictionary[@"max"]];

  if ((min == nil && max == nil)
      || (min != nil && min.longValue < 0)
      || (max != nil && max.longValue < 0)
      || (min != nil && max != nil && min.longValue >= max.longValue)) {
    return nil;
  }

  return [[FBSDKUserAgeRange alloc] initMin:min max:max];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _min.hash,
    _max.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKUserAgeRange.class]) {
    return NO;
  }
  return [self isEqualToUserAgeRange:object];
}

- (BOOL)isEqualToUserAgeRange:(FBSDKUserAgeRange *)ageRange
{
  return (_max == ageRange.max) && (_min == ageRange.min);
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  // we're immutable.
  return self;
}

#pragma mark NSCoding
+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
  [coder encodeObject:_min forKey:FBSDKUserAgeRangeMinCodingKey];
  [coder encodeObject:_max forKey:FBSDKUserAgeRangeMaxCodingKey];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder
{
  NSNumber *min = [coder decodeObjectOfClass:NSNumber.class forKey:FBSDKUserAgeRangeMinCodingKey];
  NSNumber *max = [coder decodeObjectOfClass:NSNumber.class forKey:FBSDKUserAgeRangeMaxCodingKey];

  return [self initMin:min max:max];
}

@end
