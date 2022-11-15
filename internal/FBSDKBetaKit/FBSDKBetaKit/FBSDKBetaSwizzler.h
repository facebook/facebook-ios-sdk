// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

// Cast to turn things that are not ids into NSMapTable keys
#define MAPTABLE_ID(x) (__bridge id)((void *)(x))

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

typedef void (^swizzleBlock)();

#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

// Rename to avoid duplicate symbol errors
NS_SWIFT_NAME(Swizzler)
@interface FBSDKBetaSwizzler : NSObject

+ (void)swizzleSelector:(SEL)aSelector onClass:(Class)aClass withBlock:(swizzleBlock)block named:(NSString *)aName;
+ (void)unswizzleSelector:(SEL)aSelector onClass:(Class)aClass named:(NSString *)aName;
+ (void)printSwizzles;

@end

NS_ASSUME_NONNULL_END
