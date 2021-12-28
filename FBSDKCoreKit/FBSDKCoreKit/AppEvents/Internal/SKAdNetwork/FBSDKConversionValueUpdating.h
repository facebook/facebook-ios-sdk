/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/// An internal protocol used to describe a type that can update a value
NS_SWIFT_NAME(ConversionValueUpdating)
@protocol FBSDKConversionValueUpdating

+ (void)updateConversionValue:(NSInteger)conversionValue;

@end

NS_ASSUME_NONNULL_END
