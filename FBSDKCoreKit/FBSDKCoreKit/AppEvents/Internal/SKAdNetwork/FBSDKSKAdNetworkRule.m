/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdNetworkRule.h"
#import "FBSDKSKAdnetworkUtils.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdNetworkRule

- (nullable instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    NSNumber *value = [FBSDKTypeUtility dictionary:dict objectForKey:@"conversion_value" ofType:NSNumber.class];
    NSArray<FBSDKSKAdNetworkEvent *> *events = [FBSDKSKAdnetworkUtils parseEvents:[FBSDKTypeUtility dictionary:dict objectForKey:@"events" ofType:NSArray.class]];
    if (value == nil || !events) {
      return nil;
    }
    _conversionValue = value.integerValue;
    _events = events;
  }
  return self;
}

- (BOOL)isMatchedWithRecordedEvents:(NSSet<NSString *> *)recordedEvents
                     recordedValues:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)recordedValues
{
  for (FBSDKSKAdNetworkEvent *event in self.events) {
    // Check if event name matches
    if (![recordedEvents containsObject:event.eventName]) {
      return NO;
    }
    // Check if event value matches when values is not nil
    if (event.values) {
      NSDictionary<NSString *, NSNumber *> *recordedEventValues = [FBSDKTypeUtility dictionary:recordedValues objectForKey:event.eventName ofType:NSDictionary.class];
      if (!recordedEventValues) {
        return NO;
      }
      if (![self isValueMatchedWithEvent:event recordedEventValues:recordedEventValues]) {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)isValueMatchedWithEvent:(FBSDKSKAdNetworkEvent *)event recordedEventValues:(NSDictionary<NSString *, NSNumber *> *)recordedEventValues
{
  for (NSString *currency in event.values) {
    NSNumber *valueInMapping = [FBSDKTypeUtility dictionary:event.values objectForKey:currency ofType:NSNumber.class];
    NSNumber *value = [FBSDKTypeUtility dictionary:recordedEventValues objectForKey:currency ofType:NSNumber.class];
    if (value != nil && valueInMapping != nil && value.doubleValue > valueInMapping.doubleValue) {
      return YES;
    }
  }
  return NO;
}

@end

#endif
