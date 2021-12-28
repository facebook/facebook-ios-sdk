/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

typedef void (^swizzleBlock)();

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Swizzling)
@protocol FBSDKSwizzling

+ (void)swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(swizzleBlock)block named:(NSString *)aName;

@end

NS_ASSUME_NONNULL_END
