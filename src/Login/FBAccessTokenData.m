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

#import "FBAccessTokenData+Internal.h"

#import "FBError.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBSettings.h"
#import "FBUtility.h"

@interface FBAccessTokenData ()

// Note these properties are re-declared here (in addition to
// +Internal.h) to allow easy synthesis. Additionally, this is required to
// allow the SDK to call the setters of these properties from an app, since
// the app only has access to the public (not +Internal) header.
@property (nonatomic, readwrite, copy) NSDate *refreshDate;
@property (nonatomic, readwrite, copy) NSArray *permissions;
@property (nonatomic, readwrite, copy) NSArray *declinedPermissions;
@property (nonatomic, readwrite, copy) NSString *appID;
@property (nonatomic, readwrite, copy) NSString *userID;

@property (nonatomic, readwrite, copy) NSDate *permissionsRefreshDate;

@end

@implementation FBAccessTokenData

- (id)      initWithToken:(NSString *)accessToken
              permissions:(NSArray *)permissions
      declinedPermissions:(NSArray *)declinedPermissions
           expirationDate:(NSDate *)expirationDate
                loginType:(FBSessionLoginType)loginType
              refreshDate:(NSDate *)refreshDate
   permissionsRefreshDate:(NSDate *)permissionsRefreshDate
                    appID:(NSString *)appID
                   userID:(NSString *)userID
{
    if ((self = [super init])) {
        _accessToken = [accessToken copy];
        _permissions = [permissions copy];
        _declinedPermissions = [declinedPermissions copy];
        _expirationDate = [expirationDate copy];
        _refreshDate = [refreshDate copy];
        _loginType = loginType;
        _permissionsRefreshDate = [permissionsRefreshDate copy];
        _appID = [appID copy];
        _userID = [userID copy];
    }
    return self;
}

- (void)dealloc {
    [_accessToken release];
    [_permissions release];
    [_declinedPermissions release];
    [_expirationDate release];
    [_refreshDate release];
    [_permissionsRefreshDate release];
    [_appID release];
    [_userID release];
    [super dealloc];
}

#pragma mark - Factory methods

+ (FBAccessTokenData *)createTokenFromFacebookURL:(NSURL *)url appID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    NSString *expectedUrlPrefix = [FBUtility stringAppBaseUrlFromAppId:appID urlSchemeSuffix:urlSchemeSuffix];
    if (![[url absoluteString] hasPrefix:expectedUrlPrefix]) {
        return nil;
    }

    NSDictionary *queryDictionary = [FBUtility queryParamsDictionaryFromFBURL:url];

    return [self createTokenFromString:queryDictionary[@"access_token"]
                           permissions:nil
                        expirationDate:[FBUtility expirationDateFromExpirationTimeIntervalString:queryDictionary[@"expires_in"]]
                             loginType:FBSessionLoginTypeFacebookApplication
                           refreshDate:nil
                permissionsRefreshDate:nil
                                 appID:appID];
}

