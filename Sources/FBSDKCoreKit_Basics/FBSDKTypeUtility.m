/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTypeUtility.h"

@implementation FBSDKTypeUtility

#pragma mark - Class Methods

+ (nullable NSArray *)arrayValue:(id)object
{
  return (NSArray *)[self _objectValue:object ofClass:NSArray.class];
}

+ (nullable id)array:(NSArray *)array objectAtIndex:(NSUInteger)index
{
  if ([self arrayValue:array] && index < array.count) {
    return array[index];
  }

  return nil;
}

+ (void)array:(NSMutableArray *)array addObject:(nullable id)object
{
  if (object && [array isKindOfClass:NSMutableArray.class]) {
    [array addObject:object];
  }
}

+ (void)array:(NSMutableArray *)array addObject:(nullable id)object atIndex:(NSUInteger)index
{
  if (object && [array isKindOfClass:NSMutableArray.class]) {
    if (index < array.count) {
      [array insertObject:object atIndex:index];
    } else if (index == array.count) {
      [array addObject:object];
    }
  }
}

+ (BOOL)boolValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    // @0 or @NO returns NO, otherwise YES
    return ((NSNumber *)object).boolValue;
  } else if ([object isKindOfClass:NSString.class]) {
    // Returns YES on encountering one of "Y", "y", "T", "t", or a digit 1-9, otherwise NO
    return ((NSString *)object).boolValue;
  } else {
    return ([self objectValue:object] != nil);
  }
}

+ (nullable NSDictionary<NSString *, id> *)dictionaryValue:(id)object
{
  return (NSDictionary<NSString *, id> *)[self _objectValue: object ofClass:[NSDictionary<NSString *, id> class]];
}

+ (nullable id)dictionary:(NSDictionary<NSString *, id> *)dictionary objectForKey:(NSString *)key ofType:(Class)type
{
  id potentialValue = [self dictionaryValue:dictionary][key];

  if ([potentialValue isKindOfClass:type]) {
    return potentialValue;
  } else {
    return nil;
  }
}

+ (void)dictionary:(NSMutableDictionary *)dictionary
         setObject:(nullable id)object
            forKey:(nullable id<NSCopying>)key
{
  if (object && key) {
    dictionary[key] = object;
  }
}

+ (void)dictionary:(NSDictionary<NSString *, id> *)dictionary enumerateKeysAndObjectsUsingBlock:(void(NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block
{
  NSDictionary<NSString *, id> *validDictionary = [self dictionaryValue:dictionary];
  if (validDictionary) {
    [validDictionary enumerateKeysAndObjectsUsingBlock:block];
  }
}

+ (NSNumber *)numberValue:(id)object
{
  return [self _objectValue:object ofClass:NSNumber.class];
}

+ (NSInteger)integerValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).integerValue;
  } else if ([object isKindOfClass:NSString.class]) {
    return ((NSString *)object).integerValue;
  } else {
    return 0;
  }
}

+ (double)doubleValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).doubleValue;
  } else if ([object isKindOfClass:NSString.class]) {
    return ((NSString *)object).doubleValue;
  } else {
    return 0;
  }
}

+ (NSString *)stringValueOrNil:(id)object
{
  return [self _objectValue:object ofClass:NSString.class];
}

+ (nullable id)objectValue:(id)object
{
  return ([object isKindOfClass:NSNull.class] ? nil : object);
}

+ (nullable NSString *)coercedToStringValue:(id)object
{
  if ([object isKindOfClass:NSString.class]) {
    return (NSString *)object;
  } else if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).stringValue;
  } else if ([object isKindOfClass:NSURL.class]) {
    return ((NSURL *)object).absoluteString;
  } else {
    return nil;
  }
}

+ (NSTimeInterval)timeIntervalValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).doubleValue;
  } else if ([object isKindOfClass:NSString.class]) {
    return ((NSString *)object).doubleValue;
  } else {
    return 0;
  }
}

+ (NSUInteger)unsignedIntegerValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).unsignedIntegerValue;
  } else {
    // there is no direct support for strings containing unsigned values > NSIntegerMax - not worth writing ourselves
    // right now, so just cap unsigned values at NSIntegerMax until we have a need for larger
    NSInteger integerValue = [self integerValue:object];
    if (integerValue < 0) {
      integerValue = 0;
    }
    return (NSUInteger)integerValue;
  }
}

+ (nullable NSURL *)coercedToURLValue:(id)object
{
  if ([object isKindOfClass:NSURL.class]) {
    return (NSURL *)object;
  } else if ([object isKindOfClass:NSString.class]) {
    return [NSURL URLWithString:(NSString *)object];
  } else {
    return nil;
  }
}

+ (BOOL)isValidJSONObject:(id)obj
{
  return [NSJSONSerialization isValidJSONObject:obj];
}

+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError *__autoreleasing _Nullable *)error
{
  NSData *data;

  @try {
    data = [NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
  } @catch (NSException *exception) {
    NSLog(@"FBSDKJSONSerialization - dataWithJSONObject:options:error failed: %@", exception.reason);
  }
  return data;
}

+ (nullable id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError *__autoreleasing _Nullable *)error
{
  if (![data isKindOfClass:NSData.class]) {
    return nil;
  }

  id object;
  @try {
    object = [NSJSONSerialization JSONObjectWithData:data options:opt error:error];
  } @catch (NSException *exception) {
    NSLog(@"FBSDKJSONSerialization - JSONObjectWithData:options:error failed: %@", exception.reason);
  }
  return object;
}

+ (id)_objectValue:(id)object ofClass:(Class)expectedClass
{
  return ([object isKindOfClass:expectedClass] ? object : nil);
}

@end
