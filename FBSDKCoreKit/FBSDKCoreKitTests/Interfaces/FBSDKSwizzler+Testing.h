/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSwizzler.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKSwizzler (Testing)

+ (void)swizzleSelector:(SEL)aSelector
                onClass:(Class)aClass
              withBlock:(swizzleBlock)aBlock
                  named:(nullable NSString *)aName
                  async:(BOOL)async;

@end

NS_ASSUME_NONNULL_END
