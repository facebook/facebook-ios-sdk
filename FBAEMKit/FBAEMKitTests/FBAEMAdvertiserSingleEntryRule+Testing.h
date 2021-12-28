/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBAEMAdvertiserSingleEntryRule.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBAEMAdvertiserSingleEntryRule (Testing)

- (BOOL)isMatchedWithStringValue:(nullable NSString *)stringValue
                  numericalValue:(nullable NSNumber *)numericalValue;

- (BOOL)isMatchedWithAsteriskParam:(NSString *)param
                   eventParameters:(NSDictionary<NSString *, id> *)eventParams
                         paramPath:(NSArray<NSString *> *)paramPath;

- (BOOL)isRegexMatch:(NSString *)stringValue;

- (BOOL)isAnyOf:(NSArray<NSString *> *)arrayCondition
    stringValue:(NSString *)stringValue
     ignoreCase:(BOOL)ignoreCase;

- (void)setOperator:(FBAEMAdvertiserRuleOperator)op;

@end

NS_ASSUME_NONNULL_END
