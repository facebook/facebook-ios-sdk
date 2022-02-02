/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

NS_ASSUME_NONNULL_BEGIN

/// Describes anything that can provide instances of `AEMAdvertiserRuleMatching`
NS_SWIFT_NAME(AEMAdvertiserRuleProviding)
@protocol FBAEMAdvertiserRuleProviding

- (nullable id<FBAEMAdvertiserRuleMatching>)createRuleWithJson:(nullable NSString *)json;

- (nullable id<FBAEMAdvertiserRuleMatching>)createRuleWithDict:(NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

#endif
