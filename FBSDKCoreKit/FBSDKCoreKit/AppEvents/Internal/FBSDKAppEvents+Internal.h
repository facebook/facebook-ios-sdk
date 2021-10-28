/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit/FBSDKAppEvents.h>

#import "FBSDKAppEventName.h"
#import "FBSDKAppEventsUtility.h"

NS_ASSUME_NONNULL_BEGIN

// Internally known event parameter values

FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Completed;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Failed;

FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesHandlerKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesActionKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesEventKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesParamsKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackCustomKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackSingleKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelTrackSingleCustomKey;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsWKWebViewMessagesPixelIDKey;

@interface FBSDKAppEvents (Internal)

@property (nonatomic) UIApplicationState applicationState;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(double)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged;

+ (void)logInternalEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

+ (void)logImplicitEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(nullable NSDictionary<NSString *, id> *)parameters
             accessToken:(FBSDKAccessToken *)accessToken;

- (void)flushForReason:(FBSDKAppEventsFlushReason)flushReason;
- (void)startObservingApplicationLifecycleNotifications;

@end

NS_ASSUME_NONNULL_END
