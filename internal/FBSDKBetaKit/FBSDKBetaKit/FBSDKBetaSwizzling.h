// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

typedef void (^swizzleBlock)();

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Swizzling)
@protocol FBSDKBetaSwizzling

+ (void)swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(swizzleBlock)block named:(NSString *)aName;

@end

NS_ASSUME_NONNULL_END
