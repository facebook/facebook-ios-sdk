/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBAEMConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBAEMConfiguration (Testing)

+ (nullable NSArray<FBAEMRule *> *)parseRules:(nullable NSArray<NSDictionary<NSString *, id> *> *)rules;

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBAEMRule *> *)rules;

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBAEMRule *> *)rules;

+ (id<FBAEMAdvertiserRuleProviding>)ruleProvider;

@end

NS_ASSUME_NONNULL_END
