/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMEvent.h"

#import "FBCoreKitBasicsImportForAEMKit.h"

static NSString *const EVENT_NAME_KEY = @"event_name";
static NSString *const VALUES_KEY = @"values";
static NSString *const CURRENCY_KEY = @"currency";
static NSString *const AMOUNT_KEY = @"amount";

@implementation FBAEMEvent

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
  NSSet<Class> *classes = [NSSet setWithArray:@[
    NSDictionary.class,
    NSNumber.class,
    NSString.class,
                           ]];
  NSString *eventName = [decoder decodeObjectOfClass:NSString.class forKey:EVENT_NAME_KEY];
  NSDictionary<NSString *, NSNumber *> *values = [decoder decodeObjectOfClasses:classes forKey:VALUES_KEY];
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
