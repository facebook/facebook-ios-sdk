/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import "FBSDKSKAdNetworkEvent.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKAdNetworkRule)
@interface FBSDKSKAdNetworkRule : NSObject

@property (nonatomic) NSInteger conversionValue;
@property (nonatomic, copy) NSArray<FBSDKSKAdNetworkEvent *> *events;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict;

- (BOOL)isMatchedWithRecordedEvents:(NSSet<NSString *> *)recordedEvents
                     recordedValues:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)recordedValues;

@end

NS_ASSUME_NONNULL_END

#endif
