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

#import "FBTestUsersManager.h"

#import "FBAccessTokenData.h"
#import "FBLogger.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBSessionUtility.h"
#import "FBSettings.h"

static NSString *const kFBGraphAPITestUsersPathFormat = @"%@/accounts/test-users";
static NSString *const kAccountsDictionaryTokenKey = @"access_token";
static NSString *const kAccountsDictionaryPermissionsKey = @"permissions";
static NSMutableDictionary *gInstancesDictionary;

@interface FBTestUsersManager() {
    NSString *_appId;
    NSString *_appSecret;
    // dictionary with format like:
    // { user_id :  { kAccountsDictionaryTokenKey : "token",
    //                kAccountsDictionaryPermissionsKey : [ permissions ] }
    NSMutableDictionary *_accounts;
}

@end

@implementation FBTestUsersManager
- (instancetype)initWithAppId:(NSString *)appId appSecret:(NSString *)appSecret {
    if ((self = [super init])) {
        _appId = [appId copy];
        _appSecret = [appSecret copy];
        _accounts = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void)dealloc {
    [_appId release];
    [_appSecret release];
    [_accounts release];

    [super dealloc];
}

+ (instancetype)sharedInstanceForAppId:(NSString *)appId appSecret:(NSString *)appSecret {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gInstancesDictionary = [[NSMutableDictionary dictionary] retain];
    });

    NSString *instanceKey = [NSString stringWithFormat:@"%@|%@", appId, appSecret];
    if (!gInstancesDictionary[instanceKey]) {
        gInstancesDictionary[instanceKey] = [[[FBTestUsersManager alloc] initWithAppId:appId appSecret:appSecret] autorelease];
    }
    return gInstancesDictionary[instanceKey];
}

- (void)requestTestAccountTokensWithArraysOfPermissions:(NSArray *)arraysOfPermissions
                                       createIfNotFound:(BOOL)createIfNotFound
                                      completionHandler:(FBTestUsersManagerRetrieveTestAccountTokensHandler)handler {
    arraysOfPermissions = arraysOfPermissions ?: @[@[]];

    // wrap work in a block so that we can chain it to after a fetch of existing accounts if we need to.
    void (^helper)(NSError *) = ^(NSError *error){
        if (error) {
            if (handler) {
                handler(nil, error);
            }
            return;
        }
        NSMutableArray *tokenDatum = [NSMutableArray arrayWithCapacity:arraysOfPermissions.count];
        NSMutableSet *collectedUserIds = [NSMutableSet setWithCapacity:arraysOfPermissions.count];
        __block BOOL canInvokeHandler = YES;
        [arraysOfPermissions enumerateObjectsUsingBlock:^(NSArray *desiredPermissions, NSUInteger idx, BOOL *stop) {
            NSArray* userIdAndTokenPair = [self userIdAndTokenOfExistingAccountWithPermissions:desiredPermissions skip:collectedUserIds];
            if (!userIdAndTokenPair) {
                if (createIfNotFound) {
                    [self addTestAccountWithPermissions:desiredPermissions
                                      completionHandler:^(NSArray *tokens, NSError *addError) {
                        if (addError) {
                            if (handler) {
                                handler(nil, addError);
                            }
                        } else {
                            [self requestTestAccountTokensWithArraysOfPermissions:arraysOfPermissions
                                                                 createIfNotFound:createIfNotFound
                                                                completionHandler:handler];
                        }
                    }];
                    // stop the enumeration (ane flag so that callback to addTestAccount* will resolve our handler now).
                    canInvokeHandler = NO;
                    *stop = YES;
                    return;
                } else {
                    [tokenDatum addObject:[NSNull null]];
                }
            } else {
                NSString *userId = userIdAndTokenPair[0];
                NSString *tokenString = userIdAndTokenPair[1];
                [collectedUserIds addObject:userId];
                [tokenDatum addObject:[self tokenDataForTokenString:tokenString
                                                        permissions:desiredPermissions
                                                             userId:userId]];
            }
        }];

        if (canInvokeHandler && handler) {
            handler(tokenDatum, nil);
        }
    };
    if (_accounts.count == 0) {
        [self fetchExistingTestAccounts:helper];
    } else {
        helper(NULL);
    }
}

- (void)addTestAccountWithPermissions:(NSArray *)permissions
                    completionHandler:(FBTestUsersManagerRetrieveTestAccountTokensHandler)handler {
    NSDictionary *params = @{
                                 @"installed" : @"true",
                                 @"permissions" : [permissions componentsJoinedByString:@","],
                                 @"access_token" : self.appAccessToken
                                 };
    FBRequest *request = [[[FBRequest alloc] initWithSession:nil
                                                  graphPath:[NSString stringWithFormat:kFBGraphAPITestUsersPathFormat, _appId]
                                                 parameters:params
                                                 HTTPMethod:@"POST"] autorelease];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            if (handler) {
                handler(nil, error);
            }
        } else {
            NSMutableDictionary *accountData = [NSMutableDictionary dictionaryWithCapacity:2];
            accountData[kAccountsDictionaryPermissionsKey] = [NSArray arrayWithArray:permissions];
            accountData[kAccountsDictionaryTokenKey] = result[@"access_token"];
            _accounts[result[@"id"]] = accountData;

            if (handler) {
                FBAccessTokenData *tokenData = [self tokenDataForTokenString:accountData[kAccountsDictionaryTokenKey]
                                                                 permissions:permissions
                                                                      userId:result[@"id"]];
                handler(@[tokenData], nil);
            }
        }
    }];
}