+ (FBAccessTokenData *)createTokenFromDictionary:(NSDictionary *)dictionary {
    NSString *dictionaryToken = dictionary[FBTokenInformationTokenKey];
    NSDate *dictionaryExpirationDate = dictionary[FBTokenInformationExpirationDateKey];
    NSArray *dictionaryPermissions = dictionary[FBTokenInformationPermissionsKey];
    NSArray *dictionaryDeclinedPermissions = dictionary[FBTokenInformationDeclinedPermissionsKey];
    FBSessionLoginType dictionaryLoginType = [dictionary[FBTokenInformationLoginTypeLoginKey] intValue];
    BOOL dictionaryIsFacebookLoginType = [dictionary[FBTokenInformationIsFacebookLoginKey] boolValue];
    NSDate *dictionaryRefreshDate = dictionary[FBTokenInformationRefreshDateKey];
    NSDate *dictionaryPermissionsRefreshDate = dictionary[FBTokenInformationPermissionsRefreshDateKey];
    NSString *dictionaryAppID = dictionary[FBTokenInformationAppIDKey];
    NSString *dictionaryUserID = dictionary[FBTokenInformationUserFBIDKey];

    if (dictionaryIsFacebookLoginType && dictionaryLoginType == FBSessionLoginTypeNone) {
        // The internal isFacebookLogin has been removed but to support backwards compatibility,
        // we will still check it and set the login type appropriately.
        // This is relevant for `-FBSession shouldExtendAccessToken`
        dictionaryLoginType = FBSessionLoginTypeFacebookApplication;
    }
    FBAccessTokenData *tokenData = [self createTokenFromString:dictionaryToken
                                                   permissions:dictionaryPermissions
                                           declinedPermissions:dictionaryDeclinedPermissions
                                                expirationDate:dictionaryExpirationDate
                                                     loginType:dictionaryLoginType
                                                   refreshDate:dictionaryRefreshDate
                                        permissionsRefreshDate:dictionaryPermissionsRefreshDate
                                                         appID:dictionaryAppID
                                                        userID:dictionaryUserID];
    return tokenData;
}

+ (FBAccessTokenData *)createTokenFromString:(NSString *)accessToken
                                 permissions:(NSArray *)permissions
                              expirationDate:(NSDate *)expirationDate
                                   loginType:(FBSessionLoginType)loginType
                                 refreshDate:(NSDate *)refreshDate {
    return [self createTokenFromString:accessToken
                           permissions:permissions
                   declinedPermissions:nil
                        expirationDate:expirationDate
                             loginType:loginType
                           refreshDate:refreshDate
                permissionsRefreshDate:nil
                                 appID:nil
                                userID:nil];
}

+ (FBAccessTokenData *)createTokenFromString:(NSString *)accessToken
                                 permissions:(NSArray *)permissions
                              expirationDate:(NSDate *)expirationDate
                                   loginType:(FBSessionLoginType)loginType
                                 refreshDate:(NSDate *)refreshDate
                      permissionsRefreshDate:(NSDate *)permissionsRefreshDate {
    return [self createTokenFromString:accessToken
                           permissions:permissions
                   declinedPermissions:nil
                        expirationDate:expirationDate
                             loginType:loginType
                           refreshDate:refreshDate
                permissionsRefreshDate:permissionsRefreshDate
                                 appID:nil
                                userID:nil];
}

+ (FBAccessTokenData *)createTokenFromString:(NSString *)accessToken
                                 permissions:(NSArray *)permissions
                              expirationDate:(NSDate *)expirationDate
                                   loginType:(FBSessionLoginType)loginType
                                 refreshDate:(NSDate *)refreshDate
                      permissionsRefreshDate:(NSDate *)permissionsRefreshDate
                                       appID:(NSString *)appID {
    return [self createTokenFromString:accessToken
                           permissions:permissions
                   declinedPermissions:nil
                        expirationDate:expirationDate
                             loginType:loginType
                           refreshDate:refreshDate
                permissionsRefreshDate:permissionsRefreshDate
                                 appID:appID
                                userID:nil];
}

+ (FBAccessTokenData *)createTokenFromString:(NSString *)accessToken
                                 permissions:(NSArray *)permissions
                         declinedPermissions:(NSArray *)declinedPermissions
                              expirationDate:(NSDate *)expirationDate
                                   loginType:(FBSessionLoginType)loginType
                                 refreshDate:(NSDate *)refreshDate
                      permissionsRefreshDate:(NSDate *)permissionsRefreshDate
                                       appID:(NSString *)appID
                                      userID:(NSString *)userID
    {
    if (accessToken == nil || [accessToken stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]].length == 0) {
        return nil;
    }
    if (expirationDate == nil) {
        expirationDate = [NSDate distantFuture];
    }
    if (refreshDate == nil) {
        refreshDate = [NSDate date];
    }
    if (permissionsRefreshDate == nil) {
        permissionsRefreshDate = [NSDate distantPast];
    }
    if (appID == nil) {
        appID = [FBSettings defaultAppID];
    }

    FBAccessTokenData *fbAccessToken = [[FBAccessTokenData alloc] initWithToken:accessToken
                                                                    permissions:permissions
                                                            declinedPermissions:declinedPermissions
                                                                 expirationDate:expirationDate
                                                                      loginType:loginType
                                                                    refreshDate:refreshDate
                                                         permissionsRefreshDate:permissionsRefreshDate
                                                                          appID:appID
                                                                         userID:userID];
    return [fbAccessToken autorelease];
}

