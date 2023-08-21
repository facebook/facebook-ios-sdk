/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKAdNetworkCoarseCVRule)
@interface FBSDKSKAdNetworkCoarseCVRule : NSObject

@property (nonatomic) NSString *coarseCvValue;
@property (nonatomic, readonly, copy) NSArray<FBSDKSKAdNetworkEvent *> *events;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict;
- (BOOL)isMatchedWithRecordedCoarseEvents:(NSSet<NSString *> *)recordedCoarseEvents
                     recordedCoarseValues:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)recordedCoarseValues;

@end

NS_ASSUME_NONNULL_END

#endif
