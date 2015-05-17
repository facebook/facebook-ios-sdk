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

#import "SUCache.h"

#import <Foundation/Foundation.h>
#import <Security/Security.h>

static NSString *const kCacheVersion = @"v2";

#define USER_DEFAULTS_INSTALLED_KEY @"com.facebook.sdk.samples.switchuser.installed"

@implementation SUCache

+ (void)initialize
{
    if (self == [SUCache class]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_INSTALLED_KEY]) {
            [SUCache clearCache];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_INSTALLED_KEY];
    }
}

+ (NSString *)keychainKeyForSlot:(NSInteger)slot
{
    return [NSString stringWithFormat:@"%@%lu", kCacheVersion, (unsigned long)slot];
}

+ (void)saveItem:(SUCacheItem *)item slot:(NSInteger)slot
{
    // Delete any old values
    [self deleteItemInSlot:slot];

    NSString *key = [self keychainKeyForSlot:slot];
    NSString *error;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:item];
    if (error) {
        NSLog(@"Failed to serialize item for insertion into keychain:%@", error);
        return;
    }
    NSDictionary *keychainQuery = @{
                                    (__bridge id)kSecAttrAccount : key,
                                    (__bridge id)kSecValueData : data,
                                    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                    };
    OSStatus result = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, nil);
    if(result != noErr){
        NSLog(@"Failed to add item to keychain");
        return;
    }
}

+ (void)deleteItemInSlot:(NSInteger)slot
{
    NSString *key = [self keychainKeyForSlot:slot];
    NSDictionary *keychainQuery = @{
                                    (__bridge id)kSecAttrAccount : key,
                                    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                    };
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef) keychainQuery);
    if(result != noErr){
        return;
    }
}

+ (SUCacheItem *)itemForSlot:(NSInteger)slot
{
    NSString *key = [self keychainKeyForSlot:slot];
    NSDictionary *keychainQuery = @{
                                    (__bridge id)kSecAttrAccount : key,
                                    (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                                    (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword
                                    };

    CFDataRef serializedDictionaryRef;
    OSStatus result = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&serializedDictionaryRef);
    if(result == noErr) {
        NSData *data = (__bridge_transfer NSData*)serializedDictionaryRef;
        if (data) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    return nil;
}

+ (void)clearCache
{
    NSArray *secItemClasses = @[(__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecClassInternetPassword,
                                (__bridge id)kSecClassCertificate,
                                (__bridge id)kSecClassKey,
                                (__bridge id)kSecClassIdentity];
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass: secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
}

@end
