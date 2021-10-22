/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMConfiguration.h"

#import "FBAEMAdvertiserMultiEntryRule.h"
#import "FBAEMAdvertiserSingleEntryRule.h"
#import "FBCoreKitBasicsImportForAEMKit.h"

static NSString *const DEFAULT_CURRENCY_KEY = @"default_currency";
static NSString *const CUTOFF_TIME_KEY = @"cutoff_time";
static NSString *const CONVERSION_RULES_KEY = @"conversion_value_rules";
static NSString *const VALID_FROM_KEY = @"valid_from";
static NSString *const CONFIG_MODE_KEY = @"config_mode";
static NSString *const CONFIG_BUSINESS_ID_KEY = @"advertiser_id";
static NSString *const BUSINESS_ID_KEY = @"business_id";
static NSString *const PARAM_RULE_KEY = @"param_rule";

static id<FBAEMAdvertiserRuleProviding> _ruleProvider;

@implementation FBAEMConfiguration

+ (void)configureWithRuleProvider:(id<FBAEMAdvertiserRuleProviding>)ruleProvider
{
  if (self == FBAEMConfiguration.class) {
    _ruleProvider = ruleProvider;
  }
}

+ (id<FBAEMAdvertiserRuleProviding>)ruleProvider
{
  return _ruleProvider;
}

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    @try {
      dict = [FBSDKTypeUtility dictionaryValue:dict];
      if (!dict) {
        return nil;
      }
      NSString *defaultCurrency = [FBSDKTypeUtility dictionary:dict objectForKey:DEFAULT_CURRENCY_KEY ofType:NSString.class];
      NSNumber *cutoffTime = [FBSDKTypeUtility dictionary:dict objectForKey:CUTOFF_TIME_KEY ofType:NSNumber.class];
      NSNumber *validFrom = [FBSDKTypeUtility dictionary:dict objectForKey:VALID_FROM_KEY ofType:NSNumber.class];
      NSString *configMode = [FBSDKTypeUtility dictionary:dict objectForKey:CONFIG_MODE_KEY ofType:NSString.class];
      NSString *businessID = [FBSDKTypeUtility dictionary:dict objectForKey:CONFIG_BUSINESS_ID_KEY ofType:NSString.class];
      NSString *paramRuleJson = [FBSDKTypeUtility dictionary:dict objectForKey:PARAM_RULE_KEY ofType:NSString.class];
      id<FBAEMAdvertiserRuleMatching> matchingRule = [FBAEMConfiguration.ruleProvider createRuleWithJson:paramRuleJson];
      NSArray<FBAEMRule *> *rules = [FBAEMConfiguration parseRules:[FBSDKTypeUtility dictionary:dict objectForKey:CONVERSION_RULES_KEY ofType:NSArray.class]];
      if (!defaultCurrency || cutoffTime == nil || validFrom == nil || !configMode || 0 == rules.count) {
        return nil;
      }
      // Advertiser Config must have param rule
      if (businessID && !matchingRule) {
        return nil;
      }
      _defaultCurrency = defaultCurrency;
      _cutoffTime = cutoffTime.integerValue;
      _validFrom = validFrom.integerValue;
      _configMode = configMode;
      _businessID = businessID;
      _matchingRule = matchingRule;
      _conversionValueRules = rules;
      _eventSet = [FBAEMConfiguration getEventSetFromRules:_conversionValueRules];
      _currencySet = [FBAEMConfiguration getCurrencySetFromRules:_conversionValueRules];
    } @catch (NSException *exception) {
      return nil;
    }
  }
  return self;
}

- (instancetype)initWithDefaultCurrency:(NSString *)defaultCurrency
                             cutoffTime:(NSInteger)cutoffTime
                              validFrom:(NSInteger)validFrom
                             configMode:(NSString *)configMode
                             businessID:(nullable NSString *)businessID
                           matchingRule:(id<FBAEMAdvertiserRuleMatching>)matchingRule
                   conversionValueRules:(NSArray<FBAEMRule *> *)conversionValueRules
{
  if ((self = [super init])) {
    _defaultCurrency = defaultCurrency;
    _cutoffTime = cutoffTime;
    _validFrom = validFrom;
    _configMode = configMode;
    _businessID = businessID;
    _matchingRule = matchingRule;
    _conversionValueRules = conversionValueRules;
    _eventSet = [FBAEMConfiguration getEventSetFromRules:_conversionValueRules];
    _currencySet = [FBAEMConfiguration getCurrencySetFromRules:_conversionValueRules];
  }
  return self;
}

