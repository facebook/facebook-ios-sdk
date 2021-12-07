/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBAEMAdvertiserMultiEntryRule.h"
#import "FBAEMAdvertiserRuleFactory.h"
#import "FBAEMAdvertiserSingleEntryRule.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBAEMAdvertiserRuleFactory (Testing)

- (nullable FBAEMAdvertiserMultiEntryRule *)createMultiEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict;

- (nullable FBAEMAdvertiserSingleEntryRule *)createSingleEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict;

- (nullable NSString *)primaryKeyForRule:(NSDictionary<NSString *, id> *)rule;

- (FBAEMAdvertiserRuleOperator)getOperator:(NSDictionary<NSString *, id> *)rule;

- (BOOL)isOperatorForMultiEntryRule:(FBAEMAdvertiserRuleOperator)op;

@end

NS_ASSUME_NONNULL_END
