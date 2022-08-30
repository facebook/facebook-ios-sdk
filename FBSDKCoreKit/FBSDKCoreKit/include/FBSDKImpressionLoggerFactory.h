/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKImpressionLoggerFactoryProtocol.h>
#import <FBSDKCoreKit_Basics/FBSDKNotificationDelivering.h>

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKEventLogging;
@protocol FBSDKNotificationDelivering;
@protocol FBSDKAccessTokenProviding;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_ImpressionLoggerFactory)
@interface FBSDKImpressionLoggerFactory : NSObject <FBSDKImpressionLoggerFactory>

@property (nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) id<FBSDKNotificationDelivering> notificationCenter;
@property (nonatomic, readonly) Class<FBSDKAccessTokenProviding> accessTokenWallet;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithGraphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestFactory
                                eventLogger:(nonnull id<FBSDKEventLogging>)eventLogger
                         notificationCenter:(nonnull id<FBSDKNotificationDelivering>)notificationCenter
                          accessTokenWallet:(nonnull Class<FBSDKAccessTokenProviding>)accessTokenWallet
  NS_DESIGNATED_INITIALIZER
  NS_SWIFT_NAME(init(graphRequestFactory:eventLogger:notificationCenter:accessTokenWallet:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
