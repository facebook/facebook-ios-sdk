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

#import "FBSafeCollections.h"

@implementation FBSafeCollections

+ (NSDictionary *)dictionaryAtIndex:(NSUInteger)index fromArray:(NSArray *)array
{
    return [self objectOfKind:[NSDictionary class] atIndex:index fromArray:array];
}

+ (NSArray *)arrayAtIndex:(NSUInteger)index fromArray:(NSArray *)array
{
    return [self objectOfKind:[NSArray class] atIndex:index fromArray:array];
}

+ (NSString *)stringAtIndex:(NSUInteger)index fromArray:(NSArray *)array
{
    return [self objectOfKind:[NSString class] atIndex:index fromArray:array];
}

+ (NSNumber *)numberAtIndex:(NSUInteger)index fromArray:(NSArray *)array;
{
    return [self objectOfKind:[NSNumber class] atIndex:index fromArray:array];
}

+ (id)objectOfKind:(Class)cls atIndex:(NSUInteger)index fromArray:(NSArray *)array
{
    if (![array isKindOfClass:[NSArray class]] || array.count <= index) {
        return nil;
    }

    id obj = [array objectAtIndex:index];
    if (![obj isKindOfClass:cls]) {
        return nil;
    }

    return obj;
}

#pragma mark - Dictionary

+ (NSDictionary *)dictionaryForKey:(id)key fromDictionary:(NSDictionary *)dictionary
{
    return [self objectOfKind:[NSDictionary class] forKey:key fromDictionary:dictionary];
}

+ (NSArray *)arrayForKey:(id)key fromDictionary:(NSDictionary *)dictionary
{
    return [self objectOfKind:[NSArray class] forKey:key fromDictionary:dictionary];
}

+ (NSString *)stringForKey:(id)key fromDictionary:(NSDictionary *)dictionary
{
    return [self objectOfKind:[NSString class] forKey:key fromDictionary:dictionary];
}

+ (NSNumber *)numberForKey:(id)key fromDictionary:(NSDictionary *)dictionary
{
    return [self objectOfKind:[NSNumber class] forKey:key fromDictionary:dictionary];
}

+ (id)objectOfKind:(Class)cls forKey:(id)key fromDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    id obj = [dictionary objectForKey:key];

    if (![obj isKindOfClass:cls]) {
        return nil;
    }

    return obj;
}

@end
