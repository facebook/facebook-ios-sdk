/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTokenCache.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKUnarchiverProvider.h"

static NSString *const kFBSDKAccessTokenUserDefaultsKey = @"com.facebook.sdk.v4.FBSDKAccessTokenInformationKey";
static NSString *const kFBSDKAccessTokenKeychainKey = @"com.facebook.sdk.v4.FBSDKAccessTokenInformationKeychainKey";

static NSString *const kFBSDKAuthenticationTokenUserDefaultsKey = @"com.facebook.sdk.v9.FBSDKAuthenticationTokenInformationKey";
static NSString *const kFBSDKAuthenticationTokenKeychainKey = @"com.facebook.sdk.v9.FBSDKAuthenticationTokenInformationKeychainKey";

static NSString *const kFBSDKTokenUUIDKey = @"tokenUUID";
static NSString *const kFBSDKTokenEncodedKey = @"tokenEncoded";

NSString *const DefaultKeychainServicePrefix = @"com.facebook.sdk.tokencache";

@implementation FBSDKTokenCache

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
                   keychainStore:(id<FBSDKKeychainStore>)keychainStore
{
  if ((self = [super init])) {
    _keychainStore = keychainStore;
    _settings = settings;
  }

  return self;
}

- (nullable FBSDKAccessToken *)accessToken
{
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSString *uuid = [defaults objectForKey:kFBSDKAccessTokenUserDefaultsKey];
  NSDictionary<NSString *, id> *dict = [self.keychainStore dictionaryForKey:kFBSDKAccessTokenKeychainKey];

  if (self.settings.shouldUseTokenOptimizations) {
    if (!uuid && !dict) {
      return nil;
    }

    if (!uuid) {
      [self clearAccessTokenCache];
      return nil;
    }

    if (!dict) {
      [defaults setObject:nil forKey:kFBSDKAccessTokenUserDefaultsKey];
      return nil;
    }
  }

  if ([dict[kFBSDKTokenUUIDKey] isKindOfClass:NSString.class]) {
    // there is a bug while running on simulator that the uuid stored in dict can be NSData,
    // do a type check to make sure it is NSString
    if ([dict[kFBSDKTokenUUIDKey] isEqualToString:uuid]) {
      id tokenData = dict[kFBSDKTokenEncodedKey];
      if ([tokenData isKindOfClass:NSData.class]) {
        id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:tokenData];

        FBSDKAccessToken *unarchivedToken = nil;
        @try {
          unarchivedToken = [unarchiver decodeObjectOfClass:FBSDKAccessToken.class forKey:NSKeyedArchiveRootObjectKey];
        } @catch (NSException *ex) {
          // ignore decoding exceptions
        }
        return unarchivedToken;
      }
    }
  }
  // if the uuid doesn't match (including if there is no uuid in defaults which means uninstalled case)
  // clear the access token cache and return nil.
  [self clearAccessTokenCache];
  return nil;
}

- (void)setAccessToken:(FBSDKAccessToken *)token
{
  if (!token) {
    [self clearAccessTokenCache];
    return;
  }
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSString *uuid = [defaults objectForKey:kFBSDKAccessTokenUserDefaultsKey];
  if (!uuid) {
    uuid = [NSUUID UUID].UUIDString;
    [defaults setObject:uuid forKey:kFBSDKAccessTokenUserDefaultsKey];
  }
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:token requiringSecureCoding:NO error:nil];
  NSDictionary<NSString *, id> *dict = @{
    kFBSDKTokenUUIDKey : uuid,
    kFBSDKTokenEncodedKey : tokenData
  };

  [self.keychainStore setDictionary:dict
                             forKey:kFBSDKAccessTokenKeychainKey
                      accessibility:FBSDKDynamicFrameworkLoader.loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
}

- (nullable FBSDKAuthenticationToken *)authenticationToken
{
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSString *uuid = [defaults objectForKey:kFBSDKAuthenticationTokenUserDefaultsKey];
  NSDictionary<NSString *, id> *dict = [self.keychainStore dictionaryForKey:kFBSDKAuthenticationTokenKeychainKey];

  if (self.settings.shouldUseTokenOptimizations) {
    if (!uuid && !dict) {
      return nil;
    }

    if (!uuid) {
      [self clearAuthenticationTokenCache];
      return nil;
    }

    if (!dict) {
      [defaults setObject:nil forKey:kFBSDKAuthenticationTokenKeychainKey];
      return nil;
    }
  }

  if ([dict[kFBSDKTokenUUIDKey] isKindOfClass:NSString.class]) {
    // there is a bug while running on simulator that the uuid stored in dict can be NSData,
    // do a type check to make sure it is NSString
    if ([dict[kFBSDKTokenUUIDKey] isEqualToString:uuid]) {
      id tokenData = dict[kFBSDKTokenEncodedKey];
      id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:tokenData];

      FBSDKAuthenticationToken *unarchivedToken = nil;
      @try {
        unarchivedToken = [unarchiver decodeObjectOfClass:FBSDKAuthenticationToken.class forKey:NSKeyedArchiveRootObjectKey];
      } @catch (NSException *ex) {
        // ignore decoding exceptions
      } @finally {
        return unarchivedToken;
      }
      return nil;
    }
  }
  // if the uuid doesn't match (including if there is no uuid in defaults which means uninstalled case)
  // clear the authentication token cache and return nil.
  [self clearAuthenticationTokenCache];
  return nil;
}

- (void)setAuthenticationToken:(FBSDKAuthenticationToken *)token
{
  if (!token) {
    [self clearAuthenticationTokenCache];
    return;
  }
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSString *uuid = [defaults objectForKey:kFBSDKAuthenticationTokenUserDefaultsKey];
  if (!uuid) {
    uuid = NSUUID.UUID.UUIDString;
    [defaults setObject:uuid forKey:kFBSDKAuthenticationTokenUserDefaultsKey];
  }
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:token requiringSecureCoding:NO error:nil];
  NSDictionary<NSString *, id> *dict = @{
    kFBSDKTokenUUIDKey : uuid,
    kFBSDKTokenEncodedKey : tokenData
  };

  [self.keychainStore setDictionary:dict
                             forKey:kFBSDKAuthenticationTokenKeychainKey
                      accessibility:FBSDKDynamicFrameworkLoader.loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
}

- (void)clearAuthenticationTokenCache
{
  [self.keychainStore setDictionary:nil
                             forKey:kFBSDKAuthenticationTokenKeychainKey
                      accessibility:NULL];
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  [defaults removeObjectForKey:kFBSDKAuthenticationTokenUserDefaultsKey];
}

- (void)clearAccessTokenCache
{
  [self.keychainStore setDictionary:nil
                             forKey:kFBSDKAccessTokenKeychainKey
                      accessibility:NULL];
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  [defaults removeObjectForKey:kFBSDKAccessTokenUserDefaultsKey];
}

@end
