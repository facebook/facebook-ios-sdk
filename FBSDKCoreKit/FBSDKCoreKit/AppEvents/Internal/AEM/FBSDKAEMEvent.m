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

 #import "FBSDKAEMEvent.h"

 #import "FBSDKCoreKit+Internal.h"

static NSString *const EVENT_NAME_KEY = @"event_name";
static NSString *const VALUES_KEY = @"values";
static NSString *const CURRENCY_KEY = @"currency";
static NSString *const AMOUNT_KEY = @"amount";

@implementation FBSDKAEMEvent

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    _eventName = [FBSDKTypeUtility dictionary:dict objectForKey:EVENT_NAME_KEY ofType:NSString.class];
    // Event name is a required field
    if (!_eventName) {
      return nil;
    }
    // Values is an optional field
    NSArray<NSDictionary<NSString *, id> *> *valueEntries = [FBSDKTypeUtility dictionary:dict objectForKey:VALUES_KEY ofType:NSArray.class];
    if (valueEntries.count > 0) {
      NSMutableDictionary<NSString *, NSNumber *> *valueDict = [NSMutableDictionary new];
      for (NSDictionary<NSString *, id> *valueEntry in valueEntries) {
        NSDictionary<NSString *, id> *value = [FBSDKTypeUtility dictionaryValue:valueEntry];
        NSString *currency = [FBSDKTypeUtility dictionary:value objectForKey:CURRENCY_KEY ofType:NSString.class];
        NSNumber *amount = [FBSDKTypeUtility dictionary:value objectForKey:AMOUNT_KEY ofType:NSNumber.class];
        if (!currency || amount == nil) {
          return nil;
        }
        [FBSDKTypeUtility dictionary:valueDict setObject:amount forKey:[currency uppercaseString]];
      }
      _values = [valueDict copy];
    }
  }
  return self;
}

- (instancetype)initWithEventName:(NSString *)eventName
                           values:(NSDictionary<NSString *, NSNumber *> *)values
{
  if ((self = [super init])) {
    _eventName = eventName;
    _values = values;
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
  NSString *eventName = [decoder decodeObjectOfClass:NSString.class forKey:EVENT_NAME_KEY];
  NSDictionary<NSString *, NSNumber *> *values = [decoder decodeObjectOfClass:NSDictionary.class forKey:VALUES_KEY];
  return [self initWithEventName:eventName values:values];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_eventName forKey:EVENT_NAME_KEY];
  if (_values) {
    [encoder encodeObject:_values forKey:VALUES_KEY];
  }
}

 #pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

@end

#endif
