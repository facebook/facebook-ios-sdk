/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TypeUtility)
@interface FBSDKTypeUtility : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Returns an NSArray if the provided object is an NSArray, otherwise returns nil.
+ (nullable NSArray *)arrayValue:(id)object;

/**
 Return an object at a given index if the index is valid, otherwise return nil
 @param array The array to retrieve the object from.
 @param index The index to retrieve the object from.
 */
+ (nullable id)array:(NSArray *)array objectAtIndex:(NSUInteger)index;

/**
 Adds an object to an array if it is not nil.
 @param array The array to add the object to.
 @param object The object to add to the array.
 */
+ (void)array:(NSMutableArray *)array addObject:(nullable id)object;

/**
 Adds an object to an array at a given index if the object is not nil and the index is available.
 Will override objects if  they exist.
 @param array The array to add the object to.
 @param object The object to add to the array.
 @param index The index to try and insert the object into
 */
+ (void)array:(NSMutableArray *)array addObject:(nullable id)object atIndex:(NSUInteger)index;

/// Returns a BOOL if the provided object is a BOOL, otherwise returns nil.
+ (BOOL)boolValue:(id)object;

/// Returns an NSDictionary<NSString *, id> if the provided object is an NSDictionary, otherwise returns nil.
+ (nullable NSDictionary<NSString *, id> *)dictionaryValue:(id)object;

/// Returns an object for a given key in the provided dictionary if it matches the stated type
+ (nullable id)dictionary:(NSDictionary<NSString *, id> *)dictionary objectForKey:(NSString *)key ofType:(Class)type;

/**
 Sets an object for a key in a dictionary if it is not nil.
 @param dictionary The dictionary to set the value for.
 @param object The value to set.
 @param key The key to set the value for.
 */
+ (void)dictionary:(NSMutableDictionary *)dictionary
         setObject:(nullable id)object
            forKey:(nullable id<NSCopying>)key;

/// Checks if an object is a valid dictionary type before enumerating its keys and objects
+ (void)dictionary:(NSDictionary<NSString *, id> *)dictionary enumerateKeysAndObjectsUsingBlock:(void(NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block;

/// Returns an NSInteger if the provided object is an NSInteger, otherwise returns nil.
+ (NSInteger)integerValue:(id)object;

/// Returns a double if the provided object is a double, otherwise returns 0.
+ (double)doubleValue:(id)object;

/// Returns an NSNumber if the provided object is an NSNumber, otherwise returns nil.
+ (NSNumber *)numberValue:(id)object;

/// Returns an NSString if the provided object is an NSString, otherwise returns nil.
+ (NSString *)stringValueOrNil:(id)object;

/// Returns the provided object if it is non-null
+ (nullable id)objectValue:(id)object;

/// Returns an NSString if the provided object can be coered to an NSString, otherwise returns nil.
+ (nullable NSString *)coercedToStringValue:(id)object;

/// Returns an NSTimeInterval if the provided object is an NSTimeInterval, otherwise returns nil.
+ (NSTimeInterval)timeIntervalValue:(id)object;

/// Returns an NSUInteger if the provided object is an NSUInteger, otherwise returns nil.
+ (NSUInteger)unsignedIntegerValue:(id)object;

/// Returns an NSURL if the provided object is an NSURL; will attempt to create an NSURL if the object is an NSString; returns nil otherwise.
+ (nullable NSURL *)coercedToURLValue:(id)object;

/*
 Lightweight wrapper around Foundation's isValidJSONObject:

 Returns YES if the given object can be converted to JSON data, NO otherwise.
 Calling this method or attempting a conversion are the definitive ways to tell if a given object can be converted to JSON data.
 */
+ (BOOL)isValidJSONObject:(id)obj;

/*
 Lightweight safety wrapper around Foundation's NSJSONSerialization:dataWithJSONObject:options:error:

 Generate JSON data from a Foundation object.
 If the object will not produce valid JSON then null is returned.
 Setting the NSJSONWritingPrettyPrinted option will generate JSON with whitespace designed to make the output more readable.
 If that option is not set, the most compact possible JSON will be generated.
 If an error occurs, the error parameter will be set and the return value will be nil.
 The resulting data is a encoded in UTF-8.
 */
+ (nullable NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error;

/*
 Lightweight safety wrapper around Foundation's NSJSONSerialization:JSONObjectWithData:options:error:

 Create a Foundation object from JSON data.
 Set the NSJSONReadingAllowFragments option if the parser should allow top-level objects that are not an NSArray or NSDictionary.
 Setting the NSJSONReadingMutableContainers option will make the parser generate mutable NSArrays and NSDictionaries.
 Setting the NSJSONReadingMutableLeaves option will make the parser generate mutable NSString objects.
 If an error occurs during the parse, then the error parameter will be set and the result will be nil.
 The data must be in one of the 5 supported encodings listed in the JSON specification: UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE.
 The data may or may not have a BOM.
 The most efficient encoding to use for parsing is UTF-8, so if you have a choice in encoding the data passed to this method, use UTF-8.
 */
+ (nullable id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
