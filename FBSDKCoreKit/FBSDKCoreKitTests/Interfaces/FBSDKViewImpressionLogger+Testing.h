/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKViewImpressionLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKViewImpressionLogger (Testing)

@property (nonatomic, assign) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, assign) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, strong) id<FBSDKNotificationObserving> notificationObserver;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> tokenWallet;

+ (void)reset;
- (NSSet<NSDateFormatter *> *)trackedImpressions;
- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
