/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppEventsConfigurationProtocol)
@protocol FBSDKAppEventsConfiguration

@property (nonatomic, readonly, assign) FBSDKAdvertisingTrackingStatus defaultATEStatus;
@property (nonatomic, readonly, assign) BOOL advertiserIDCollectionEnabled;
@property (nonatomic, readonly, assign) BOOL eventCollectionEnabled;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict;
+ (instancetype)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END
