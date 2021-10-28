/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBAEMEvent : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, copy) NSString *eventName;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> *values;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

#endif
