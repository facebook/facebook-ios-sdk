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

 #import "FBSDKAEMAdvertiserRuleFactory.h"

 #import "FBSDKAEMAdvertiserMultiEntryRule.h"
 #import "FBSDKAEMAdvertiserSingleEntryRule.h"
 #import "FBSDKCoreKitBasicsImport.h"
 #import "FBSDKLogger.h"

@implementation FBSDKAEMAdvertiserRuleFactory

- (nullable id<FBSDKAEMAdvertiserRuleMatching>)createRuleWithJson:(nullable NSString *)json
{
  @try {
    json = [FBSDKTypeUtility stringValueOrNil:json];
    if (!json) {
      return nil;
    }
    NSDictionary<NSString *, id> *rule = [FBSDKBasicUtility objectForJSONString:json error:nil];
    return [self createRuleWithDict:rule];
  } @catch (NSException *exception) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents logEntry:@"Fail to parse Advertiser Rules with JSON"];
  }
  return nil;
}

- (nullable id<FBSDKAEMAdvertiserRuleMatching>)createRuleWithDict:(NSDictionary<NSString *, id> *)dict
{
  @try {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    FBSDKAEMAdvertiserRuleOperator op = [self getOperator:dict];
    if ([self isOperatorForMultiEntryRule:op]) {
      return [self createMultiEntryRuleWithDict:dict];
    } else {
      return [self createSingleEntryRuleWithDict:dict];
    }
  } @catch (NSException *exception) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents logEntry:@"Fail to parse Advertiser Rules with Dict"];
  }
  return nil;
}

- (nullable FBSDKAEMAdvertiserMultiEntryRule *)createMultiEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict
{
  dict = [FBSDKTypeUtility dictionaryValue:dict];
  if (!dict) {
    return nil;
  }
  NSString *opString = [self primaryKeyForRule:dict];
  FBSDKAEMAdvertiserRuleOperator operator = [self getOperator:dict];
  if (![self isOperatorForMultiEntryRule:operator]) {
    return nil;
  }
  NSArray<NSDictionary *> *subrules = [FBSDKTypeUtility dictionary:dict objectForKey:opString ofType:NSArray.class];
  NSMutableArray<id<FBSDKAEMAdvertiserRuleMatching>> *rules = [NSMutableArray new];
  for (NSDictionary *subrule in subrules) {
    id<FBSDKAEMAdvertiserRuleMatching> entryRule = [self createRuleWithDict:subrule];
    if (!entryRule) {
      return nil;
    }
    [FBSDKTypeUtility array:rules addObject:entryRule];
  }
  if (!rules.count) {
    return nil;
  }
  return [[FBSDKAEMAdvertiserMultiEntryRule alloc] initWithOperator:operator rules:rules];
}

- (nullable FBSDKAEMAdvertiserSingleEntryRule *)createSingleEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict
{
  dict = [FBSDKTypeUtility dictionaryValue:dict];
  if (!dict) {
    return nil;
  }
  NSString *paramKey = [self primaryKeyForRule:dict];
  NSDictionary<NSString *, id> *rawRule = [FBSDKTypeUtility dictionary:dict objectForKey:paramKey ofType:NSDictionary.class];
  NSString *encodedOperator = [self primaryKeyForRule:rawRule];
  FBSDKAEMAdvertiserRuleOperator operator = [self getOperator:rawRule];
  NSString *linguisticCondition = nil;
  NSNumber *numericalCondition = nil;
  NSArray *arrayCondition = nil;
  switch (operator) {
    case Unknown:
    default:
      return nil;
    case FBSDKAEMAdvertiserRuleOperatorContains:
    case FBSDKAEMAdvertiserRuleOperatorNotContains:
    case FBSDKAEMAdvertiserRuleOperatorStartsWith:
    case FBSDKAEMAdvertiserRuleOperatorI_Contains:
    case FBSDKAEMAdvertiserRuleOperatorI_NotContains:
    case FBSDKAEMAdvertiserRuleOperatorI_StartsWith:
    case FBSDKAEMAdvertiserRuleOperatorRegexMatch:
    case FBSDKAEMAdvertiserRuleOperatorEqual:
    case FBSDKAEMAdvertiserRuleOperatorNotEqual:
      linguisticCondition = [FBSDKTypeUtility dictionary:rawRule objectForKey:encodedOperator ofType:NSString.class]; break;
    case FBSDKAEMAdvertiserRuleOperatorLessThan:
    case FBSDKAEMAdvertiserRuleOperatorLessThanOrEqual:
    case FBSDKAEMAdvertiserRuleOperatorGreaterThan:
    case FBSDKAEMAdvertiserRuleOperatorGreaterThanOrEqual:
      numericalCondition = [FBSDKTypeUtility dictionary:rawRule objectForKey:encodedOperator ofType:NSNumber.class]; break;
    case FBSDKAEMAdvertiserRuleOperatorI_IsAny:
    case FBSDKAEMAdvertiserRuleOperatorI_IsNotAny:
    case FBSDKAEMAdvertiserRuleOperatorIsAny:
    case FBSDKAEMAdvertiserRuleOperatorIsNotAny:
      arrayCondition = [FBSDKTypeUtility dictionary:rawRule objectForKey:encodedOperator ofType:NSArray.class]; break;
  }
  if (linguisticCondition || numericalCondition != nil || arrayCondition.count > 0) {
    return [[FBSDKAEMAdvertiserSingleEntryRule alloc] initWithOperator:operator paramKey:paramKey linguisticCondition:linguisticCondition numericalCondition:numericalCondition arrayCondition:arrayCondition];
  }
  return nil;
}

- (nullable NSString *)primaryKeyForRule:(NSDictionary<NSString *, id> *)rule
{
  NSArray<NSString *> *keys = [rule allKeys];
  NSString *key = keys.firstObject;
  return [FBSDKTypeUtility stringValueOrNil:key];
}

- (FBSDKAEMAdvertiserRuleOperator)getOperator:(NSDictionary<NSString *, id> *)rule
{
  NSString *key = [self primaryKeyForRule:rule];
  if (!key) {
    return Unknown;
  }
  NSArray<NSString *> *operatorKeys = @[
    @"unknown",
    @"and",
    @"or",
    @"not",
    @"contains",
    @"not_contains",
    @"starts_with",
    @"i_contains",
    @"i_not_contains",
    @"i_starts_with",
    @"regex_match",
    @"eq",
    @"neq",
    @"lt",
    @"lte",
    @"gt",
    @"gte",
    @"i_is_any",
    @"i_is_not_any",
    @"is_any",
    @"is_not_any"
  ];
  NSInteger index = [operatorKeys indexOfObject:key.lowercaseString];
  return index == NSNotFound ? Unknown : index;
}

- (BOOL)isOperatorForMultiEntryRule:(FBSDKAEMAdvertiserRuleOperator)operator
{
  return operator == FBSDKAEMAdvertiserRuleOperatorAnd
  || operator == FBSDKAEMAdvertiserRuleOperatorOr
  || operator == FBSDKAEMAdvertiserRuleOperatorNot;
}

@end

#endif
