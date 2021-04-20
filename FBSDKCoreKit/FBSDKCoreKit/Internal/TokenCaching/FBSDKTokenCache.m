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

#import "FBSDKTokenCache.h"

#import "FBSDKAuthenticationToken+Internal.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKKeychainStore.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKUnarchiverProvider.h"

static NSString *const kFBSDKAccessTokenUserDefaultsKey = @"com.facebook.sdk.v4.FBSDKAccessTokenInformationKey";
static NSString *const kFBSDKAccessTokenKeychainKey = @"com.facebook.sdk.v4.FBSDKAccessTokenInformationKeychainKey";

static NSString *const kFBSDKAuthenticationTokenUserDefaultsKey = @"com.facebook.sdk.v9.FBSDKAuthenticationTokenInformationKey";
static NSString *const kFBSDKAuthenticationTokenKeychainKey = @"com.facebook.sdk.v9.FBSDKAuthenticationTokenInformationKeychainKey";

static NSString *const kFBSDKTokenUUIDKey = @"tokenUUID";
static NSString *const kFBSDKTokenEncodedKey = @"tokenEncoded";

@implementation FBSDKTokenCache
{
  FBSDKKeychainStore *_keychainStore;
  id<FBSDKSettings> _settings;
}

- (instancetype)initWithSettings:(id<FBSDKSettings>)settings
{
  if ((self = [super init])) {
    NSString *keyChainServiceIdentifier = [NSString stringWithFormat:@"com.facebook.sdk.tokencache.%@", [NSBundle mainBundle].bundleIdentifier];
    _keychainStore = [[FBSDKKeychainStore alloc] initWithService:keyChainServiceIdentifier accessGroup:nil];
    _settings = settings;
  }
  return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (FBSDKAccessToken *)accessToken
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *uuid = [defaults objectForKey:kFBSDKAccessTokenUserDefaultsKey];
  NSDictionary<NSString *, id> *dict = [_keychainStore dictionaryForKey:kFBSDKAccessTokenKeychainKey];

  if (_settings.shouldUseTokenOptimizations) {
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

  if ([dict[kFBSDKTokenUUIDKey] isKindOfClass:[NSString class]]) {
    // there is a bug while running on simulator that the uuid stored in dict can be NSData,
    // do a type check to make sure it is NSString
    if ([dict[kFBSDKTokenUUIDKey] isEqualToString:uuid]) {
      id tokenData = dict[kFBSDKTokenEncodedKey];
      if ([tokenData isKindOfClass:[NSData class]]) {
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
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *uuid = [defaults objectForKey:kFBSDKAccessTokenUserDefaultsKey];
  if (!uuid) {
    uuid = [NSUUID UUID].UUIDString;
    [defaults setObject:uuid forKey:kFBSDKAccessTokenUserDefaultsKey];
  }
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
  NSDictionary<NSString *, id> *dict = @{
    kFBSDKTokenUUIDKey : uuid,
    kFBSDKTokenEncodedKey : tokenData
  };

  [_keychainStore setDictionary:dict
                         forKey:kFBSDKAccessTokenKeychainKey
                  accessibility:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

- (FBSDKAuthenticationToken *)authenticationToken
{
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSString *uuid = [defaults objectForKey:kFBSDKAuthenticationTokenUserDefaultsKey];
  NSDictionary<NSString *, id> *dict = [_keychainStore dictionaryForKey:kFBSDKAuthenticationTokenKeychainKey];

  if (_settings.shouldUseTokenOptimizations) {
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

  if ([dict[kFBSDKTokenUUIDKey] isKindOfClass:[NSString class]]) {
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
  NSData *tokenData = [NSKeyedArchiver archivedDataWithRootObject:token];
  NSDictionary<NSString *, id> *dict = @{
    kFBSDKTokenUUIDKey : uuid,
    kFBSDKTokenEncodedKey : tokenData
  };

  [_keychainStore setDictionary:dict
                         forKey:kFBSDKAuthenticationTokenKeychainKey
                  accessibility:[FBSDKDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

#pragma clang diagnostic pop

- (void)clearAuthenticationTokenCache
{
  [_keychainStore setDictionary:nil
                         forKey:kFBSDKAuthenticationTokenKeychainKey
                  accessibility:NULL];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kFBSDKAuthenticationTokenUserDefaultsKey];
  [defaults synchronize];
}

- (void)clearAccessTokenCache
{
  [_keychainStore setDictionary:nil
                         forKey:kFBSDKAccessTokenKeychainKey
                  accessibility:NULL];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kFBSDKAccessTokenUserDefaultsKey];
  [defaults synchronize];
}

@end