+ (nullable NSArray<FBAEMRule *> *)parseRules:(nullable NSArray<NSDictionary<NSString *, id> *> *)rules
{
  if (0 == rules.count) {
    return nil;
  }
  NSMutableArray<FBAEMRule *> *parsedRules = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *ruleEntry in rules) {
    FBAEMRule *rule = [[FBAEMRule alloc] initWithJSON:ruleEntry];
    if (!rule) {
      return nil;
    }
    [FBSDKTypeUtility array:parsedRules addObject:rule];
  }
  // Sort the rules in descending priority order
  [parsedRules sortUsingComparator:^NSComparisonResult (FBAEMRule *obj1, FBAEMRule *obj2) {
    if (obj1.priority < obj2.priority) {
      return NSOrderedDescending;
    }
    if (obj1.priority > obj2.priority) {
      return NSOrderedAscending;
    }
    return NSOrderedSame;
  }];
  return [parsedRules copy];
}

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBAEMRule *> *)rules
{
  NSMutableSet<NSString *> *eventSet = [NSMutableSet new];
  for (FBAEMRule *rule in rules) {
    if (!rule) {
      continue;
    }
    for (FBAEMEvent *event in rule.events) {
      if (event.eventName) {
        [eventSet addObject:event.eventName];
      }
    }
  }
  return [eventSet copy];
}

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBAEMRule *> *)rules
{
  NSMutableSet<NSString *> *currencySet = [NSMutableSet new];
  for (FBAEMRule *rule in rules) {
    if (!rule) {
      continue;
    }
    for (FBAEMEvent *event in rule.events) {
      for (NSString *currency in event.values) {
        [currencySet addObject:[currency uppercaseString]];
      }
    }
  }
  return [currencySet copy];
}

- (BOOL)isSameValidFrom:(NSInteger)validFrom
             businessID:(nullable NSString *)businessID
{
  return (_validFrom == validFrom) && [self isSameBusinessID:businessID];
}

- (BOOL)isSameBusinessID:(nullable NSString *)businessID
{
  return (_businessID && [_businessID isEqualToString:businessID])
  || (!_businessID && !businessID);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *defaultCurrency = [decoder decodeObjectOfClass:NSString.class forKey:DEFAULT_CURRENCY_KEY];
  NSInteger cutoffTime = [decoder decodeIntegerForKey:CUTOFF_TIME_KEY];
  NSInteger validFrom = [decoder decodeIntegerForKey:VALID_FROM_KEY];
  NSString *configMode = [decoder decodeObjectOfClass:NSString.class forKey:CONFIG_MODE_KEY];
  NSString *businessID = [decoder decodeObjectOfClass:NSString.class forKey:BUSINESS_ID_KEY];
  NSSet<Class> *matchingRuleClasses = [NSSet setWithArray:@[NSArray.class, FBAEMAdvertiserMultiEntryRule.class, FBAEMAdvertiserSingleEntryRule.class]];
  id<FBAEMAdvertiserRuleMatching> matchingRule = [decoder decodeObjectOfClasses:matchingRuleClasses forKey:PARAM_RULE_KEY];
  NSArray<FBAEMRule *> *rules = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBAEMRule.class, FBAEMEvent.class]] forKey:CONVERSION_RULES_KEY];
  return [self initWithDefaultCurrency:defaultCurrency
                            cutoffTime:cutoffTime
                             validFrom:validFrom
                            configMode:configMode
                            businessID:businessID
                          matchingRule:matchingRule
                  conversionValueRules:rules];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_defaultCurrency forKey:DEFAULT_CURRENCY_KEY];
  [encoder encodeInteger:_cutoffTime forKey:CUTOFF_TIME_KEY];
  [encoder encodeInteger:_validFrom forKey:VALID_FROM_KEY];
  [encoder encodeObject:_configMode forKey:CONFIG_MODE_KEY];
  [encoder encodeObject:_businessID forKey:BUSINESS_ID_KEY];
  [encoder encodeObject:_matchingRule forKey:PARAM_RULE_KEY];
  [encoder encodeObject:_conversionValueRules forKey:CONVERSION_RULES_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

@end

#endif
