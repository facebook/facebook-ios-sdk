/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Location)
@interface FBSDKLocation : NSObject <NSCopying, NSObject, NSSecureCoding>

/**
  Location id
 */
@property (nonatomic, readonly, strong) NSString *id;
/**
  Location name
 */
@property (nonatomic, readonly, strong) NSString *name;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Returns a Location object from a dinctionary containing valid location information.
  @param dictionary The dictionary containing raw location

  Valid location will consist of "id" and "name" strings.
 */
+ (nullable instancetype)locationFromDictionary:(NSDictionary<NSString *, NSString *> *)dictionary;

@end

NS_ASSUME_NONNULL_END
