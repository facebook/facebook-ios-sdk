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

static NSString *const OPERATOR_KEY = @"operator";
static NSString *const PARAMKEY_KEY = @"param_key";
static NSString *const STRING_VALUE_KEY = @"string_value";
static NSString *const NUMBER_VALUE_KEY = @"number_value";
static NSString *const ARRAY_VALUE_KEY = @"array_value";

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

@end

#endif
