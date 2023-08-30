/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdNetworkCoarseCVRule.h"
#import "FBSDKSKAdnetworkUtils.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdNetworkCoarseCVRule

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    NSString *coarseCvValue = [FBSDKTypeUtility dictionary:dict objectForKey:@"coarse_cv_value" ofType:NSString.class];
    NSArray<FBSDKSKAdNetworkEvent *> *events = [FBSDKSKAdnetworkUtils parseEvents:[FBSDKTypeUtility dictionary:dict objectForKey:@"events" ofType:NSArray.class]];
    if (coarseCvValue == nil || coarseCvValue.length == 0 || !events || events.count == 0) {
      return nil;
    }
    _coarseCvValue = coarseCvValue;
    _events = events;
  }
  return self;
}

- (BOOL)isMatchedWithRecordedCoarseEvents:(NSSet<NSString *> *)recordedCoarseEvents
                     recordedCoarseValues:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)recordedCoarseValues
{
  for (FBSDKSKAdNetworkEvent *event in self.events) {
    // Check if event name matches
    if (![recordedCoarseEvents containsObject:event.eventName]) {
      return NO;
    }
    // Check if event value matches when values is not nil
    if (event.values) {
      NSDictionary<NSString *, NSNumber *> *recordedCoarseEventValues = [FBSDKTypeUtility dictionary:recordedCoarseValues objectForKey:event.eventName ofType:NSDictionary.class];
      if (!recordedCoarseEventValues) {
        return NO;
      }
      for (NSString *currency in event.values) {
        NSNumber *valueInMapping = [FBSDKTypeUtility dictionary:event.values objectForKey:currency ofType:NSNumber.class];
        NSNumber *value = [FBSDKTypeUtility dictionary:recordedCoarseEventValues objectForKey:currency ofType:NSNumber.class];
        if (value != nil && valueInMapping != nil && value.doubleValue > valueInMapping.doubleValue) {
          return YES;
        }
      }
      return NO;
    }
  }
  return YES;
}

@end

#endif
