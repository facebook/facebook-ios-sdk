/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMAdvertiserMultiEntryRule.h"

#import <FBAEMKit/FBAEMKit-Swift.h>

#import "FBAEMAdvertiserSingleEntryRule.h"

static NSString *const OPERATOR_KEY = @"operator";
static NSString *const RULES_KEY = @"rules";

@implementation FBAEMAdvertiserMultiEntryRule

- (instancetype)initWithOperator:(FBAEMAdvertiserRuleOperator)op
                           rules:(NSArray<id<FBAEMAdvertiserRuleMatching>> *)rules
{
  if ((self = [super init])) {
    _operator = op;
    _rules = rules;
  }
  return self;
}

#pragma mark - FBAEMAdvertiserRuleMatching

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams
{
  @try {
    BOOL isMatched = _operator == FBAEMAdvertiserRuleOperatorOr ? NO : YES;
    for (id<FBAEMAdvertiserRuleMatching> rule in _rules) {
      BOOL doesSubruleMatch = [rule isMatchedEventParameters:eventParams];
      if (_operator == FBAEMAdvertiserRuleOperatorAnd) {
        isMatched = isMatched & doesSubruleMatch;
      }
      if (_operator == FBAEMAdvertiserRuleOperatorOr) {
        isMatched = isMatched | doesSubruleMatch;
      }
      if (_operator == FBAEMAdvertiserRuleOperatorNot) {
        isMatched = isMatched & !doesSubruleMatch;
      }
    }
    return isMatched;
  } @catch (NSException *exception) {
  #if DEBUG
  #if FBTEST
    @throw exception;
  #endif
  #endif
    return NO;
  }
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  FBAEMAdvertiserRuleOperator op = [decoder decodeIntegerForKey:OPERATOR_KEY];
  NSSet<Class> *classes = [NSSet setWithArray:@[NSArray.class, FBAEMAdvertiserMultiEntryRule.class, FBAEMAdvertiserSingleEntryRule.class]];
  NSArray<id<FBAEMAdvertiserRuleMatching>> *rules = [decoder decodeObjectOfClasses:classes forKey:RULES_KEY];
  return [self initWithOperator:op rules:rules];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInteger:_operator forKey:OPERATOR_KEY];
  [encoder encodeObject:_rules forKey:RULES_KEY];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

@end

#endif
