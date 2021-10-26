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
 #import "FBAEMAdvertiserRuleProviding.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AEMAdvertiserRuleFactory)
@interface FBAEMAdvertiserRuleFactory : NSObject <FBAEMAdvertiserRuleProviding>

@end

NS_ASSUME_NONNULL_END

#endif
