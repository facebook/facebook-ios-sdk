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

#import "FBSessionTokenCachingStrategy.h"

#import "FBAccessTokenData+Internal.h"
#import "FBDynamicFrameworkLoader.h"
#import "FBKeychainStore.h"
#import "FBKeychainStoreDeprecated.h"
#import "FBUtility.h"

// const strings
static NSString *const FBAccessTokenInformationKeyName = @"FBAccessTokenInformationKey";

NSString *const FBTokenInformationTokenKey = @"com.facebook.sdk:TokenInformationTokenKey";
NSString *const FBTokenInformationExpirationDateKey = @"com.facebook.sdk:TokenInformationExpirationDateKey";
NSString *const FBTokenInformationRefreshDateKey = @"com.facebook.sdk:TokenInformationRefreshDateKey";
NSString *const FBTokenInformationUserFBIDKey = @"com.facebook.sdk:TokenInformationUserFBIDKey";
NSString *const FBTokenInformationIsFacebookLoginKey = @"com.facebook.sdk:TokenInformationIsFacebookLoginKey";
NSString *const FBTokenInformationLoginTypeLoginKey = @"com.facebook.sdk:TokenInformationLoginTypeLoginKey";
NSString *const FBTokenInformationPermissionsKey = @"com.facebook.sdk:TokenInformationPermissionsKey";
NSString *const FBTokenInformationDeclinedPermissionsKey = @"com.facebook.sdk:TokenInformationDeclinedPermissionsKey";
NSString *const FBTokenInformationPermissionsRefreshDateKey = @"com.facebook.sdk:TokenInformationPermissionsRefreshDateKey";
NSString *const FBTokenInformationAppIDKey = @"com.facebook.sdk:TokenInformationAppIDKey";
NSString *const FBTokenInformationUUIDKey = @"com.facebook.sdk:TokenInformationUUIDKey";

#pragma mark - private FBSessionTokenCachingStrategyNoOpInstance class

@interface FBSessionTokenCachingStrategyNoOpInstance : FBSessionTokenCachingStrategy

@end
@implementation FBSessionTokenCachingStrategyNoOpInstance

- (void)cacheTokenInformation:(NSDictionary *)tokenInformation {
}

- (NSDictionary *)fetchTokenInformation {
    return [NSDictionary dictionary];
}

- (void)clearToken {
}

@end


@implementation FBSessionTokenCachingStrategy {
    NSString *_accessTokenInformationKeyName;
    FBKeychainStore *_keychainStore;
}

#pragma mark - Lifecycle

- (instancetype)init {
    return [self initWithUserDefaultTokenInformationKeyName:nil];
}

- (instancetype)initWithUserDefaultTokenInformationKeyName:(NSString *)tokenInformationKeyName {
    self = [super init];
    if (self) {
        // get-em
        _accessTokenInformationKeyName = tokenInformationKeyName ? tokenInformationKeyName : FBAccessTokenInformationKeyName;

        // keep-em
        [_accessTokenInformationKeyName retain];
    }
    return self;
}

- (void)dealloc {
    // let-em go
    [_accessTokenInformationKeyName release];
    [_keychainStore release];
    [super dealloc];
}

- (FBKeychainStore *)keychainStore {
    if (!_keychainStore) {
        NSString *keyChainServiceIdentifier = [NSString stringWithFormat:@"com.facebook.sdk.tokencache.%@", [[NSBundle mainBundle] bundleIdentifier]];
        _keychainStore = [[FBKeychainStore alloc] initWithService:keyChainServiceIdentifier];
    }

    return _keychainStore;
}

/* This is only used for injections in tests. DO NOT USE. */
- (void)overrideKeyChainStoreForTests:(FBKeychainStore *)keychainStore {
    if (_keychainStore != keychainStore) {
        [_keychainStore release];
        _keychainStore = [keychainStore retain];
    };
}

- (NSString *)userDefaultsKeyForKeychainValidation {
   return [_accessTokenInformationKeyName stringByAppendingString:@"UUID"];
}

#pragma mark -
#pragma mark Public Members

