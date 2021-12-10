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

 #import "FBAEMEvent.h"

NS_ASSUME_NONNULL_BEGIN

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
