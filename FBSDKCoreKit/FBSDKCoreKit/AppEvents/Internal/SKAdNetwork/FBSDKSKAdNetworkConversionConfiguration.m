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
      NSDictionary<NSString *, id> *conversionRules = [FBSDKTypeUtility dictionaryValue:data.firstObject];
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
      _lockWindowRules = [FBSDKSKAdNetworkConversionConfiguration parseLockWindowRules:conversionRules[@"lock_window_rules"]];
      _coarseCvConfigs = [FBSDKSKAdNetworkConversionConfiguration parseCoarseCvConfigs:conversionRules[@"coarse_cv_configs"]];
      _isCoarseCVAccumulative = [FBSDKTypeUtility boolValue:conversionRules[@"is_coarse_cv_accumulative"]];
      _eventSet = [FBSDKSKAdNetworkConversionConfiguration getEventSetFromRules:_conversionValueRules];
      _currencySet = [FBSDKSKAdNetworkConversionConfiguration getCurrencySetFromRules:_conversionValueRules];
      _coarseEventSet = [FBSDKSKAdNetworkConversionConfiguration getEventSetFromCoarseConfigs:_coarseCvConfigs];
      _coarseCurrencySet = [FBSDKSKAdNetworkConversionConfiguration getCurrencySetFromCoarseConfigs:_coarseCvConfigs];
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

+ (NSSet<NSString *> *)getEventSetFromCoarseConfigs:(nullable NSArray<FBSDKSKAdNetworkCoarseCVConfig *> *)configs
{
  NSMutableSet<NSString *> *eventSet = [NSMutableSet new];
  if (configs) {
    for (FBSDKSKAdNetworkCoarseCVConfig *config in configs) {
      for (FBSDKSKAdNetworkCoarseCVRule *rule in config.cvRules) {
        if (!rule) {
          continue;
        }
        for (FBSDKSKAdNetworkEvent *event in rule.events) {
          if (event.eventName) {
            [eventSet addObject:event.eventName];
          }
        }
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
        [currencySet addObject:currency.uppercaseString];
      }
    }
  }
  return [currencySet copy];
}

+ (NSSet<NSString *> *)getCurrencySetFromCoarseConfigs:(nullable NSArray<FBSDKSKAdNetworkCoarseCVConfig *> *)configs
{
  NSMutableSet<NSString *> *currencySet = [NSMutableSet new];
  if (configs) {
    for (FBSDKSKAdNetworkCoarseCVConfig *config in configs) {
      for (FBSDKSKAdNetworkCoarseCVRule *rule in config.cvRules) {
        if (!rule) {
          continue;
        }
        for (FBSDKSKAdNetworkEvent *event in rule.events) {
          for (NSString *currency in event.values) {
            [currencySet addObject:currency.uppercaseString];
          }
        }
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

+ (nullable NSArray<FBSDKSKAdNetworkLockWindowRule *> *)parseLockWindowRules:(nullable NSArray<id> *)rules
{
  rules = [FBSDKTypeUtility arrayValue:rules];
  if (!rules) {
    return nil;
  }
  NSMutableArray<FBSDKSKAdNetworkLockWindowRule *> *parsedRules = [NSMutableArray new];
  for (id ruleEntry in rules) {
    FBSDKSKAdNetworkLockWindowRule *rule = [[FBSDKSKAdNetworkLockWindowRule alloc] initWithJSON:ruleEntry];
    [FBSDKTypeUtility array:parsedRules addObject:rule];
  }
  [parsedRules sortUsingComparator:^NSComparisonResult (FBSDKSKAdNetworkLockWindowRule *obj1, FBSDKSKAdNetworkLockWindowRule *obj2) {
    if (obj1.postbackSequenceIndex < obj2.postbackSequenceIndex) {
      return NSOrderedAscending;
    }
    if (obj1.postbackSequenceIndex > obj2.postbackSequenceIndex) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
  return [parsedRules copy];
}

+ (nullable NSArray<FBSDKSKAdNetworkCoarseCVConfig *> *)parseCoarseCvConfigs:(nullable NSArray<id> *)configs
{
  configs = [FBSDKTypeUtility arrayValue:configs];
  if (!configs) {
    return nil;
  }
  NSMutableArray<FBSDKSKAdNetworkCoarseCVConfig *> *parsedConfigs = [NSMutableArray new];
  for (id configEntry in configs) {
    FBSDKSKAdNetworkCoarseCVConfig *config = [[FBSDKSKAdNetworkCoarseCVConfig alloc] initWithJSON:configEntry];
    [FBSDKTypeUtility array:parsedConfigs addObject:config];
  }
  [parsedConfigs sortUsingComparator:^NSComparisonResult (FBSDKSKAdNetworkCoarseCVConfig *obj1, FBSDKSKAdNetworkCoarseCVConfig *obj2) {
    if (obj1.postbackSequenceIndex < obj2.postbackSequenceIndex) {
      return NSOrderedAscending;
    }
    if (obj1.postbackSequenceIndex > obj2.postbackSequenceIndex) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
  return [parsedConfigs copy];
}

@end

#endif
