/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKFeatureChecking;
@protocol FBSDKSettings;
@protocol FBSDKCrashObserving;
@protocol FBSDKErrorReporting;
@protocol FBSDKCrashHandler;

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_InstrumentManager)
@interface FBSDKInstrumentManager : NSObject

@property (class, nonatomic, readonly) FBSDKInstrumentManager *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

// UNCRUSTIFY_FORMAT_OFF
- (void)configureWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                           settings:(id<FBSDKSettings>)settings
                      crashObserver:(id<FBSDKCrashObserving>)crashObserver
                      errorReporter:(id<FBSDKErrorReporting>)errorReporter
                       crashHandler:(id<FBSDKCrashHandler>)crashHandler
NS_SWIFT_NAME(configure(featureChecker:settings:crashObserver:errorReporter:crashHandler:));
// UNCRUSTIFY_FORMAT_ON

- (void)enable;

@end

NS_ASSUME_NONNULL_END