- (void)cacheTokenInformation:(NSDictionary *)tokenInformation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [defaults objectForKey:[self userDefaultsKeyForKeychainValidation]];
    if (!uuid) {
        uuid = [[FBUtility newUUIDString] autorelease];
        [defaults setObject:uuid forKey:[self userDefaultsKeyForKeychainValidation]];
        [defaults synchronize];
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:tokenInformation];
    dict[FBTokenInformationUUIDKey] = uuid;

    [self.keychainStore setDictionary:dict
                               forKey:_accessTokenInformationKeyName
                        accessibility:[FBDynamicFrameworkLoader loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]];
}

- (NSDictionary *)fetchTokenInformation {
    // fetch values from defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // backward compatibility - check NSUserDefaults first, if token is there
    // move it to Keychain and remove from NSUserDefaults
    NSDictionary *token = [defaults objectForKey:_accessTokenInformationKeyName];
    if (token) {
        [defaults removeObjectForKey:_accessTokenInformationKeyName];
        [defaults synchronize];
        [self cacheTokenInformation:token];
        return token;
    } else {
        NSString *uuid = [defaults objectForKey:[self userDefaultsKeyForKeychainValidation]];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self.keychainStore dictionaryForKey:_accessTokenInformationKeyName]];

        // backwards compatibilty with old keychain that used bundle id as service id.
        // this will manifest as a uuid in defaults, but empty dict
        if (uuid.length > 0 && dict.count == 0) {
            FBKeychainStoreDeprecated *oldKeychainStore = [[FBKeychainStoreDeprecated alloc] init];
            dict = [NSMutableDictionary dictionaryWithDictionary:[oldKeychainStore dictionaryForKey:_accessTokenInformationKeyName]];

            if (dict) {
                [oldKeychainStore setDictionary:nil forKey:_accessTokenInformationKeyName];
                [self cacheTokenInformation:dict];
            }
            [oldKeychainStore release];
        }

        if (![dict[FBTokenInformationUUIDKey] isEqualToString:uuid]) {
            // if the uuid doesn't match (including if there is no uuid in defaults which means uninstalled case)
            // clear the keychain and return nil.
            [self clearToken];
            return nil;
        }
        [dict removeObjectForKey:FBTokenInformationUUIDKey];
        return dict;
    }
}

- (void)clearToken {
    [self.keychainStore setDictionary:nil forKey:_accessTokenInformationKeyName];
}


- (void)cacheFBAccessTokenData:(FBAccessTokenData *)accessToken {
    // For backwards compatibility, we must call into existing dictionary-based APIs.
    [self cacheTokenInformation:[accessToken dictionary]];
}

- (FBAccessTokenData *)fetchFBAccessTokenData {
    // For backwards compatibility, we must call into existing dictionary-based APIs.
    NSDictionary *dictionary = [self fetchTokenInformation];
    if (![FBSessionTokenCachingStrategy isValidTokenInformation:dictionary]) {
        return nil;
    }
    FBAccessTokenData *fbAccessToken = [FBAccessTokenData createTokenFromDictionary:dictionary];
    return fbAccessToken;
}

+ (BOOL)isValidTokenInformation:(NSDictionary *)tokenInformation {
    id token = [tokenInformation objectForKey:FBTokenInformationTokenKey];
    id expirationDate = [tokenInformation objectForKey:FBTokenInformationExpirationDateKey];
    return ([token isKindOfClass:[NSString class]] &&
            ([token length] > 0) &&
            [expirationDate isKindOfClass:[NSDate class]]);
}

+ (FBSessionTokenCachingStrategy *)defaultInstance {
    // static state to assure a single default instance here
    static FBSessionTokenCachingStrategy *sharedDefaultInstance = nil;
    static dispatch_once_t onceToken;

    // assign once to the static, if called
    dispatch_once(&onceToken, ^{
        sharedDefaultInstance = [[FBSessionTokenCachingStrategy alloc] init];
    });
    return sharedDefaultInstance;
}

+ (FBSessionTokenCachingStrategy *)nullCacheInstance {
    // static state to assure a single instance here
    static FBSessionTokenCachingStrategyNoOpInstance *noOpInstance = nil;
    static dispatch_once_t onceToken;

    // assign once to the static, if called
    dispatch_once(&onceToken, ^{
        noOpInstance = [[FBSessionTokenCachingStrategyNoOpInstance alloc] init];
    });
    return noOpInstance;
}

#pragma mark -

@end
