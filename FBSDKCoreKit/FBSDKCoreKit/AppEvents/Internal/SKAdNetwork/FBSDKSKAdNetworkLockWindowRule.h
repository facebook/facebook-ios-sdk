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

NS_SWIFT_NAME(SKAdNetworkLockWindowRule)
@interface FBSDKSKAdNetworkLockWindowRule : NSObject

@property (nonatomic) NSString *lockWindowType;
@property (nonatomic) NSInteger time;
@property (nonatomic, readonly, copy) NSArray<FBSDKSKAdNetworkEvent *> *events;
@property (nonatomic) NSInteger postbackSequenceIndex;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END

#endif
