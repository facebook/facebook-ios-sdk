/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKSwizzling.h>
#import <Foundation/Foundation.h>

// Cast to turn things that are not ids into NSMapTable keys
#define MAPTABLE_ID(x) (__bridge id)((void *)x)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef void (^_swizzleBlock)();

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_Swizzler)
@interface FBSDKSwizzler : NSObject <FBSDKSwizzling>

+ (void)swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(_swizzleBlock)block named:(NSString *)aName;
+ (void)unswizzleSelector:(SEL)aSelector onClass:(Class)aClass named:(NSString *)aName;
+ (void)printSwizzles;

@end

NS_ASSUME_NONNULL_END
