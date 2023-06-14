/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKAEMReporter;
@protocol FBSDKAppEventsUtility;
@protocol FBSDKCrashHandler;
@protocol FBSDKEventLogging;
@protocol FBSDKFeatureDisabling;
@protocol FBSDKSwizzling;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AutoSetup)
@protocol FBSDKAutoSetup

- (void)configureWithSwizzler:(nonnull Class<FBSDKSwizzling>)swizzler
                  aemReporter:(nonnull Class<FBSDKAEMReporter>)aemReporter
                  eventLogger:(nonnull id<FBSDKEventLogging>)eventLogger
                 crashHandler:(nonnull id<FBSDKCrashHandler>)crashHandler
               featureChecker:(nonnull id<FBSDKFeatureDisabling>)featureChecker
             appEventsUtility:(nonnull id<FBSDKAppEventsUtility>)appEventsUtility
NS_SWIFT_NAME(configure(swizzler:reporter:eventLogger:crashHandler:featureChecker:appEventsUtility:));

- (void)enableAutoSetup:(BOOL)proxyEnabled;

- (void)logAutoSetupStatus:(BOOL)optin
                    source:(NSString *)source;

@end

NS_ASSUME_NONNULL_END
