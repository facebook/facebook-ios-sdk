/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKImpressionLoggerFactory.h"

#import <FBSDKCoreKit_Basics/FBSDKNotificationDelivering.h>

#import <FBSDKCoreKit/FBSDKAccessTokenProtocols.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFactory.h>

#import "FBSDKEventLogging.h"
#import "FBSDKImpressionLogging.h"
#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKImpressionLoggerFactory

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                eventLogger:(id<FBSDKEventLogging>)eventLogger
                         notificationCenter:(id<FBSDKNotificationDelivering>)notificationCenter
                          accessTokenWallet:(Class<FBSDKAccessTokenProviding>)accessTokenWallet
{
  if ((self = [super init])) {
    _graphRequestFactory = graphRequestFactory;
    _eventLogger = eventLogger;
    _notificationCenter = notificationCenter;
    _accessTokenWallet = accessTokenWallet;
  }
  return self;
}

- (id<FBSDKImpressionLogging>)makeImpressionLoggerWithEventName:(FBSDKAppEventName)eventName
{
  return [FBSDKViewImpressionLogger retrieveLoggerWith: eventName];
}

@end

NS_ASSUME_NONNULL_END
