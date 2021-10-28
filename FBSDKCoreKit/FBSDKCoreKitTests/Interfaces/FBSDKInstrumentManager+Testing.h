/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKErrorReporting.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKInstrumentManager (Testing)

@property (nullable, nonatomic, strong) id<FBSDKFeatureChecking> featureChecker;
@property (nullable, nonatomic, strong) id<FBSDKSettings> settings;
@property (nullable, nonatomic, strong) id<FBSDKCrashObserving> crashObserver;
@property (nullable, nonatomic, strong) id<FBSDKErrorReporting> errorReporter;
@property (nullable, nonatomic, strong) id<FBSDKCrashHandler> crashHandler;

+ (void)reset;

@end

NS_ASSUME_NONNULL_END
