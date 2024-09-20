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

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ConversionValueUpdating)
@protocol FBSDKConversionValueUpdating

+ (void)updateConversionValue:(NSInteger)conversionValue;
+ (void)updateCoarseConversionValue:(NSString *)coarseConversionValue;
+ (void)updatePostbackConversionValue:(NSInteger)conversionValue
                    completionHandler:(nullable void (^)(NSError *__nullable error))completion API_AVAILABLE(ios(15.4));
+ (void)updatePostbackConversionValue:(NSInteger)fineValue
                          coarseValue:(SKAdNetworkCoarseConversionValue)coarseValue
                    completionHandler:(nullable void (^)(NSError *__nullable error))completion API_AVAILABLE(ios(16.1));
+ (void)updatePostbackConversionValue:(NSInteger)fineValue
                          coarseValue:(SKAdNetworkCoarseConversionValue)coarseValue
                           lockWindow:(BOOL)lockWindow
                    completionHandler:(nullable void (^)(NSError *__nullable error))completion API_AVAILABLE(ios(16.1));

@end

/**
 Internal conformance exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@interface SKAdNetwork (ConversionValueUpdating) <FBSDKConversionValueUpdating>

@end

NS_ASSUME_NONNULL_END
