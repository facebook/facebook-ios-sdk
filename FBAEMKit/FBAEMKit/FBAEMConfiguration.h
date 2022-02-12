/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import "FBAEMAdvertiserRuleMatching.h"
 #import "FBAEMAdvertiserRuleProviding.h"
 #import "FBAEMRule.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMConfiguration)
@interface FBAEMConfiguration : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, readonly, assign) NSInteger cutoffTime;

/// The UNIX timestamp of config's valid date and works as a unqiue identifier of the config
@property (nonatomic, readonly, assign) NSInteger validFrom;
@property (nonatomic, readonly, copy) NSString *defaultCurrency;
@property (nonatomic, readonly, copy) NSString *configMode;
@property (nullable, nonatomic, readonly, copy) NSString *businessID;
@property (nullable, nonatomic, readonly, copy) id<FBAEMAdvertiserRuleMatching> matchingRule;
@property (nonatomic, readonly) NSArray<FBAEMRule *> *conversionValueRules;
@property (nonatomic, readonly) NSSet<NSString *> *eventSet;
@property (nonatomic, readonly) NSSet<NSString *> *currencySet;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (void)configureWithRuleProvider:(id<FBAEMAdvertiserRuleProviding>)ruleProvider;

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict;

- (BOOL)isSameValidFrom:(NSInteger)validFrom
             businessID:(nullable NSString *)businessID;

- (BOOL)isSameBusinessID:(nullable NSString *)businessID;

@end

NS_ASSUME_NONNULL_END

#endif
