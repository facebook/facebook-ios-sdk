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

/**
 * Contains code from UICKeyChainStore
 *
 * Copyright (c) 2011 kishikawa katsumi
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "FBKeychainStore.h"

#import "FBDynamicFrameworkLoader.h"

@implementation FBKeychainStore

- (instancetype)initWithService:(NSString *)service {
    return [self initWithService:service accessGroup:nil];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    if ((self = [super init])) {
        _service = service ? [service copy] : [[[NSBundle mainBundle] bundleIdentifier] retain];
        _accessGroup = [accessGroup copy];
        NSAssert(_service, @"Keychain must be initialized with service");
    }

    return self;
}

- (void)dealloc {
    [_accessGroup release];
    [_service release];
    [super dealloc];
}

- (BOOL)setDictionary:(NSDictionary *)value forKey:(NSString *)key {
    return [self setDictionary:value forKey:key accessibility:Nil];
}

- (BOOL)setDictionary:(NSDictionary *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    NSData *data = value == nil ? nil : [NSKeyedArchiver archivedDataWithRootObject:value];
    return [self setData:data forKey:key accessibility:accessibility];
}

- (NSDictionary *)dictionaryForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (!data) {
        return nil;
    }

    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    return dict;
}

- (BOOL)setString:(NSString *)value forKey:(NSString *)key {
    return [self setString:value forKey:key accessibility:Nil];
}

- (BOOL)setString:(NSString *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [self setData:data forKey:key accessibility:accessibility];
}

- (NSString *)stringForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (!data) {
        return nil;
    }

    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

- (BOOL)setData:(NSData *)value forKey:(NSString *)key {
    return [self setData:value forKey:key accessibility:Nil];
}

- (BOOL)setData:(NSData *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility {
    if (!key) {
        return NO;
    }

    NSMutableDictionary *query = [self queryForKey:key];

    OSStatus status;
    if (value) {
        NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
        [attributesToUpdate setObject:value forKey:[FBDynamicFrameworkLoader loadkSecValueData]];

        status = fbdfl_SecItemUpdate((CFDictionaryRef)query, (CFDictionaryRef)attributesToUpdate);
        if (status == errSecItemNotFound) {
#if TARGET_OS_IPHONE || (defined(MAC_OS_X_VERSION_10_9) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9)
            if (accessibility) {
                [query setObject:accessibility forKey:[FBDynamicFrameworkLoader loadkSecAttrAccessible]];
            }
#endif
            [query setObject:value forKey:[FBDynamicFrameworkLoader loadkSecValueData]];

            status = fbdfl_SecItemAdd((CFDictionaryRef)query, NULL);
        }
    } else {
        status = fbdfl_SecItemDelete((CFDictionaryRef)query);
        if (status == errSecItemNotFound) {
            status = errSecSuccess;
        }
    }

    return (status == errSecSuccess);
}

- (NSData *)dataForKey:(NSString *)key {
    if (!key) {
        return nil;
    }

    NSMutableDictionary *query = [self queryForKey:key];
    [query setObject:(id)kCFBooleanTrue forKey:[FBDynamicFrameworkLoader loadkSecReturnData]];
    [query setObject:[FBDynamicFrameworkLoader loadkSecMatchLimitOne] forKey:[FBDynamicFrameworkLoader loadkSecMatchLimit]];

    CFTypeRef data = nil;
    OSStatus status = fbdfl_SecItemCopyMatching((CFDictionaryRef)query, &data);
    if (status != errSecSuccess) {
        return nil;
    }

    if (!data || CFGetTypeID(data) != CFDataGetTypeID()) {
        return nil;
    }

    NSData *ret = [NSData dataWithData:data];
    CFRelease(data);

    return ret;
}

- (NSMutableDictionary *)queryForKey:(NSString *)key {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:[FBDynamicFrameworkLoader loadkSecClassGenericPassword] forKey:[FBDynamicFrameworkLoader loadkSecClass]];
    [query setObject:_service forKey:[FBDynamicFrameworkLoader loadkSecAttrService]];
    [query setObject:key forKey:[FBDynamicFrameworkLoader loadkSecAttrAccount]];
#if !TARGET_IPHONE_SIMULATOR
    if (_accessGroup) {
        [query setObject:_accessGroup forKey:[FBDynamicFrameworkLoader loadkSecAttrAccessGroup]];
    }
#endif

    return query;
}

@end
