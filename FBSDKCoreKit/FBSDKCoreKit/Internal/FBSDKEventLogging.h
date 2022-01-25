/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAppEventName.h>
#import <FBSDKCoreKit/FBSDKAppEventParameterName.h>
#import <FBSDKCoreKit/FBSDKAppEventsFlushBehavior.h>

@class FBSDKAccessToken;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EventLogging)
@protocol FBSDKEventLogging

@property (nonatomic, readonly) FBSDKAppEventsFlushBehavior flushBehavior;

- (void)flushForReason:(NSUInteger)flushReason;

- (void)logEvent:(FBSDKAppEventName)eventName
      parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

- (void)logEvent:(FBSDKAppEventName)eventName
      valueToSum:(double)valueToSum
      parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

- (void)logInternalEvent:(FBSDKAppEventName)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

- (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

- (void)logInternalEvent:(FBSDKAppEventName)eventName
              parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(nullable FBSDKAccessToken *)accessToken;

- (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

@end

NS_ASSUME_NONNULL_END
