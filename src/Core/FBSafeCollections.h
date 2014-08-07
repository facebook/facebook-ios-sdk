/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

/*!
 Provides alternative getter methods, that do not throw exceptions and return objects only of expected kind.
 */
@interface FBSafeCollections : NSObject

#pragma mark - Array

/*!
 @abstract
 Looks up for dictionary at given index.
 If index is out of range - nil is returned and no exception is generated.
 If object at that index is not kind of NSDictionary - this method returns nil.

 @param index any unsigned integer, non-existing index will not cause exceptions.

 @param array Array to look into, should be kind of NSArray, if it's not - this method returns nil.
 */
+ (NSDictionary *)dictionaryAtIndex:(NSUInteger)index fromArray:(NSArray *)array;

/*!
 @abstract
 Looks up for array at given index.
 If index is out of range - nil is returned and no exception is generated.
 If object at that index is not kind of NSArray - this method returns nil.

 @param index any unsigned integer, non-existing index will not cause exceptions.

 @param array Array to look into, should be kind of NSArray, if it's not - this method returns nil.
 */
+ (NSArray *)arrayAtIndex:(NSUInteger)index fromArray:(NSArray *)array;

/*!
 @abstract
 Looks up for string at given index.
 If index is out of range - nil is returned and no exception is generated.
 If object at that index is not kind of NSString - this method returns nil.

 @param index any unsigned integer, non-existing index will not cause exceptions.

 @param array Array to look into, should be kind of NSArray, if it's not - this method returns nil.
 */
+ (NSString *)stringAtIndex:(NSUInteger)index fromArray:(NSArray *)array;

/*!
 @abstract
 Looks up for number at given index.
 If index is out of range - nil is returned and no exception is generated.
 If object at that index is not kind of NSNumber - this method returns nil.

 @param index any unsigned integer, non-existing index will not cause exceptions.

 @param array Array to look into, should be kind of NSArray, if it's not - this method returns nil.
 */
+ (NSNumber *)numberAtIndex:(NSUInteger)index fromArray:(NSArray *)array;

/*!
 @abstract
 Looks up for instance of given class at given index.
 If index is out of range - nil is returned and no exception is generated.
 If object at that index is not kind of given class - this method returns nil.

 @param index any unsigned integer, non-existing index will not cause exceptions.

 @param array Array to look into, should be kind of NSArray, if it's not - this method returns nil.
 */
+ (id)objectOfKind:(Class)cls atIndex:(NSUInteger)index fromArray:(NSArray *)array;

#pragma mark - Dictionary

/*!
 @abstract
 Looks up for dictionary for given key.
 If object for that key is not kind of NSDictionary - this method returns nil.

 @param key dictionary key to look for.

 @param dictionary Dictionary to look into, should be kind of NSDictionary, if it's not - this method returns nil.
 */
+ (NSDictionary *)dictionaryForKey:(id)key fromDictionary:(NSDictionary *)dictionary;

/*!
 @abstract
 Looks up for array for given key.
 If object for that key is not kind of NSArray - this method returns nil.

 @param key dictionary key to look for.

 @param dictionary Dictionary to look into, should be kind of NSDictionary, if it's not - this method returns nil.
 */
+ (NSArray *)arrayForKey:(id)key fromDictionary:(NSDictionary *)dictionary;

/*!
 @abstract
 Looks up for string for given key.
 If object for that key is not kind of NSString - this method returns nil.

 @param key dictionary key to look for.

 @param dictionary Dictionary to look into, should be kind of NSDictionary, if it's not - this method returns nil.
 */
+ (NSString *)stringForKey:(id)key fromDictionary:(NSDictionary *)dictionary;

/*!
 @abstract
 Looks up for number at for given key.
 If index is out of range - nil is returned and no exception is generated.
 If object at that index is not kind of NSNumber - this method returns nil.

 @param key dictionary key to look for.

 @param dictionary Dictionary to look into, should be kind of NSDictionary, if it's not - this method returns nil.
 */
+ (NSNumber *)numberForKey:(id)key fromDictionary:(NSDictionary *)dictionary;

/*!
 @abstract
 Looks up for instance of given class for given key.
 If object at that index is not kind of given class - this method returns nil.

 @param key dictionary key to look for.

 @param dictionary Dictionary to look into, should be kind of NSDictionary, if it's not - this method returns nil.
 */
+ (id)objectOfKind:(Class)cls forKey:(id)key fromDictionary:(NSDictionary *)dictionary;

@end
