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

 #import "FBSDKAEMRule.h"

 #import "FBSDKCoreKit+Internal.h"

static NSString *const CONVERSION_VALUE_KEY = @"conversion_value";
static NSString *const PRIORITY_KEY = @"priority";
static NSString *const EVENTS_KEY = @"events";

@implementation FBSDKAEMRule

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    NSNumber *conversionValue = [FBSDKTypeUtility dictionary:dict objectForKey:CONVERSION_VALUE_KEY ofType:NSNumber.class];
    NSNumber *priority = [FBSDKTypeUtility dictionary:dict objectForKey:PRIORITY_KEY ofType:NSNumber.class];
    NSArray<FBSDKAEMEvent *> *events = [FBSDKAEMRule parseEvents:[FBSDKTypeUtility dictionary:dict objectForKey:EVENTS_KEY ofType:NSArray.class]];
    if (conversionValue == nil || priority == nil || 0 == events.count) {
      return nil;
    }
    _conversionValue = conversionValue.integerValue;
    _priority = priority.integerValue;
    _events = events;
  }
  return self;
}

- (instancetype)initWithConversionValue:(NSInteger)conversionValue
                               priority:(NSInteger)priority
                                 events:(NSArray<FBSDKAEMEvent *> *)events
{
  if ((self = [super init])) {
    _conversionValue = conversionValue;
    _priority = priority;
    _events = events;
  }
  return self;
}

- (BOOL)isMatchedWithRecordedEvents:(nullable NSSet<NSString *> *)recordedEvents
                     recordedValues:(nullable NSDictionary<NSString *, NSDictionary *> *)recordedValues
{
  for (FBSDKAEMEvent *event in self.events) {
    // Check if event name matches
    if (![recordedEvents containsObject:event.eventName]) {
      return NO;
    }
    // Check if event value matches when values is not nil
    if (event.values) {
      NSDictionary<NSString *, NSNumber *> *recordedEventValues = [FBSDKTypeUtility dictionary:recordedValues objectForKey:event.eventName ofType:NSDictionary.class];
      if (![self _isMatchedWithValues:event.values recordedEventValues:recordedEventValues]) {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)_isMatchedWithValues:(NSDictionary<NSString *, NSNumber *> *)values
         recordedEventValues:(nullable NSDictionary<NSString *, NSNumber *> *)recordedEventValues
{
  for (NSString *currency in values) {
    NSNumber *valueInMapping = [FBSDKTypeUtility dictionary:values objectForKey:currency ofType:NSNumber.class];
    NSNumber *value = [FBSDKTypeUtility dictionary:recordedEventValues objectForKey:currency ofType:NSNumber.class];
    if (value.doubleValue >= valueInMapping.doubleValue) {
      return YES;
    }
  }
  return NO;
}

+ (nullable NSArray<FBSDKAEMEvent *> *)parseEvents:(nullable NSArray<NSDictionary<NSString *, id> *> *)events
{
  if (0 == events.count) {
    return nil;
  }
  NSMutableArray<FBSDKAEMEvent *> *parsedEvents = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *eventEntry in events) {
    FBSDKAEMEvent *event = [[FBSDKAEMEvent alloc] initWithJSON:eventEntry];
    if (!event) {
      return nil;
    }
    [FBSDKTypeUtility array:parsedEvents addObject:event];
  }
  return [parsedEvents copy];
}

 #pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSInteger conversionValue = [decoder decodeIntegerForKey:CONVERSION_VALUE_KEY];
  NSInteger priority = [decoder decodeIntegerForKey:PRIORITY_KEY];
  NSArray<FBSDKAEMEvent *> *events = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBSDKAEMEvent.class]] forKey:EVENTS_KEY];
  return [self initWithConversionValue:conversionValue priority:priority events:events];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInteger:_conversionValue forKey:CONVERSION_VALUE_KEY];
  [encoder encodeInteger:_priority forKey:PRIORITY_KEY];
  [encoder encodeObject:_events forKey:EVENTS_KEY];
}

 #pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
  return self;
}

@end

#endif
