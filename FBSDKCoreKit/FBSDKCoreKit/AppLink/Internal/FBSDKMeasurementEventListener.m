/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMeasurementEventListener.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEvents+SourceApplicationTracking.h"
#import "FBSDKMeasurementEvent.h"
#import "FBSDKTimeSpentData.h"

static NSString *const FBSDKMeasurementEventName = @"event_name";
static NSString *const FBSDKMeasurementEventArgs = @"event_args";
static NSString *const FBSDKMeasurementEventPrefix = @"bf_";

@implementation FBSDKMeasurementEventListener

+ (instancetype)defaultListener
{
  static dispatch_once_t dispatchOnceLocker = 0;
  static FBSDKMeasurementEventListener *defaultListener = nil;
  dispatch_once(&dispatchOnceLocker, ^{
    defaultListener = [self new];
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:defaultListener
               selector:@selector(logFBAppEventForNotification:)
                   name:FBSDKMeasurementEventNotification
                 object:nil];
  });
  return defaultListener;
}

- (void)logFBAppEventForNotification:(NSNotification *)note
{
  // when catch al_nav_in event, we set source application for FBAppEvents.
  if ([note.userInfo[FBSDKMeasurementEventName] isEqualToString:@"al_nav_in"]) {
    NSString *sourceApplication = note.userInfo[FBSDKMeasurementEventArgs][@"sourceApplication"];
    if (sourceApplication) {
      [FBSDKAppEvents.shared setSourceApplication:sourceApplication isFromAppLink:YES];
    }
  }
  NSDictionary<NSString *, id> *eventArgs = note.userInfo[FBSDKMeasurementEventArgs];
  NSMutableDictionary<NSString *, id> *logData = [NSMutableDictionary new];
  for (NSString *key in eventArgs.allKeys) {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9a-zA-Z _-]" options:0 error:&error];
    NSString *safeKey = [regex stringByReplacingMatchesInString:key
                                                        options:0
                                                          range:NSMakeRange(0, key.length)
                                                   withTemplate:@"-"];
    safeKey = [safeKey stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -"]];
    [FBSDKTypeUtility dictionary:logData setObject:eventArgs[key] forKey:safeKey];
  }
  [FBSDKAppEvents logInternalEvent:[FBSDKMeasurementEventPrefix stringByAppendingString:note.userInfo[FBSDKMeasurementEventName]]
                        parameters:logData
                isImplicitlyLogged:YES];
}

@end

#endif
