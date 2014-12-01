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

@interface FBKeychainStore : NSObject

@property (nonatomic, readonly, copy) NSString *service;
@property (nonatomic, readonly, copy) NSString *accessGroup;

- (instancetype)initWithService:(NSString *)service;
- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup;

- (BOOL)setDictionary:(NSDictionary *)value forKey:(NSString *)key;
- (BOOL)setDictionary:(NSDictionary *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (NSDictionary *)dictionaryForKey:(NSString *)key;

- (BOOL)setString:(NSString *)value forKey:(NSString *)key;
- (BOOL)setString:(NSString *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (NSString *)stringForKey:(NSString *)key;

- (BOOL)setData:(NSData *)value forKey:(NSString *)key;
- (BOOL)setData:(NSData *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility;
- (NSData *)dataForKey:(NSString *)key;

// hook for subclasses to override keychain query construction.
- (NSMutableDictionary *)queryForKey:(NSString *)key;

@end
