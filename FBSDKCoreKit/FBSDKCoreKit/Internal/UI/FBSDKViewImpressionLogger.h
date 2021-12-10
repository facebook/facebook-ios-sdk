/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKAppEventName.h>

#import "FBSDKImpressionLogging.h"

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKEventLogging;
@protocol FBSDKNotificationObserving;
@protocol FBSDKAccessTokenProviding;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ViewImpressionLogger)
@interface FBSDKViewImpressionLogger : NSObject <FBSDKImpressionLogging>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)impressionLoggerWithEventName:(FBSDKAppEventName)eventName
                          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                  eventLogger:(id<FBSDKEventLogging>)eventLogger
                         notificationObserver:(id<FBSDKNotificationObserving>)notificationObserver
                                  tokenWallet:(Class<FBSDKAccessTokenProviding>)tokenWallet;

@property (nonatomic, readonly, copy) FBSDKAppEventName eventName;

- (void)logImpressionWithIdentifier:(NSString *)identifier parameters:(nullable NSDictionary<NSString *, id> *)parameters;

@end

NS_ASSUME_NONNULL_END
