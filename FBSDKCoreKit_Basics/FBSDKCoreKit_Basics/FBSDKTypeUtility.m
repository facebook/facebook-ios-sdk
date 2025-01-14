/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTypeUtility.h"

@implementation FBSDKTypeUtility

#pragma mark - Class Methods

+ (nullable NSArray<id> *)arrayValue:(nullable id)object
{
  if (!object) {
    return nil;
  }
  return (NSArray<id> *)[self _objectValue:object ofClass:NSArray.class];
}

+ (nullable id)array:(NSArray<id> *)array objectAtIndex:(NSUInteger)index
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

+ (BOOL)boolValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    // @0 or @NO returns NO, otherwise YES
    return ((NSNumber *)object).boolValue;
  }

  if ([object isKindOfClass:NSString.class]) {
    // Returns YES on encountering one of "Y", "y", "T", "t", or a digit 1-9, otherwise NO
    return ((NSString *)object).boolValue;
  }

  return ([self objectValue:object] != nil);
}

+ (nullable NSDictionary<NSString *, id> *)dictionaryValue:(nullable id)object
{
  if (!object) {
    return nil;
  }
  return (NSDictionary<NSString *, id> *)[self _objectValue: object ofClass:[NSDictionary<NSString *, id> class]];
}

+ (nullable id)dictionary:(NSDictionary<NSString *, id> *)dictionary objectForKey:(NSString *)key ofType:(Class)type
{
  id potentialValue = [self dictionaryValue:dictionary][key];

  if ([potentialValue isKindOfClass:type]) {
    return potentialValue;
  }

  return nil;
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
  }

  if ([object isKindOfClass:NSString.class]) {
    return ((NSString *)object).integerValue;
  }

  return 0;
}

+ (double)doubleValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).doubleValue;
  }

  if ([object isKindOfClass:NSString.class]) {
    return ((NSString *)object).doubleValue;
  }

  return 0;
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
  }

  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).stringValue;
  }

  if ([object isKindOfClass:NSURL.class]) {
    return ((NSURL *)object).absoluteString;
  }

  return nil;
}

+ (NSTimeInterval)timeIntervalValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).doubleValue;
  }

  if ([object isKindOfClass:NSString.class]) {
    return ((NSString *)object).doubleValue;
  }

  return 0;
}

+ (NSUInteger)unsignedIntegerValue:(id)object
{
  if ([object isKindOfClass:NSNumber.class]) {
    return ((NSNumber *)object).unsignedIntegerValue;
  }

  // there is no direct support for strings containing unsigned values > NSIntegerMax - not worth writing ourselves
  // right now, so just cap unsigned values at NSIntegerMax until we have a need for larger
  NSInteger integerValue = [self integerValue:object];
  if (integerValue < 0) {
    integerValue = 0;
  }
  return (NSUInteger)integerValue;
}

+ (nullable NSURL *)coercedToURLValue:(id)object
{
  if ([object isKindOfClass:NSURL.class]) {
    return (NSURL *)object;
  }

  if ([object isKindOfClass:NSString.class]) {
    return [NSURL URLWithString:(NSString *)object];
  }

  return nil;
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
