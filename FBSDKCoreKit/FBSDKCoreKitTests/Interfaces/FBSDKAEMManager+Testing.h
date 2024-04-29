/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAEMManager (Testing)

@property (class, nonatomic) FBSDKAEMManager *shared;

@property (nullable, nonatomic) Class<FBSDKAEMReporter> aemReporter;
@property (nullable, nonatomic) Class<FBSDKSwizzling> swizzler;
@property (nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) id<FBSDKCrashHandler> crashHandler;
@property (nullable, nonatomic) id<FBSDKFeatureDisabling> featureChecker;
@property (nullable, nonatomic) id<FBSDKAppEventsUtility> appEventsUtility;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
