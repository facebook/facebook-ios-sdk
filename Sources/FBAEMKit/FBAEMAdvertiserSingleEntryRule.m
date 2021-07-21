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

 #import "FBAEMAdvertiserSingleEntryRule.h"

 #import "FBCoreKitBasicsImportForAEMKit.h"

static NSString *const OPERATOR_KEY = @"operator";
static NSString *const PARAMKEY_KEY = @"param_key";
static NSString *const STRING_VALUE_KEY = @"string_value";
static NSString *const NUMBER_VALUE_KEY = @"number_value";
static NSString *const ARRAY_VALUE_KEY = @"array_value";
static NSString *const PARAM_DELIMETER = @".";
static NSString *const ASTERISK_DELIMETER = @"[*]";

@implementation FBAEMAdvertiserSingleEntryRule

- (instancetype)initWithOperator:(FBAEMAdvertiserRuleOperator)op
                        paramKey:(NSString *)paramKey
             linguisticCondition:(nullable NSString *)linguisticCondition
              numericalCondition:(nullable NSNumber *)numericalCondition
                  arrayCondition:(nullable NSArray *)arrayCondition
{
  if ((self = [super init])) {
    _operator = op;
    _paramKey = paramKey;
    _linguisticCondition = linguisticCondition;
    _numericalCondition = numericalCondition;
    _arrayCondition = arrayCondition;
  }
  return self;
}

 #pragma mark - FBAEMAdvertiserRuleMatching

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams
{
  @try {
    NSArray<NSString *> *paramPath = [_paramKey componentsSeparatedByString:PARAM_DELIMETER];
    return [self isMatchedEventParameters:eventParams paramPath:paramPath];
  } @catch (NSException *exception) {
  #if DEBUG
  #if FBAEMTEST
    @throw exception;
  #endif
  #endif
    return NO;
  }
}

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams
                       paramPath:(NSArray<NSString *> *)paramPath
{
  eventParams = [FBSDKTypeUtility dictionaryValue:eventParams];
  if (!eventParams || !paramPath.count) {
    return NO;
  }
  NSString *param = [FBSDKTypeUtility stringValueOrNil:paramPath.firstObject];
  if ([param hasSuffix:ASTERISK_DELIMETER]) {
    return [self isMatchedWithAsteriskParam:param eventParameters:eventParams paramPath:paramPath];
  }
  // if data does not contain the key, we should return false directly.
  if (!param || ![[eventParams allKeys] containsObject:param]) {
    return NO;
  }
  // Apply operator rule if the last param is reached
  if (paramPath.count == 1) {
    NSString *stringValue = nil;
    NSNumber *numericalValue = nil;
    switch (_operator) {
      case FBAEMAdvertiserRuleOperatorContains:
      case FBAEMAdvertiserRuleOperatorNotContains:
      case FBAEMAdvertiserRuleOperatorStartsWith:
      case FBAEMAdvertiserRuleOperatorI_Contains:
      case FBAEMAdvertiserRuleOperatorI_NotContains:
      case FBAEMAdvertiserRuleOperatorI_StartsWith:
      case FBAEMAdvertiserRuleOperatorRegexMatch:
      case FBAEMAdvertiserRuleOperatorEqual:
      case FBAEMAdvertiserRuleOperatorNotEqual:
      case FBAEMAdvertiserRuleOperatorI_IsAny:
      case FBAEMAdvertiserRuleOperatorI_IsNotAny:
      case FBAEMAdvertiserRuleOperatorIsAny:
      case FBAEMAdvertiserRuleOperatorIsNotAny:
        stringValue = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSString.class]; break;
      case FBAEMAdvertiserRuleOperatorLessThan:
      case FBAEMAdvertiserRuleOperatorLessThanOrEqual:
      case FBAEMAdvertiserRuleOperatorGreaterThan:
      case FBAEMAdvertiserRuleOperatorGreaterThanOrEqual:
        numericalValue = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSNumber.class]; break;
      default: break;
    }
    return [self isMatchedWithStringValue:stringValue numericalValue:numericalValue];
  }
  NSDictionary<NSString *, id> *subParams = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSDictionary.class];
  NSRange range = NSMakeRange(1, paramPath.count - 1);
  NSArray *subParamPath = [paramPath subarrayWithRange:range];
  return [self isMatchedEventParameters:subParams paramPath:subParamPath];
}

- (BOOL)isMatchedWithAsteriskParam:(NSString *)param
                   eventParameters:(NSDictionary<NSString *, id> *)eventParams
                         paramPath:(NSArray<NSString *> *)paramPath
{
  param = [param substringToIndex:param.length - ASTERISK_DELIMETER.length];
  NSArray<NSDictionary *> *items = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSArray.class];
  if (!items.count || paramPath.count < 2) {
    return NO;
  }
  BOOL isMatched = NO;
  NSRange range = NSMakeRange(1, paramPath.count - 1);
  NSArray *subParamPath = [paramPath subarrayWithRange:range];
  for (NSDictionary *item in items) {
    isMatched |= [self isMatchedEventParameters:item paramPath:subParamPath];
    if (isMatched) {
      break;
    }
  }
  return isMatched;
}

