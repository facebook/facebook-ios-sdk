/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKShareMediaContent.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKSharingContent.h"
#import "_FBSDKShareUtilityProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ShareUtility)
@interface _FBSDKShareUtility : NSObject <_FBSDKShareUtility>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (void)assertCollection:(id<NSFastEnumeration>)collection ofClass:itemClass name:(NSString *)name;
+ (void)assertCollection:(id<NSFastEnumeration>)collection ofClassStrings:(NSArray<NSString *> *)classStrings name:(NSString *)name;
+ (nullable NSString *)buildWebShareTags:(nullable NSArray<NSString *> *)peopleIDs;
+ (nullable NSDictionary<NSString *, id> *)convertPhoto:(nullable FBSDKSharePhoto *)photo;
+ (nullable UIImage *)imageWithCircleColor:(nullable UIColor *)color
                                canvasSize:(CGSize)canvasSize
                                circleSize:(CGSize)circleSize;
+ (BOOL)validateArgumentWithName:(NSString *)argumentName
                           value:(NSUInteger)value
                            isIn:(NSArray<NSNumber *> *)possibleValues
                           error:(NSError *_Nullable *)errorRef;
+ (BOOL)validateArray:(NSArray<id> *)array
             minCount:(NSUInteger)minCount
             maxCount:(NSUInteger)maxCount
                 name:(NSString *)name
                error:(NSError *_Nullable *)errorRef;
+ (BOOL)validateNetworkURL:(NSURL *)URL name:(NSString *)name error:(NSError *_Nullable *)errorRef;
+ (BOOL)validateRequiredValue:(id)value name:(NSString *)name error:(NSError *_Nullable *)errorRef;

@end

NS_ASSUME_NONNULL_END
