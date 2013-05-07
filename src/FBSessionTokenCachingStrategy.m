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

// const strings
static NSString *const FBAccessTokenInformationKeyName = @"FBAccessTokenInformationKey";

NSString *const FBTokenInformationTokenKey = @"com.facebook.sdk:TokenInformationTokenKey";
NSString *const FBTokenInformationExpirationDateKey = @"com.facebook.sdk:TokenInformationExpirationDateKey";
NSString *const FBTokenInformationRefreshDateKey = @"com.facebook.sdk:TokenInformationRefreshDateKey";
NSString *const FBTokenInformationUserFBIDKey = @"com.facebook.sdk:TokenInformationUserFBIDKey";
NSString *const FBTokenInformationIsFacebookLoginKey = @"com.facebook.sdk:TokenInformationIsFacebookLoginKey";
NSString *const FBTokenInformationLoginTypeLoginKey = @"com.facebook.sdk:TokenInformationLoginTypeLoginKey";
NSString *const FBTokenInformationPermissionsKey = @"com.facebook.sdk:TokenInformationPermissionsKey";

#pragma mark - private FBSessionTokenCachingStrategyNoOpInstance class

@interface FBSessionTokenCachingStrategyNoOpInstance : FBSessionTokenCachingStrategy
    
@end
@implementation FBSessionTokenCachingStrategyNoOpInstance

- (void)cacheTokenInformation:(NSDictionary*)tokenInformation {
}

- (NSDictionary*)fetchTokenInformation {
    return [NSDictionary dictionary];
}

- (void)clearToken {
}

@end


@implementation FBSessionTokenCachingStrategy {
    NSString *_accessTokenInformationKeyName;
}

#pragma mark - Lifecycle

- (id)init {
    return [self initWithUserDefaultTokenInformationKeyName:nil];
}

- (id)initWithUserDefaultTokenInformationKeyName:(NSString*)tokenInformationKeyName {
    
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
    [super dealloc];
}

#pragma mark - 
#pragma mark Public Members

- (void)cacheTokenInformation:(NSDictionary*)tokenInformation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:tokenInformation forKey:_accessTokenInformationKeyName];
    [defaults synchronize];
}

- (NSDictionary*)fetchTokenInformation {
    // fetch values from defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:_accessTokenInformationKeyName];
}

- (void)clearToken {        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:_accessTokenInformationKeyName];
    [defaults synchronize];
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

+ (BOOL)isValidTokenInformation:(NSDictionary*)tokenInformation {
    id token = [tokenInformation objectForKey:FBTokenInformationTokenKey];
    id expirationDate = [tokenInformation objectForKey:FBTokenInformationExpirationDateKey];
    return  [token isKindOfClass:[NSString class]] &&
            ([token length] > 0) &&
            [expirationDate isKindOfClass:[NSDate class]];
}

+ (FBSessionTokenCachingStrategy*)defaultInstance {
    // static state to assure a single default instance here
    static FBSessionTokenCachingStrategy *sharedDefaultInstance = nil;
    static dispatch_once_t onceToken;

    // assign once to the static, if called
    dispatch_once(&onceToken, ^{
        sharedDefaultInstance = [[FBSessionTokenCachingStrategy alloc] init];
    });
    return sharedDefaultInstance;
}

+ (FBSessionTokenCachingStrategy*)nullCacheInstance {
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
