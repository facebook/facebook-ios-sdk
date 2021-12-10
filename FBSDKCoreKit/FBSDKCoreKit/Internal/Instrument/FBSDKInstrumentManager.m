/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKInstrumentManager.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKErrorReporting.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKSettingsProtocol.h"

@interface FBSDKInstrumentManager ()

@property (nonatomic, strong) id<FBSDKFeatureChecking> featureChecker;
@property (nonatomic, strong) id<FBSDKSettings> settings;
@property (nonatomic, strong) id<FBSDKCrashObserving> crashObserver;
@property (nonatomic, strong) id<FBSDKErrorReporting> errorReporter;
@property (nonatomic, strong) id<FBSDKCrashHandler> crashHandler;

@end

@implementation FBSDKInstrumentManager

- (void)configureWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                           settings:(id<FBSDKSettings>)settings
                      crashObserver:(id<FBSDKCrashObserving>)crashObserver
                      errorReporter:(id<FBSDKErrorReporting>)errorReporter
                       crashHandler:(id<FBSDKCrashHandler>)crashHandler
{
  _featureChecker = featureChecker;
  _settings = settings;
  _crashObserver = crashObserver;
  _errorReporter = errorReporter;
  _crashHandler = crashHandler;
}

static FBSDKInstrumentManager *sharedInstance;
static dispatch_once_t sharedInstanceNonce;
+ (instancetype)shared
{
  dispatch_once(&sharedInstanceNonce, ^{
    sharedInstance = [self new];
  });
  return sharedInstance;
}

- (void)enable
{
  if (![self.settings isAutoLogAppEventsEnabled]) {
    return;
  }

  [self.featureChecker checkFeature:FBSDKFeatureCrashReport completionBlock:^(BOOL enabled) {
    if (enabled) {
      [self.crashHandler addObserver:self.crashObserver];
    }
  }];
  [self.featureChecker checkFeature:FBSDKFeatureErrorReport completionBlock:^(BOOL enabled) {
    if (enabled) {
      [self.errorReporter enable];
    }
  }];
}

#if DEBUG && FBTEST

+ (void)reset
{
  // Reset the shared instance nonce.
  if (sharedInstanceNonce) {
    sharedInstanceNonce = 0;
  }
}

#endif

@end