#pragma  mark - Public methods


- (BOOL)isEqual:(id)other {
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }

    return [self isEqualToAccessTokenData:other];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 31;

    result = prime * result + [self.accessToken hash];
    result = prime * result + [self.permissions hash];
    result = prime * result + [self.declinedPermissions hash];
    result = prime * result + [self.expirationDate hash];
    result = prime * result + [self.refreshDate hash];
    result = prime * result + self.loginType;
    result = prime * result + [self.permissionsRefreshDate hash];
    result = prime * result + [self.appID hash];
    result = prime * result + [self.userID hash];

    return result;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[FBAccessTokenData alloc] initWithToken:self.accessToken
                                           permissions:self.permissions
                                   declinedPermissions:self.declinedPermissions
                                        expirationDate:self.expirationDate
                                             loginType:self.loginType
                                           refreshDate:self.refreshDate
                                permissionsRefreshDate:self.permissionsRefreshDate
                                                 appID:self.appID
                                                userID:self.userID];
    return copy;
}

- (BOOL)isEqualToAccessTokenData:(FBAccessTokenData *)accessTokenData {
    if (self == accessTokenData) {
        return YES;
    }

    if ([self.accessToken isEqualToString:accessTokenData.accessToken]
        && [[NSSet setWithArray:self.permissions] isEqualToSet:[NSSet setWithArray:accessTokenData.permissions]]
        && [[NSSet setWithArray:self.declinedPermissions] isEqualToSet:[NSSet setWithArray:accessTokenData.declinedPermissions]]
        && [self.expirationDate isEqualToDate:accessTokenData.expirationDate]
        && self.loginType == accessTokenData.loginType
        && [self.refreshDate isEqualToDate:accessTokenData.refreshDate]
        && [self.permissionsRefreshDate isEqualToDate:accessTokenData.permissionsRefreshDate]
        && ((!self.appID && !accessTokenData.appID) || [self.appID isEqualToString:accessTokenData.appID])
        && ((!self.userID && !accessTokenData.userID) || [self.userID isEqualToString:accessTokenData.userID]) ) {
        return YES;
    }

    return NO;
}

- (NSMutableDictionary *)dictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 self.accessToken, FBTokenInformationTokenKey,
                                 self.expirationDate, FBTokenInformationExpirationDateKey,
                                 [NSNumber numberWithInt:self.loginType], FBTokenInformationLoginTypeLoginKey,
                                 nil];
    if (self.refreshDate) {
        dict[FBTokenInformationRefreshDateKey] = self.refreshDate;
    }
    if (self.permissions) {
        dict[FBTokenInformationPermissionsKey] = self.permissions;
    }
    if (self.declinedPermissions) {
        dict[FBTokenInformationDeclinedPermissionsKey] = self.declinedPermissions;
    }
    if (self.permissionsRefreshDate) {
        dict[FBTokenInformationPermissionsRefreshDateKey] = self.permissionsRefreshDate;
    }
    if (self.appID) {
        dict[FBTokenInformationAppIDKey] = self.appID;
    }
    if (self.userID) {
        dict[FBTokenInformationUserFBIDKey] = self.userID;
    }
    return [dict autorelease];
}

- (NSString *)description {
    return self.accessToken;
}

@end
