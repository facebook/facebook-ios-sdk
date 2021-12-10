/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

 #import "FBAEMAdvertiserRuleMatching.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMUtility)
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
