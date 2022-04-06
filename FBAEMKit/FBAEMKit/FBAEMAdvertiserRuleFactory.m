/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMAdvertiserRuleFactory.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBAEMKit/FBAEMKit-Swift.h>

#import "FBAEMAdvertiserSingleEntryRule.h"

@implementation FBAEMAdvertiserRuleFactory

- (nullable id<FBAEMAdvertiserRuleMatching>)createRuleWithJson:(nullable NSString *)json
{
  @try {
    json = [FBSDKTypeUtility stringValueOrNil:json];
    if (!json) {
      return nil;
    }
    NSDictionary<NSString *, id> *rule = [FBSDKBasicUtility objectForJSONString:json error:nil];
    return [self createRuleWithDict:rule];
  } @catch (NSException *exception) {
    NSLog(@"Fail to parse Advertiser Rules with JSON");
  }
  return nil;
}

- (nullable id<FBAEMAdvertiserRuleMatching>)createRuleWithDict:(NSDictionary<NSString *, id> *)dict
{
  @try {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    FBAEMAdvertiserRuleOperator op = [self getOperator:dict];
    if ([self isOperatorForMultiEntryRule:op]) {
      return [self createMultiEntryRuleWithDict:dict];
    } else {
      return [self createSingleEntryRuleWithDict:dict];
    }
  } @catch (NSException *exception) {
    NSLog(@"Fail to parse Advertiser Rules with Dict");
  }
  return nil;
}

- (nullable FBAEMAdvertiserMultiEntryRule *)createMultiEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict
{
  dict = [FBSDKTypeUtility dictionaryValue:dict];
  if (!dict) {
    return nil;
  }
  NSString *opString = [self primaryKeyForRule:dict];
  FBAEMAdvertiserRuleOperator operator = [self getOperator:dict];
  if (![self isOperatorForMultiEntryRule:operator]) {
    return nil;
  }
  NSArray<NSDictionary<NSString *, id> *> *subrules = [FBSDKTypeUtility dictionary:dict objectForKey:opString ofType:NSArray.class];
  NSMutableArray<id<FBAEMAdvertiserRuleMatching>> *rules = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *subrule in subrules) {
    id<FBAEMAdvertiserRuleMatching> entryRule = [self createRuleWithDict:subrule];
    if (!entryRule) {
      return nil;
    }
    [FBSDKTypeUtility array:rules addObject:entryRule];
  }
  if (!rules.count) {
    return nil;
  }
  return [[FBAEMAdvertiserMultiEntryRule alloc] initWithOperator:operator rules:rules];
}

- (nullable FBAEMAdvertiserSingleEntryRule *)createSingleEntryRuleWithDict:(NSDictionary<NSString *, id> *)dict
{
  dict = [FBSDKTypeUtility dictionaryValue:dict];
  if (!dict) {
    return nil;
  }
  NSString *paramKey = [self primaryKeyForRule:dict];
  NSDictionary<NSString *, id> *rawRule = [FBSDKTypeUtility dictionary:dict objectForKey:paramKey ofType:NSDictionary.class];
  NSString *encodedOperator = [self primaryKeyForRule:rawRule];
  FBAEMAdvertiserRuleOperator operator = [self getOperator:rawRule];
  NSString *linguisticCondition = nil;
  NSNumber *numericalCondition = nil;
  NSArray<NSString *> *arrayCondition = nil;
  switch (operator) {
    case FBAEMAdvertiserRuleOperatorUnknown:
    default:
      return nil;
    case FBAEMAdvertiserRuleOperatorContains:
    case FBAEMAdvertiserRuleOperatorNotContains:
    case FBAEMAdvertiserRuleOperatorStartsWith:
    case FBAEMAdvertiserRuleOperatorCaseInsensitiveContains:
    case FBAEMAdvertiserRuleOperatorCaseInsensitiveNotContains:
    case FBAEMAdvertiserRuleOperatorCaseInsensitiveStartsWith:
    case FBAEMAdvertiserRuleOperatorRegexMatch:
    case FBAEMAdvertiserRuleOperatorEqual:
    case FBAEMAdvertiserRuleOperatorNotEqual:
      linguisticCondition = [FBSDKTypeUtility dictionary:rawRule objectForKey:encodedOperator ofType:NSString.class]; break;
    case FBAEMAdvertiserRuleOperatorLessThan:
    case FBAEMAdvertiserRuleOperatorLessThanOrEqual:
    case FBAEMAdvertiserRuleOperatorGreaterThan:
    case FBAEMAdvertiserRuleOperatorGreaterThanOrEqual:
      numericalCondition = [FBSDKTypeUtility dictionary:rawRule objectForKey:encodedOperator ofType:NSNumber.class]; break;
    case FBAEMAdvertiserRuleOperatorCaseInsensitiveIsAny:
    case FBAEMAdvertiserRuleOperatorCaseInsensitiveIsNotAny:
    case FBAEMAdvertiserRuleOperatorIsAny:
    case FBAEMAdvertiserRuleOperatorIsNotAny:
      arrayCondition = [FBSDKTypeUtility dictionary:rawRule objectForKey:encodedOperator ofType:NSArray.class]; break;
  }
  if (linguisticCondition || numericalCondition != nil || arrayCondition.count > 0) {
    return [[FBAEMAdvertiserSingleEntryRule alloc] initWithOperator:operator paramKey:paramKey linguisticCondition:linguisticCondition numericalCondition:numericalCondition arrayCondition:arrayCondition];
  }
  return nil;
}

