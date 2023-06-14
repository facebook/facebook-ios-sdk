/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKAutoSetup.h>

@protocol FBSDKSwizzling;
@protocol FBSDKAEMReporter;
@protocol FBSDKAutoSetup;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AEMManager)
@interface FBSDKAEMManager : NSObject <FBSDKAutoSetup>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/// The shared instance of AEMManager.
@property (class, nonatomic, readonly, strong) FBSDKAEMManager *shared;

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
