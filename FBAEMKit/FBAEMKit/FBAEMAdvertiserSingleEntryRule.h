/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import <FBAEMKit/FBAEMAdvertiserRuleMatching.h>
 #import <FBAEMKit/FBAEMAdvertiserRuleOperator.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AEMAdvertiserSingleEntryRule)
@interface FBAEMAdvertiserSingleEntryRule : NSObject <FBAEMAdvertiserRuleMatching, NSCopying, NSSecureCoding>

@property (nonatomic, readonly, assign)FBAEMAdvertiserRuleOperator operator;
@property (nonatomic, readonly) NSString *paramKey;
@property (nullable, nonatomic, readonly) NSString *linguisticCondition;
@property (nullable, nonatomic, readonly) NSNumber *numericalCondition;
@property (nullable, nonatomic, readonly) NSArray<NSString *> *arrayCondition;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithOperator:(FBAEMAdvertiserRuleOperator)op
                        paramKey:(NSString *)paramKey
             linguisticCondition:(nullable NSString *)linguisticCondition
              numericalCondition:(nullable NSNumber *)numericalCondition
                  arrayCondition:(nullable NSArray<NSString *> *)arrayCondition;

@end

NS_ASSUME_NONNULL_END

#endif
