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

#import "FBSDKRestrictiveDataFilterManager.h"

@interface FBSDKRestrictiveRule : NSObject

@property (nonatomic, readonly, copy) NSString *keyRegex;
@property (nonatomic, readonly, copy) NSString *valueRegex;
@property (nonatomic, readonly, copy) NSString *valueNegativeRegex;
@property (nonatomic, readonly, copy) NSString *dataType;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

-(instancetype)initWithKeyRegex:(NSString *)keyRegex
                     valueRegex:(NSString *)valueRegex
             valueNegativeRegex:(NSString *)valueNegativeRegex
                       dataType:(NSString *)dataType;

@end

@implementation FBSDKRestrictiveRule

-(instancetype)initWithKeyRegex:(NSString *)keyRegex
                     valueRegex:(NSString *)valueRegex
             valueNegativeRegex:(NSString *)valueNegativeRegex
                       dataType:(NSString *)dataType
{
  self = [super init];
  if (self) {
    _keyRegex = keyRegex;
    _valueRegex = valueRegex;
    _valueNegativeRegex = valueNegativeRegex;
    _dataType = dataType;
  }

  return self;
}

@end

@interface FBSDKRestrictiveEventFilter : NSObject

@property (nonatomic, readonly, copy) NSString *eventName;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> *eventParams;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

-(instancetype)initWithEventName:(NSString *)eventName
                     eventParams:(NSDictionary<NSString *, id> *)eventParams;

@end

@implementation FBSDKRestrictiveEventFilter

-(instancetype)initWithEventName:(NSString *)eventName
                     eventParams:(NSDictionary<NSString *, id> *)eventParams;
{
  self = [super init];
  if (self) {
    _eventName = eventName;
    _eventParams = eventParams;
  }

  return self;
}

@end

@implementation FBSDKRestrictiveDataFilterManager

static NSMutableArray<FBSDKRestrictiveRule *> *_rules;
static NSMutableArray<FBSDKRestrictiveEventFilter *>  *_params;

+ (void)updateFilters:(nullable NSArray<NSDictionary<NSString *, id> *> *)restrictiveRules
    restrictiveParams:(nullable NSDictionary<NSString *, id> *)restrictiveParams
{
  if (restrictiveRules.count > 0) {
    [_rules removeAllObjects];
    NSMutableArray<FBSDKRestrictiveRule *> *rulesArray = [NSMutableArray array];
    for (id rule in restrictiveRules) {
      FBSDKRestrictiveRule *restrictiveRule = [[FBSDKRestrictiveRule alloc] initWithKeyRegex:rule[@"key_regex"] ?: nil
                                                                                  valueRegex:rule[@"value_regex"] ?: nil
                                                                          valueNegativeRegex:rule[@"value_negative_regex"] ?: nil
                                                                                    dataType:rule[@"type"]];
      [rulesArray addObject:restrictiveRule];
    }
    _rules = rulesArray;
  }

  if (restrictiveParams.count > 0) {
    [_params removeAllObjects];
    NSMutableArray<FBSDKRestrictiveEventFilter *> *eventFilterArray = [NSMutableArray array];
    for (NSString *eventName in restrictiveParams.allKeys) {
      FBSDKRestrictiveEventFilter *restrictiveEventFilter = [[FBSDKRestrictiveEventFilter alloc] initWithEventName:eventName eventParams:restrictiveParams[eventName][@"restrictive_param"]];
      [eventFilterArray addObject:restrictiveEventFilter];
    }
    _params = eventFilterArray;
  }
}

+ (nullable NSString *)getMatchedDataTypeWithEventName:(NSString *)eventName
                                              paramKey:(NSString *)paramKey
                                            paramValue:(NSString *)paramValue
{
  // match by params in custom events with event name
  for (FBSDKRestrictiveEventFilter *filter in _params) {
    if ([filter.eventName isEqualToString:eventName]) {
      NSString *type = filter.eventParams[paramKey];
      if (type) {
        return type;
      }
    }
  }

  // match by regex
  NSArray<FBSDKRestrictiveRule *> *rules = [_rules copy];
  for (FBSDKRestrictiveRule *rule in rules) {
    // not matched to key
    if (rule.keyRegex.length != 0 && ![self isMatchedWithPattern:rule.keyRegex text:paramKey]) {
      continue;
    }
    // matched to neg val
    if (rule.valueNegativeRegex.length != 0 && [self isMatchedWithPattern:rule.valueNegativeRegex text:paramValue]) {
      continue;
    }
    // not matched to val
    if (rule.valueRegex.length != 0 && ![self isMatchedWithPattern:rule.valueRegex text:paramValue]) {
      continue;
    }
    return rule.dataType;
  }
  return nil;
}

#pragma mark Helper functions

+ (BOOL)isMatchedWithPattern:(NSString *)pattern
                        text:(NSString *)text
{
  NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
  NSUInteger matches = [regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, text.length)];
  return matches > 0;
}

@end
