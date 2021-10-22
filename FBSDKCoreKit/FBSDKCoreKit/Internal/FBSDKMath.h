/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKMath : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (CGSize)ceilForSize:(CGSize)value;
+ (CGSize)floorForSize:(CGSize)value;
+ (NSUInteger)hashWithInteger:(NSUInteger)value;
+ (NSUInteger)hashWithIntegerArray:(NSUInteger *)values count:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
