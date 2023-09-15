/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKSKAdNetworkLockWindowRule.h"
#import "FBSDKSKAdNetworkCoarseCVConfig.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKAdNetworkConversionConfiguration)
@interface FBSDKSKAdNetworkConversionConfiguration : NSObject

@property (nonatomic, readonly, assign) NSInteger timerBuckets;
@property (nonatomic, readonly, assign) NSTimeInterval timerInterval;
@property (nonatomic, readonly, assign) NSInteger cutoffTime;
@property (nonatomic, readonly, copy) NSString *defaultCurrency;
@property (nonatomic, readonly, copy) NSArray<FBSDKSKAdNetworkRule *> *conversionValueRules;
@property (nonatomic, readonly, copy) NSSet<NSString *> *eventSet;
@property (nonatomic, readonly, copy) NSSet<NSString *> *currencySet;
@property (nonatomic, readonly, copy) NSSet<NSString *> *coarseEventSet;
@property (nonatomic, readonly, copy) NSSet<NSString *> *coarseCurrencySet;
@property (nullable, nonatomic, readonly, copy) NSArray<FBSDKSKAdNetworkLockWindowRule *> *lockWindowRules;
@property (nullable, nonatomic, readonly, copy) NSArray<FBSDKSKAdNetworkCoarseCVConfig *> *coarseCvConfigs;
@property (nonatomic, readonly, assign) Boolean isCoarseCVAccumulative;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

#endif
