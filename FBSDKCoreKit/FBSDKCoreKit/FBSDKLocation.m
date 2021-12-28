/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLocation.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKMath.h"

NSString *const FBSDKLocationIdCodingKey = @"FBSDKLocationIdCodingKey";
NSString *const FBSDKLocationNameCodingKey = @"FBSDKLocationNameCodingKey";

@implementation FBSDKLocation

- (instancetype)initWithId:(NSString *)id
                      name:(NSString *)name
{
  if ((self = [super init])) {
    _id = id;
    _name = name;
  }

  return self;
}

+ (nullable instancetype)locationFromDictionary:(NSDictionary<NSString *, id> *)dictionary
{
  if (![FBSDKTypeUtility dictionaryValue:dictionary]) {
    return nil;
  }

  NSString *id = [FBSDKTypeUtility stringValueOrNil:dictionary[@"id"]];
  NSString *name = [FBSDKTypeUtility stringValueOrNil:dictionary[@"name"]];

  if (id == nil || name == nil) {
    return nil;
  }

  return [[FBSDKLocation alloc] initWithId:id name:name];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _id.hash,
    _name.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKLocation.class]) {
    return NO;
  }
  return [self isEqualToLocation:object];
}

- (BOOL)isEqualToLocation:(FBSDKLocation *)location
{
  return [_id isEqualToString:location.id] && [_name isEqualToString:location.name];
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
  [coder encodeObject:_id forKey:FBSDKLocationIdCodingKey];
  [coder encodeObject:_name forKey:FBSDKLocationNameCodingKey];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder
{
  NSString *id = [coder decodeObjectOfClass:NSString.class forKey:FBSDKLocationIdCodingKey];
  NSString *name = [coder decodeObjectOfClass:NSString.class forKey:FBSDKLocationNameCodingKey];

  return [self initWithId:id name:name];
}

@end
