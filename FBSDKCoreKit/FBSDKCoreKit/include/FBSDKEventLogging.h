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
#import <FBSDKCoreKit/FBSDKAppOperationalDataType.h>
#import <FBSDKCoreKit/FBSDKAppEventsFlushReason.h>
#import <FBSDKCoreKit/FBSDKAppEventsFlushBehavior.h>

@class FBSDKAccessToken;


/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EventLogging)
@protocol FBSDKEventLogging

@property (nonatomic, readonly) FBSDKAppEventsFlushBehavior flushBehavior;

- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;

- (void)logEvent:(FBSDKAppEventName)eventName
      parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

- (void)logEvent:(FBSDKAppEventName)eventName
      valueToSum:(double)valueToSum
      parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters;

- (void)logEvent:(FBSDKAppEventName)eventName
      valueToSum:(nullable NSNumber *)valueToSum
      parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
     accessToken:(nullable FBSDKAccessToken *)accessToken;

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

- (void)doLogEvent:(FBSDKAppEventName)eventName
          valueToSum:(nullable NSNumber *)valueToSum
          parameters:(nullable NSDictionary<FBSDKAppEventParameterName, id> *)parameters
  isImplicitlyLogged:(BOOL)isImplicitlyLogged
           accessToken:(nullable FBSDKAccessToken *)accessToken
operationalParameters:(nullable NSDictionary<FBSDKAppOperationalDataType, NSDictionary<NSString *, id> *> *)operationalParameters;

@end

NS_ASSUME_NONNULL_END
