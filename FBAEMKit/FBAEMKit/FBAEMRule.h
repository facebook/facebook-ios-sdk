/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

 #import <Foundation/Foundation.h>

@class FBAEMEvent;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AEMRule)
@interface FBAEMRule : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic) NSInteger conversionValue;
@property (nonatomic) NSInteger priority;
@property (nonatomic, copy) NSArray<FBAEMEvent *> *events;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict;

- (BOOL)containsEvent:(NSString *)event;

- (BOOL)isMatchedWithRecordedEvents:(nullable NSSet<NSString *> *)recordedEvents
                     recordedValues:(nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)recordedValues;

@end

NS_ASSUME_NONNULL_END

#endif
