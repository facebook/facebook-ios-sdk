/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKHasher : NSObject

+ (NSUInteger)hashWithInteger:(NSUInteger)value;
+ (NSUInteger)hashWithInteger:(NSUInteger)value1 andInteger:(NSUInteger)value2;
+ (NSUInteger)hashWithIntegerArray:(NSUInteger *)values count:(NSUInteger)count;
+ (NSUInteger)hashWithLong:(unsigned long long)value;

@end

NS_ASSUME_NONNULL_END
