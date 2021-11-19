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
#import "FBSDKAppEventsConfiguring.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKApplicationActivating.h"
#import "FBSDKApplicationLifecycleObserving.h"
#import "FBSDKApplicationStateSetting.h"
#import "FBSDKEventLogging.h"
#import "FBSDKSourceApplicationTracking.h"
#import "FBSDKUserIDProviding.h"

NS_ASSUME_NONNULL_BEGIN

// Internally known event parameter values

FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Completed;
FOUNDATION_EXPORT NSString *const FBSDKAppEventsDialogOutcomeValue_Failed;

@interface FBSDKAppEvents (Internal) <
  FBSDKAppEventsConfiguring,
  FBSDKApplicationActivating,
  FBSDKApplicationLifecycleObserving,
  FBSDKApplicationStateSetting,
  FBSDKEventLogging,
  FBSDKSourceApplicationTracking,
  FBSDKUserIDProviding
>

@end

NS_ASSUME_NONNULL_END
