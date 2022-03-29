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

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AEMUtility)
@interface FBAEMUtility : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (class, nonatomic, readonly) FBAEMUtility *sharedUtility;

- (NSNumber *)getInSegmentValue:(nullable NSDictionary<NSString *, id> *)parameters
                   matchingRule:(id<FBAEMAdvertiserRuleMatching>)matchingRule;

- (nullable NSString *)getContentID:(nullable NSDictionary<NSString *, id> *)parameters;

@end

NS_ASSUME_NONNULL_END

#endif
