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

 #import "FBSDKAEMAdvertiserMultiEntryRule.h"

 #import "FBSDKAEMAdvertiserSingleEntryRule.h"

static NSString *const OPERATOR_KEY = @"operator";
static NSString *const RULES_KEY = @"rules";

@implementation FBSDKAEMAdvertiserMultiEntryRule

- (instancetype)initWithOperator:(FBSDKAEMAdvertiserRuleOperator)op
                           rules:(NSArray<id<FBSDKAEMAdvertiserRuleMatching>> *)rules
{
  if (self = [super init]) {
    _operator = op;
    _rules = rules;
  }
  return self;
}

 #pragma mark - FBSDKAEMAdvertiserRuleMatching

- (BOOL)isMatchedEventParameters:(nullable NSDictionary<NSString *, id> *)eventParams
{
  @try {
    BOOL isMatched = _operator == FBSDKAEMAdvertiserRuleOperatorOr ? NO : YES;
    for (id<FBSDKAEMAdvertiserRuleMatching> rule in _rules) {
      BOOL doesSubruleMatch = [rule isMatchedEventParameters:eventParams];
      if (_operator == FBSDKAEMAdvertiserRuleOperatorAnd) {
        isMatched = isMatched & doesSubruleMatch;
      }
      if (_operator == FBSDKAEMAdvertiserRuleOperatorOr) {
        isMatched = isMatched | doesSubruleMatch;
      }
      if (_operator == FBSDKAEMAdvertiserRuleOperatorNot) {
        isMatched = isMatched & !doesSubruleMatch;
      }
    }
    return isMatched;
  } @catch (NSException *exception) {
  #if DEBUG
  #if FBSDKTEST
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
  FBSDKAEMAdvertiserRuleOperator op = [decoder decodeIntegerForKey:OPERATOR_KEY];
  NSSet *classes = [NSSet setWithArray:@[NSArray.class, FBSDKAEMAdvertiserMultiEntryRule.class, FBSDKAEMAdvertiserSingleEntryRule.class]];
  NSArray<id<FBSDKAEMAdvertiserRuleMatching>> *rules = [decoder decodeObjectOfClasses:classes forKey:RULES_KEY];
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