- (BOOL)isMatchedWithStringValue:(nullable NSString *)stringValue
                  numericalValue:(nullable NSNumber *)numericalValue
{
  BOOL isMatched = NO;
  switch (_operator) {
    case FBAEMAdvertiserRuleOperatorContains:
      isMatched = stringValue && [stringValue containsString:_linguisticCondition]; break;
    case FBAEMAdvertiserRuleOperatorNotContains:
      isMatched = !(stringValue && [stringValue containsString:_linguisticCondition]); break;
    case FBAEMAdvertiserRuleOperatorStartsWith:
      isMatched = stringValue && [stringValue hasPrefix:_linguisticCondition]; break;
    case FBAEMAdvertiserRuleOperatorI_Contains:
      isMatched = stringValue && [stringValue.lowercaseString containsString:_linguisticCondition.lowercaseString]; break;
    case FBAEMAdvertiserRuleOperatorI_NotContains:
      isMatched = !(stringValue && [stringValue.lowercaseString containsString:_linguisticCondition.lowercaseString]); break;
    case FBAEMAdvertiserRuleOperatorI_StartsWith:
      isMatched = stringValue && [stringValue.lowercaseString hasPrefix:_linguisticCondition.lowercaseString]; break;
    case FBAEMAdvertiserRuleOperatorRegexMatch:
      isMatched = stringValue && [self isRegexMatch:stringValue]; break;
    case FBAEMAdvertiserRuleOperatorEqual:
      isMatched = stringValue && [stringValue isEqualToString:_linguisticCondition]; break;
    case FBAEMAdvertiserRuleOperatorNotEqual:
      isMatched = !(stringValue && [stringValue isEqualToString:_linguisticCondition]); break;
    case FBAEMAdvertiserRuleOperatorI_IsAny:
      isMatched = stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:YES]; break;
    case FBAEMAdvertiserRuleOperatorI_IsNotAny:
      isMatched = !(stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:YES]); break;
    case FBAEMAdvertiserRuleOperatorIsAny:
      isMatched = stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:NO]; break;
    case FBAEMAdvertiserRuleOperatorIsNotAny:
      isMatched = !(stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:NO]); break;
    case FBAEMAdvertiserRuleOperatorLessThan:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] == NSOrderedAscending); break;
    case FBAEMAdvertiserRuleOperatorLessThanOrEqual:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] != NSOrderedDescending); break;
    case FBAEMAdvertiserRuleOperatorGreaterThan:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] == NSOrderedDescending); break;
    case FBAEMAdvertiserRuleOperatorGreaterThanOrEqual:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] != NSOrderedAscending); break;
    default: break;
  }
  return isMatched;
}

- (BOOL)isRegexMatch:(NSString *)stringValue
{
  if (!_linguisticCondition.length) {
    return NO;
  }
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:_linguisticCondition options:0 error:&error];
  if (!regex || error) {
    return NO;
  }
  NSRange searchedRange = NSMakeRange(0, stringValue.length);
  NSArray *matches = [regex matchesInString:stringValue options:0 range:searchedRange];
  return matches.count > 0;
}

- (BOOL)isAnyOf:(NSArray<NSString *> *)arrayCondition
    stringValue:(NSString *)stringValue
     ignoreCase:(BOOL)ignoreCase
{
  NSMutableSet<NSString *> *set = [NSMutableSet new];
  for (NSString *item in arrayCondition) {
    if (ignoreCase) {
      [set addObject:item.lowercaseString];
    } else {
      [set addObject:item];
    }
  }
  if (ignoreCase) {
    stringValue = stringValue.lowercaseString;
  }
  return [set containsObject:stringValue];
}

 #pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  FBAEMAdvertiserRuleOperator op = [decoder decodeIntegerForKey:OPERATOR_KEY];
  NSString *paramKey = [decoder decodeObjectOfClass:NSString.class forKey:PARAMKEY_KEY];
  NSString *linguisticCondition = [decoder decodeObjectOfClass:NSString.class forKey:STRING_VALUE_KEY];
  NSNumber *numericalCondition = [decoder decodeObjectOfClass:NSNumber.class forKey:NUMBER_VALUE_KEY];
  NSArray *arrayCondition = [decoder decodeObjectOfClass:NSArray.class forKey:ARRAY_VALUE_KEY];
  return [self initWithOperator:op
                       paramKey:paramKey
            linguisticCondition:linguisticCondition
             numericalCondition:numericalCondition
                 arrayCondition:arrayCondition];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInteger:_operator forKey:OPERATOR_KEY];
  [encoder encodeObject:_paramKey forKey:PARAMKEY_KEY];
  [encoder encodeObject:_linguisticCondition forKey:STRING_VALUE_KEY];
  [encoder encodeObject:_numericalCondition forKey:NUMBER_VALUE_KEY];
  [encoder encodeObject:_arrayCondition forKey:ARRAY_VALUE_KEY];
}

 #pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

 #if DEBUG
  #if FBAEMTEST

- (void)setOperator:(FBAEMAdvertiserRuleOperator)operator
{
  _operator = operator;
}

  #endif
 #endif

@end

#endif
