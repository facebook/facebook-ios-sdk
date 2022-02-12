/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMeasurementEvent+Internal.h"

#import "FBSDKLogger.h"
#import "FBSDKMeasurementEventNames.h"

NSNotificationName const FBSDKMeasurementEventNotification = @"com.facebook.facebook-objc-sdk.measurement_event";

NSString *const FBSDKMeasurementEventNotificationName = @"com.facebook.facebook-objc-sdk.measurement_event";

NSString *const FBSDKMeasurementEventNameKey = @"event_name";
NSString *const FBSDKMeasurementEventArgsKey = @"event_args";

/// app Link Event raised by this FBSDKURL
NSString *const FBSDKAppLinkParseEventName = @"al_link_parse";
NSString *const FBSDKAppLinkNavigateInEventName = @"al_nav_in";

/// AppLink events raised in this class
NSString *const FBSDKAppLinkNavigateOutEventName = @"al_nav_out";
NSString *const FBSDKAppLinkNavigateBackToReferrerEventName = @"al_ref_back_out";

@implementation FBSDKMeasurementEvent

- (void)postNotificationForEventName:(NSString *)name
                                args:(NSDictionary<NSString *, id> *)args
{
  if (!name) {
    [FBSDKLogger
     singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
     logEntry:@"Warning: Missing event name when logging FBSDK measurement event.\nIgnoring this event in logging."];
    return;
  }
  NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
  NSDictionary<NSString *, id> *userInfo = @{FBSDKMeasurementEventNameKey : name,
                                             FBSDKMeasurementEventArgsKey : args};

  [center postNotificationName:FBSDKMeasurementEventNotification
                        object:self
                      userInfo:userInfo];
}

+ (void)postNotificationForEventName:(NSString *)name
                                args:(NSDictionary<NSString *, id> *)args
{
  [[self new] postNotificationForEventName:name args:args ?: @{}];
}

@end

#endif
