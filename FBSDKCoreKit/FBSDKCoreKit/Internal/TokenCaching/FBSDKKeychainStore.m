/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKKeychainStore.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKLogger.h"
#import "FBSDKUnarchiverProvider.h"

@implementation FBSDKKeychainStore

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup
{
  if ((self = [super init])) {
    _service = service ? [service copy] : NSBundle.mainBundle.bundleIdentifier;
    _accessGroup = [accessGroup copy];
    NSAssert(_service, @"Keychain must be initialized with service");
  }

  return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (BOOL)setDictionary:(NSDictionary<NSString *, id> *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility
{
  NSData *data = value == nil ? nil : [NSKeyedArchiver archivedDataWithRootObject:value];
  return [self setData:data forKey:key accessibility:accessibility];
}

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)key
{
  NSData *data = [self dataForKey:key];
  if (!data) {
    return nil;
  }
  id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createInsecureUnarchiverFor:data];

  NSDictionary<NSString *, id> *dict = nil;
  @try {
    dict = [unarchiver decodeObjectOfClass:NSDictionary.class forKey:NSKeyedArchiveRootObjectKey];
  } @catch (NSException *ex) {
    // ignore decoding exceptions
  }
  return dict;
}

#pragma clang diagnostic pop

- (BOOL)setString:(NSString *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility
{
  NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
  return [self setData:data forKey:key accessibility:accessibility];
}

- (nullable NSString *)stringForKey:(NSString *)key
{
  NSData *data = [self dataForKey:key];
  if (!data) {
    return nil;
  }

  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)setData:(nullable NSData *)value forKey:(NSString *)key accessibility:(CFTypeRef)accessibility
{
  if (!key) {
    return NO;
  }

#if TARGET_OS_SIMULATOR
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational
                         logEntry:@"Falling back to storing access token in NSUserDefaults because of simulator bug"];
  [NSUserDefaults.standardUserDefaults setObject:value forKey:key];

  return [NSUserDefaults.standardUserDefaults synchronize];
#else
  NSMutableDictionary<NSString *, id> *query = [self queryForKey:key];

  OSStatus status;
  if (value) {
    NSMutableDictionary<NSString *, id> *attributesToUpdate = [NSMutableDictionary dictionary];
    [attributesToUpdate setObject:value forKey:[FBSDKDynamicFrameworkLoader loadkSecValueData]];

    status = fbsdkdfl_SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    if (status == errSecItemNotFound) {
    #if !TARGET_OS_TV
      if (@available(macOS 10.9, iOS 8, *)) {
        if (accessibility) {
          [query setObject:(__bridge id)(accessibility) forKey:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessible]];
        }
      }
    #endif
      [query setObject:value forKey:[FBSDKDynamicFrameworkLoader loadkSecValueData]];

      status = fbsdkdfl_SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
  } else {
    status = fbsdkdfl_SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecItemNotFound) {
      status = errSecSuccess;
    }
  }

  return (status == errSecSuccess);
#endif
}

- (nullable NSData *)dataForKey:(NSString *)key
{
  if (!key) {
    return nil;
  }

#if TARGET_OS_SIMULATOR
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational
                         logEntry:@"Falling back to loading access token from NSUserDefaults because of simulator bug"];
  return [NSUserDefaults.standardUserDefaults dataForKey:key];
#else
  NSMutableDictionary<NSString *, id> *query = [self queryForKey:key];
  [query setObject:(id)kCFBooleanTrue forKey:[FBSDKDynamicFrameworkLoader loadkSecReturnData]];
  [query setObject:[FBSDKDynamicFrameworkLoader loadkSecMatchLimitOne] forKey:[FBSDKDynamicFrameworkLoader loadkSecMatchLimit]];

  CFTypeRef data = nil;
  OSStatus status = fbsdkdfl_SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
  if (status != errSecSuccess) {
    return nil;
  }

  if (!data || CFGetTypeID(data) != CFDataGetTypeID()) {
    return nil;
  }

  NSData *ret = [NSData dataWithData:(__bridge NSData *)(data)];
  CFRelease(data);

  return ret;
#endif
}

- (NSMutableDictionary<NSString *, id> *)queryForKey:(NSString *)key
{
  NSMutableDictionary<NSString *, id> *query = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:query setObject:[FBSDKDynamicFrameworkLoader loadkSecClassGenericPassword] forKey:[FBSDKDynamicFrameworkLoader loadkSecClass]];
  [FBSDKTypeUtility dictionary:query setObject:_service forKey:[FBSDKDynamicFrameworkLoader loadkSecAttrService]];
  [FBSDKTypeUtility dictionary:query setObject:key forKey:[FBSDKDynamicFrameworkLoader loadkSecAttrAccount]];
#if !TARGET_OS_SIMULATOR
  if (_accessGroup) {
    [query setObject:_accessGroup forKey:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessGroup]];
  }
#endif

  return query;
}

@end
