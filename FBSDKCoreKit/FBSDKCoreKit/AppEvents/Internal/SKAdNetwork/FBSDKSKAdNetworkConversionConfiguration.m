/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSKAdNetworkConversionConfiguration.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@implementation FBSDKSKAdNetworkConversionConfiguration

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    @try {
      dict = [FBSDKTypeUtility dictionaryValue:dict];
      if (!dict) {
        return nil;
      }
      NSArray<id> *data = [FBSDKTypeUtility dictionary:dict objectForKey:@"data" ofType:NSArray.class];
      NSDictionary<NSString *, id> *conversionRules = [FBSDKTypeUtility dictionaryValue:[FBSDKTypeUtility array:data objectAtIndex:0]];
      if (!conversionRules) {
        return nil;
      }
      _timerBuckets = [FBSDKTypeUtility integerValue:conversionRules[@"timer_buckets"]];
      _timerInterval = (NSTimeInterval)[FBSDKTypeUtility integerValue:conversionRules[@"timer_interval"]];
      _cutoffTime = [FBSDKTypeUtility integerValue:conversionRules[@"cutoff_time"]];
      _defaultCurrency = [[FBSDKTypeUtility coercedToStringValue:conversionRules[@"default_currency"]] uppercaseString];
      _conversionValueRules = [FBSDKSKAdNetworkConversionConfiguration parseRules:conversionRules[@"conversion_value_rules"]];
      if (!_conversionValueRules || !_defaultCurrency) {
        return nil;
      }
      _eventSet = [FBSDKSKAdNetworkConversionConfiguration getEventSetFromRules:_conversionValueRules];
      _currencySet = [FBSDKSKAdNetworkConversionConfiguration getCurrencySetFromRules:_conversionValueRules];
    } @catch (NSException *exception) {
      return nil;
    }
  }
  return self;
}

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBSDKSKAdNetworkRule *> *)rules
{
  NSMutableSet<NSString *> *eventSet = [NSMutableSet new];
  for (FBSDKSKAdNetworkRule *rule in rules) {
    if (!rule) {
      continue;
    }
    for (FBSDKSKAdNetworkEvent *event in rule.events) {
      if (event.eventName) {
        [eventSet addObject:event.eventName];
      }
    }
  }
  return [eventSet copy];
}

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBSDKSKAdNetworkRule *> *)rules
{
  NSMutableSet<NSString *> *currencySet = [NSMutableSet new];
  for (FBSDKSKAdNetworkRule *rule in rules) {
    if (!rule) {
      continue;
    }
    for (FBSDKSKAdNetworkEvent *event in rule.events) {
      for (NSString *currency in event.values) {
        [currencySet addObject:[currency uppercaseString]];
      }
    }
  }
  return [currencySet copy];
}

+ (nullable NSArray<FBSDKSKAdNetworkRule *> *)parseRules:(nullable NSArray<id> *)rules
{
  rules = [FBSDKTypeUtility arrayValue:rules];
  if (!rules) {
    return nil;
  }
  NSMutableArray<FBSDKSKAdNetworkRule *> *parsedRules = [NSMutableArray new];
  for (id ruleEntry in rules) {
    FBSDKSKAdNetworkRule *rule = [[FBSDKSKAdNetworkRule alloc] initWithJSON:ruleEntry];
    [FBSDKTypeUtility array:parsedRules addObject:rule];
  }
  [parsedRules sortUsingComparator:^NSComparisonResult (FBSDKSKAdNetworkRule *obj1, FBSDKSKAdNetworkRule *obj2) {
    if (obj1.conversionValue < obj2.conversionValue) {
      return NSOrderedDescending;
    }
    if (obj1.conversionValue > obj2.conversionValue) {
      return NSOrderedAscending;
    }
    return NSOrderedSame;
  }];
  return [parsedRules copy];
}

@end

#endif
