/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMRule.h"

#import "FBCoreKitBasicsImportForAEMKit.h"

static NSString *const CONVERSION_VALUE_KEY = @"conversion_value";
static NSString *const PRIORITY_KEY = @"priority";
static NSString *const EVENTS_KEY = @"events";

@implementation FBAEMRule

- (nullable instancetype)initWithJSON:(nullable NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    dict = [FBSDKTypeUtility dictionaryValue:dict];
    if (!dict) {
      return nil;
    }
    NSNumber *conversionValue = [FBSDKTypeUtility dictionary:dict objectForKey:CONVERSION_VALUE_KEY ofType:NSNumber.class];
    NSNumber *priority = [FBSDKTypeUtility dictionary:dict objectForKey:PRIORITY_KEY ofType:NSNumber.class];
    NSArray<FBAEMEvent *> *events = [FBAEMRule parseEvents:[FBSDKTypeUtility dictionary:dict objectForKey:EVENTS_KEY ofType:NSArray.class]];
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
                                 events:(NSArray<FBAEMEvent *> *)events
{
  if ((self = [super init])) {
    _conversionValue = conversionValue;
    _priority = priority;
    _events = events;
  }
  return self;
}

- (BOOL)containsEvent:(NSString *)eventName
{
  for (FBAEMEvent *event in self.events) {
    if ([event.eventName isEqualToString:eventName]) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isMatchedWithRecordedEvents:(nullable NSSet<NSString *> *)recordedEvents
                     recordedValues:(nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)recordedValues
{
  for (FBAEMEvent *event in self.events) {
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

+ (nullable NSArray<FBAEMEvent *> *)parseEvents:(NSArray<NSDictionary<NSString *, id> *> *)events
{
  if (0 == events.count) {
    return nil;
  }
  NSMutableArray<FBAEMEvent *> *parsedEvents = [NSMutableArray new];
  for (NSDictionary<NSString *, id> *eventEntry in events) {
    FBAEMEvent *event = [[FBAEMEvent alloc] initWithJSON:eventEntry];
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
  NSArray<FBAEMEvent *> *events = [decoder decodeObjectOfClasses:[NSSet setWithArray:@[NSArray.class, FBAEMEvent.class]] forKey:EVENTS_KEY];
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
