/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKMeasurementEventListener.h"

#import <FBSDKCoreKit/FBSDKMeasurementEvent.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKMeasurementEventNames.h"

static NSString *const FBSDKMeasurementEventName = @"event_name";
static NSString *const FBSDKMeasurementEventArgs = @"event_args";
static NSString *const FBSDKMeasurementEventPrefix = @"bf_";

@interface FBSDKMeasurementEventListener ()

@property (nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) id<FBSDKSourceApplicationTracking> sourceApplicationTracker;

@end

@implementation FBSDKMeasurementEventListener

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
           sourceApplicationTracker:(id<FBSDKSourceApplicationTracking>)sourceApplicationTracker
{
  if ((self = [super init])) {
    _eventLogger = eventLogger;
    _sourceApplicationTracker = sourceApplicationTracker;
  }
  return self;
}

- (void)registerForAppLinkMeasurementEvents
{
  static dispatch_once_t nonce = 0;
  dispatch_once(&nonce, ^{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(logFBAppEventForNotification:)
                   name:FBSDKMeasurementEventNotification
                 object:nil];
  });
}

- (void)logFBAppEventForNotification:(NSNotification *)notification
{
  // when catch al_nav_in event, we set source application for FBAppEvents.
  if ([notification.userInfo[FBSDKMeasurementEventName] isEqualToString:@"al_nav_in"]) {
    NSString *sourceApplication = notification.userInfo[FBSDKMeasurementEventArgs][@"sourceApplication"];
    if (sourceApplication) {
      [self.sourceApplicationTracker setSourceApplication:sourceApplication isFromAppLink:YES];
    }
  }
  NSDictionary<NSString *, id> *eventArgs = notification.userInfo[FBSDKMeasurementEventArgs];
  NSMutableDictionary<FBSDKAppEventParameterName, id> *logData = [NSMutableDictionary new];
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
  [self.eventLogger logInternalEvent:[FBSDKMeasurementEventPrefix stringByAppendingString:notification.userInfo[FBSDKMeasurementEventName]]
                          parameters:logData
                  isImplicitlyLogged:YES];
}

@end

#endif
