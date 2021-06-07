// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKAEMConfiguration.h"

 #import "FBSDKAEMAdvertiserMultiEntryRule.h"
 #import "FBSDKAEMAdvertiserSingleEntryRule.h"
 #import "FBSDKCoreKitBasicsImport.h"

static NSString *const DEFAULT_CURRENCY_KEY = @"default_currency";
static NSString *const CUTOFF_TIME_KEY = @"cutoff_time";
static NSString *const CONVERSION_RULES_KEY = @"conversion_value_rules";
static NSString *const VALID_FROM_KEY = @"valid_from";
static NSString *const CONFIG_MODE_KEY = @"config_mode";
static NSString *const CONFIG_BUSINESS_ID_KEY = @"advertiser_id";
static NSString *const BUSINESS_ID_KEY = @"business_id";
static NSString *const PARAM_RULE_KEY = @"param_rule";

static id<FBSDKAEMAdvertiserRuleProviding> _ruleProvider;

@implementation FBSDKAEMConfiguration

+ (void)configureWithRuleProvider:(id<FBSDKAEMAdvertiserRuleProviding>)ruleProvider
{
  if (self == [FBSDKAEMConfiguration class]) {
    _ruleProvider = ruleProvider;
  }
}

+ (id<FBSDKAEMAdvertiserRuleProviding>)ruleProvider
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
      id<FBSDKAEMAdvertiserRuleMatching> matchingRule = [FBSDKAEMConfiguration.ruleProvider createRuleWithJson:paramRuleJson];
      NSArray<FBSDKAEMRule *> *rules = [FBSDKAEMConfiguration parseRules:[FBSDKTypeUtility dictionary:dict objectForKey:CONVERSION_RULES_KEY ofType:NSArray.class]];
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
      _eventSet = [FBSDKAEMConfiguration getEventSetFromRules:_conversionValueRules];
      _currencySet = [FBSDKAEMConfiguration getCurrencySetFromRules:_conversionValueRules];
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
                           matchingRule:(id<FBSDKAEMAdvertiserRuleMatching>)matchingRule
                   conversionValueRules:(NSArray<FBSDKAEMRule *> *)conversionValueRules
{
  if ((self = [super init])) {
    _defaultCurrency = defaultCurrency;
    _cutoffTime = cutoffTime;
    _validFrom = validFrom;
    _configMode = configMode;
    _businessID = businessID;
    _matchingRule = matchingRule;
    _conversionValueRules = conversionValueRules;
    _eventSet = [FBSDKAEMConfiguration getEventSetFromRules:_conversionValueRules];
    _currencySet = [FBSDKAEMConfiguration getCurrencySetFromRules:_conversionValueRules];
  }
  return self;
}

+ (nullable NSArray<FBSDKAEMRule *> *)parseRules:(nullable NSArray<NSDictionary<NSString *, id> *> *)rules
{
  if (0 == rules.count) {
    return nil;
  }
  NSMutableArray<FBSDKAEMRule *> *parsedRules = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *ruleEntry in rules) {
    FBSDKAEMRule *rule = [[FBSDKAEMRule alloc] initWithJSON:ruleEntry];
    if (!rule) {
      return nil;
    }
    [FBSDKTypeUtility array:parsedRules addObject:rule];
  }
  // Sort the rules in descending priority order
  [parsedRules sortUsingComparator:^NSComparisonResult (FBSDKAEMRule *obj1, FBSDKAEMRule *obj2) {
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

+ (NSSet<NSString *> *)getEventSetFromRules:(NSArray<FBSDKAEMRule *> *)rules
{
  NSMutableSet<NSString *> *eventSet = [NSMutableSet new];
  for (FBSDKAEMRule *rule in rules) {
    if (!rule) {
      continue;
    }
    for (FBSDKAEMEvent *event in rule.events) {
      if (event.eventName) {
        [eventSet addObject:event.eventName];
      }
    }
  }
  return [eventSet copy];
}

+ (NSSet<NSString *> *)getCurrencySetFromRules:(NSArray<FBSDKAEMRule *> *)rules
{
  NSMutableSet<NSString *> *currencySet = [NSMutableSet new];
  for (FBSDKAEMRule *rule in rules) {
    if (!rule) {
      continue;
    }
    for (FBSDKAEMEvent *event in rule.events) {
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
  NSSet *matchingRuleClasses = [NSSet setWithArray:@[NSArray.class, FBSDKAEMAdvertiserMultiEntryRule.class, FBSDKAEMAdvertiserSingleEntryRule.class]];
  id<FBSDKAEMAdvertiserRuleMatching> matchingRule = [decoder decodeObjectOfClasses:matchingRuleClasses forKey:PARAM_RULE_KEY];
  NSArray<FBSDKAEMRule *> *rules = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBSDKAEMRule.class, FBSDKAEMEvent.class]] forKey:CONVERSION_RULES_KEY];
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
