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

NS_ASSUME_NONNULL_BEGIN

@protocol FBAEMAdvertiserRuleMatching <NSObject>

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams;

@end

NS_ASSUME_NONNULL_END

#endif
