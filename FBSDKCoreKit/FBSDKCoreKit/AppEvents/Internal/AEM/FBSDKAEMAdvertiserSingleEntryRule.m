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

 #import "FBSDKAEMAdvertiserSingleEntryRule.h"

 #import "FBSDKCoreKitBasicsImport.h"

static NSString *const OPERATOR_KEY = @"operator";
static NSString *const PARAMKEY_KEY = @"param_key";
static NSString *const STRING_VALUE_KEY = @"string_value";
static NSString *const NUMBER_VALUE_KEY = @"number_value";
static NSString *const ARRAY_VALUE_KEY = @"array_value";
static NSString *const PARAM_DELIMETER = @".";

@implementation FBSDKAEMAdvertiserSingleEntryRule

- (instancetype)initWithOperator:(FBSDKAEMAdvertiserRuleOperator)op
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

 #pragma mark - FBSDKAEMAdvertiserRuleMatching

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams
{
  NSArray<NSString *> *paramPath = [_paramKey componentsSeparatedByString:PARAM_DELIMETER];
  return [self isMatchedEventParameters:eventParams paramPath:paramPath index:0];
}

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams
                       paramPath:(NSArray<NSString *> *)paramPath
                           index:(NSInteger)index
{
  eventParams = [FBSDKTypeUtility dictionaryValue:eventParams];
  if (!eventParams) {
    return NO;
  }
  NSString *param = [FBSDKTypeUtility stringValueOrNil:[FBSDKTypeUtility array:paramPath objectAtIndex:index]];
  // if data does not contain the key, we should return false directly.
  if (!param || ![[eventParams allKeys] containsObject:param]) {
    return NO;
  }
  // Apply operator rule if the last param is reached
  if (paramPath.count == index + 1) {
    NSString *stringValue = nil;
    NSNumber *numericalValue = nil;
    switch (_operator) {
      case FBSDKAEMAdvertiserRuleOperatorContains:
      case FBSDKAEMAdvertiserRuleOperatorNotContains:
      case FBSDKAEMAdvertiserRuleOperatorStartsWith:
      case FBSDKAEMAdvertiserRuleOperatorI_Contains:
      case FBSDKAEMAdvertiserRuleOperatorI_NotContains:
      case FBSDKAEMAdvertiserRuleOperatorI_StartsWith:
      case FBSDKAEMAdvertiserRuleOperatorRegexMatch:
      case FBSDKAEMAdvertiserRuleOperatorEqual:
      case FBSDKAEMAdvertiserRuleOperatorNotEqual:
      case FBSDKAEMAdvertiserRuleOperatorI_IsAny:
      case FBSDKAEMAdvertiserRuleOperatorI_IsNotAny:
      case FBSDKAEMAdvertiserRuleOperatorIsAny:
      case FBSDKAEMAdvertiserRuleOperatorIsNotAny:
        stringValue = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSString.class]; break;
      case FBSDKAEMAdvertiserRuleOperatorLessThan:
      case FBSDKAEMAdvertiserRuleOperatorLessThanOrEqual:
      case FBSDKAEMAdvertiserRuleOperatorGreaterThan:
      case FBSDKAEMAdvertiserRuleOperatorGreaterThanOrEqual:
        numericalValue = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSNumber.class]; break;
      default: break;
    }
    return [self isMatchedWithStringValue:stringValue numericalValue:numericalValue];
  }
  NSDictionary<NSString *, id> *subParams = [FBSDKTypeUtility dictionary:eventParams objectForKey:param ofType:NSDictionary.class];
  return [self isMatchedEventParameters:subParams paramPath:paramPath index:index + 1];
}

- (BOOL)isMatchedWithStringValue:(nullable NSString *)stringValue
                  numericalValue:(nullable NSNumber *)numericalValue
{
  BOOL isMatched = NO;
  switch (_operator) {
    case FBSDKAEMAdvertiserRuleOperatorContains:
      isMatched = stringValue && [stringValue containsString:_linguisticCondition]; break;
    case FBSDKAEMAdvertiserRuleOperatorNotContains:
      isMatched = !(stringValue && [stringValue containsString:_linguisticCondition]); break;
    case FBSDKAEMAdvertiserRuleOperatorStartsWith:
      isMatched = stringValue && [stringValue hasPrefix:_linguisticCondition]; break;
    case FBSDKAEMAdvertiserRuleOperatorI_Contains:
      isMatched = stringValue && [stringValue.lowercaseString containsString:_linguisticCondition.lowercaseString]; break;
    case FBSDKAEMAdvertiserRuleOperatorI_NotContains:
      isMatched = !(stringValue && [stringValue.lowercaseString containsString:_linguisticCondition.lowercaseString]); break;
    case FBSDKAEMAdvertiserRuleOperatorI_StartsWith:
      isMatched = stringValue && [stringValue.lowercaseString hasPrefix:_linguisticCondition.lowercaseString]; break;
    case FBSDKAEMAdvertiserRuleOperatorRegexMatch:
      isMatched = stringValue && [self isRegexMatch:stringValue]; break;
    case FBSDKAEMAdvertiserRuleOperatorEqual:
      isMatched = stringValue && [stringValue isEqualToString:_linguisticCondition]; break;
    case FBSDKAEMAdvertiserRuleOperatorNotEqual:
      isMatched = !(stringValue && [stringValue isEqualToString:_linguisticCondition]); break;
    case FBSDKAEMAdvertiserRuleOperatorI_IsAny:
      isMatched = stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:YES]; break;
    case FBSDKAEMAdvertiserRuleOperatorI_IsNotAny:
      isMatched = !(stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:YES]); break;
    case FBSDKAEMAdvertiserRuleOperatorIsAny:
      isMatched = stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:NO]; break;
    case FBSDKAEMAdvertiserRuleOperatorIsNotAny:
      isMatched = !(stringValue && [self isAnyOf:_arrayCondition stringValue:stringValue ignoreCase:NO]); break;
    case FBSDKAEMAdvertiserRuleOperatorLessThan:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] == NSOrderedAscending); break;
    case FBSDKAEMAdvertiserRuleOperatorLessThanOrEqual:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] != NSOrderedDescending); break;
    case FBSDKAEMAdvertiserRuleOperatorGreaterThan:
      isMatched = (numericalValue != nil) && ([numericalValue compare:_numericalCondition] == NSOrderedDescending); break;
    case FBSDKAEMAdvertiserRuleOperatorGreaterThanOrEqual:
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
  FBSDKAEMAdvertiserRuleOperator op = [decoder decodeIntegerForKey:OPERATOR_KEY];
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
  #if FBSDKTEST

- (void)setOperator:(FBSDKAEMAdvertiserRuleOperator)operator
{
  _operator = operator;
}

  #endif
 #endif

@end

#endif
