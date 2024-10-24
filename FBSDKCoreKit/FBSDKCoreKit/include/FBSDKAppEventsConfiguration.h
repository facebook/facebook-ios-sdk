/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAdvertisingTrackingStatus.h>
#import <FBSDKCoreKit/FBSDKAppEventsConfigurationProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsConfiguration)
@interface FBSDKAppEventsConfiguration : NSObject <NSCopying, NSObject, NSSecureCoding, FBSDKAppEventsConfiguration>

@property (nonatomic, readonly, assign) FBSDKAdvertisingTrackingStatus defaultATEStatus;
@property (nonatomic, readonly, assign) BOOL advertiserIDCollectionEnabled;
@property (nonatomic, readonly, assign) BOOL eventCollectionEnabled;
@property (nonatomic, readonly, assign) UInt64 iapObservationTime;
@property (nonatomic, readonly, assign) UInt64 iapManualAndAutoLogDedupWindow;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSArray<NSString *>*> * iapProdDedupConfiguration;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSArray<NSString *>*> * iapTestDedupConfiguration;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict;

+ (instancetype)defaultConfiguration;

@end

NS_ASSUME_NONNULL_END
