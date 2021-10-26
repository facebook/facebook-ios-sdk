/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKAdNetworkEvent)
@interface FBSDKSKAdNetworkEvent : NSObject

@property (nonatomic, readonly, copy) NSString *eventName;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, NSNumber *> *values;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

#endif