- (void)removeTestAccount:(NSString *)userId completionHandler:(FBTestUsersManagerRemoveTestAccountHandler)handler {
  NSDictionary *params = @{
                           @"access_token" : self.appAccessToken
                           };
  FBRequest *request = [[[FBRequest alloc] initWithSession:nil
                                                 graphPath:userId
                                                parameters:params
                                                HTTPMethod:@"DELETE"] autorelease];
  [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    if (handler) {
      handler(error);
    }
  }];
}

#pragma mark - private methods
- (FBAccessTokenData *)tokenDataForTokenString:(NSString *)tokenString permissions:(NSArray *)permissions userId:(NSString *)userId{
    return [FBAccessTokenData createTokenFromString:tokenString
                                        permissions:permissions
                                declinedPermissions:nil
                                     expirationDate:[NSDate distantFuture]
                                          loginType:FBSessionLoginTypeTestUser
                                        refreshDate:[NSDate date]
                             permissionsRefreshDate:[NSDate date]
                                              appID:_appId
                                             userID:userId
            ];
}
- (NSArray *)userIdAndTokenOfExistingAccountWithPermissions:(NSArray *)permissions skip:(NSSet *)setToSkip {
    __block NSString *userId = nil;
    __block NSString *token = nil;

    [_accounts enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *accountData, BOOL *stop) {
        if ([setToSkip containsObject:key]) {
            return;
        }
        NSArray *accountPermissions = accountData[kAccountsDictionaryPermissionsKey];
        if ([FBSessionUtility areRequiredPermissions:permissions aSubsetOfPermissions:accountPermissions]) {
            token = accountData[kAccountsDictionaryTokenKey];
            userId = key;
            *stop = YES;
        }
    }];
    if (userId && token) {
        return @[userId, token];
    } else {
        return nil;
    }
}

- (NSString *)appAccessToken {
    return [NSString stringWithFormat:@"%@|%@", _appId, _appSecret];
}

- (void)fetchExistingTestAccounts:(void(^)(NSError *error))handler {
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBSession *sessionWithAppIdOnly = [[[FBSession alloc] initWithAppID:_appId
                                                           permissions:nil
                                                       defaultAudience:FBSessionDefaultAudienceNone
                                                       urlSchemeSuffix:nil
                                                    tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]] autorelease];
    FBRequest *requestForAccountIds = [[[FBRequest alloc] initWithSession:sessionWithAppIdOnly
                                                                graphPath:[NSString stringWithFormat:kFBGraphAPITestUsersPathFormat, _appId]
                                                               parameters:@{ @"access_token" : self.appAccessToken }
                                                               HTTPMethod:nil]
                                       autorelease];
    [connection addRequest:requestForAccountIds completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        if (error) {
            if (handler) {
                handler(error);
            }
        } else {
            for (NSDictionary *account in result[@"data"]) {
                NSString *userId = account[@"id"];
                _accounts[userId] = [NSMutableDictionary dictionaryWithCapacity:2];
                _accounts[userId][kAccountsDictionaryTokenKey] = account[@"access_token"];
            }
        }
    } batchParameters:@{@"name":@"test-accounts", @"omit_response_on_success":@(NO)}];

    FBRequest *requestForUsersPermissions = [[[FBRequest alloc] initWithSession:nil
                                                                   graphPath:@"?ids={result=test-accounts:$.data.*.id}&fields=permissions"
                                                                  parameters:@{ @"access_token" : self.appAccessToken }
                                                                     HTTPMethod:nil] autorelease];
    [connection addRequest:requestForUsersPermissions completionHandler:^(FBRequestConnection *innerConnection, id result, NSError *error) {
        if (error) {
            if (handler) {
                handler(error);
            }
        } else {
            for (NSString *userId in [result allKeys]) {
                NSMutableArray *grantedPermissions = [NSMutableArray array];
                NSArray *resultPermissionsDictionaries = result[userId][@"permissions"][@"data"];
                [resultPermissionsDictionaries enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                    [grantedPermissions addObject:obj[@"permission"]];
                }];
                _accounts[userId][kAccountsDictionaryPermissionsKey] = grantedPermissions;
            }
        }
        if (handler) {
            handler(nil);
        }
    }];
    [connection start];
}
@end