- (nullable NSString *)primaryKeyForRule:(NSDictionary<NSString *, id> *)rule
{
  NSArray<NSString *> *keys = rule.allKeys;
  NSString *key = keys.firstObject;
  return [FBSDKTypeUtility stringValueOrNil:key];
}

- (FBAEMAdvertiserRuleOperator)getOperator:(NSDictionary<NSString *, id> *)rule
{
  NSString *key = [self primaryKeyForRule:rule];
  if (!key) {
    return FBAEMAdvertiserRuleOperatorUnknown;
  }
  NSArray<NSString *> *operatorKeys = @[
    // UNCRUSTIFY_FORMAT_OFF
    @"unknown",        // FBAEMAdvertiserRuleOperatorUnknown
    @"and",            // FBAEMAdvertiserRuleOperatorAnd
    @"or",             // FBAEMAdvertiserRuleOperatorOr
    @"not",            // FBAEMAdvertiserRuleOperatorNot
    @"contains",       // FBAEMAdvertiserRuleOperatorContains
    @"not_contains",   // FBAEMAdvertiserRuleOperatorNotContains
    @"starts_with",    // FBAEMAdvertiserRuleOperatorStartsWith
    @"i_contains",     // FBAEMAdvertiserRuleOperatorCaseInsensitiveContains
    @"i_not_contains", // FBAEMAdvertiserRuleOperatorCaseInsensitiveNotContains
    @"i_starts_with",  // FBAEMAdvertiserRuleOperatorCaseInsensitiveStartsWith
    @"regex_match",    // FBAEMAdvertiserRuleOperatorRegexMatch
    @"eq",             // FBAEMAdvertiserRuleOperatorEqual
    @"neq",            // FBAEMAdvertiserRuleOperatorNotEqual
    @"lt",             // FBAEMAdvertiserRuleOperatorLessThan
    @"lte",            // FBAEMAdvertiserRuleOperatorLessThanOrEqual
    @"gt",             // FBAEMAdvertiserRuleOperatorGreaterThan
    @"gte",            // FBAEMAdvertiserRuleOperatorGreaterThanOrEqual
    @"i_is_any",       // FBAEMAdvertiserRuleOperatorCaseInsensitiveIsAny
    @"i_is_not_any",   // FBAEMAdvertiserRuleOperatorCaseInsensitiveIsNotAny
    @"is_any",         // FBAEMAdvertiserRuleOperatorIsAny
    @"is_not_any"      // FBAEMAdvertiserRuleOperatorIsNotAny
    // UNCRUSTIFY_FORMAT_ON
  ];
  NSInteger index = [operatorKeys indexOfObject:key.lowercaseString];
  return index == NSNotFound ? FBAEMAdvertiserRuleOperatorUnknown : index;
}

- (BOOL)isOperatorForMultiEntryRule:(FBAEMAdvertiserRuleOperator)operator
{
  return operator == FBAEMAdvertiserRuleOperatorAnd
  || operator == FBAEMAdvertiserRuleOperatorOr
  || operator == FBAEMAdvertiserRuleOperatorNot;
}

@end

#endif
