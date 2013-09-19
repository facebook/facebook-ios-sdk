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
#import "FBUtility.h"
#import "FBSessionTokenCachingStrategy.h"

@interface FBAccessTokenData()

// Note these properties are re-declared here (in addition to
// +Internal.h) to allow easy synthesis. Additionally, this is required to
// allow the SDK to call the setters of these properties from an app, since
// the app only has access to the public (not +Internal) header.
@property (nonatomic, readwrite, copy) NSDate *refreshDate;
@property (nonatomic, readwrite, copy) NSArray *permissions;

@property (nonatomic, readwrite, copy) NSDate *permissionsRefreshDate;

@end

@implementation FBAccessTokenData

- (id)       initWithToken:(NSString *)accessToken
               permissions:(NSArray *)permissions
            expirationDate:(NSDate *)expirationDate
                 loginType:(FBSessionLoginType)loginType
               refreshDate:(NSDate *)refreshDate
    permissionsRefreshDate:(NSDate *)permissionsRefreshDate {
    if ((self = [super init])){
        _accessToken = [accessToken copy];
        _permissions = [permissions copy];
        _expirationDate = [expirationDate copy];
        _refreshDate = [refreshDate copy];
        _loginType = loginType;
        _permissionsRefreshDate = [permissionsRefreshDate copy];
    }
    return self;
}

- (void) dealloc {
    [_accessToken release];
    [_permissions release];
    [_expirationDate release];
    [_refreshDate release];
    [_permissionsRefreshDate release];
    [super dealloc];
}

#pragma mark - Factory methods

+ (FBAccessTokenData *) createTokenFromFacebookURL:(NSURL *)url appID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    NSString* expectedUrlPrefix = [FBUtility stringAppBaseUrlFromAppId:appID urlSchemeSuffix:urlSchemeSuffix];
    if (![[url absoluteString] hasPrefix:expectedUrlPrefix]) {
        return nil;
    }
    
    NSDictionary *queryDictionary = [FBUtility queryParamsDictionaryFromFBURL:url];
    
    return [self createTokenFromString:queryDictionary[@"access_token"]
                           permissions:nil
                        expirationDate:[FBUtility expirationDateFromExpirationTimeIntervalString:queryDictionary[@"expires_in"]]
                             loginType:FBSessionLoginTypeFacebookApplication
                           refreshDate:nil];
}

+ (FBAccessTokenData *) createTokenFromDictionary:(NSDictionary *)dictionary {
    NSString *dictionaryToken = dictionary[FBTokenInformationTokenKey];
    NSDate *dictionaryExpirationDate = dictionary[FBTokenInformationExpirationDateKey];
    NSArray *dictionaryPermissions = dictionary[FBTokenInformationPermissionsKey];
    FBSessionLoginType dictionaryLoginType = [dictionary[FBTokenInformationLoginTypeLoginKey] intValue];
    BOOL dictionaryIsFacebookLoginType = [dictionary[FBTokenInformationIsFacebookLoginKey] boolValue];
    NSDate *dictionaryRefreshDate = dictionary[FBTokenInformationRefreshDateKey];
    NSDate *dictionaryPermissionsRefreshDate = dictionary[FBTokenInformationPermissionsRefreshDateKey];
    
    if (dictionaryIsFacebookLoginType && dictionaryLoginType == FBSessionLoginTypeNone) {
        // The internal isFacebookLogin has been removed but to support backwards compatibility,
        // we will still check it and set the login type appropriately.
        // This is relevant for `-FBSession shouldExtendAccessToken`
        dictionaryLoginType = FBSessionLoginTypeFacebookApplication;
    }
    FBAccessTokenData *tokenData = [self createTokenFromString:dictionaryToken
                                                   permissions:dictionaryPermissions
                                                expirationDate:dictionaryExpirationDate
                                                     loginType:dictionaryLoginType
                                                   refreshDate:dictionaryRefreshDate
                                        permissionsRefreshDate:dictionaryPermissionsRefreshDate];
    return tokenData;
}

+ (FBAccessTokenData *) createTokenFromString:(NSString *)accessToken
                                  permissions:(NSArray *)permissions
                               expirationDate:(NSDate *)expirationDate
                                    loginType:(FBSessionLoginType)loginType
                                  refreshDate:(NSDate *)refreshDate {
    return [self createTokenFromString:accessToken
                           permissions:permissions
                        expirationDate:expirationDate
                             loginType:loginType
                           refreshDate:refreshDate
                permissionsRefreshDate:nil];
}

+ (FBAccessTokenData *) createTokenFromString:(NSString *)accessToken
                                  permissions:(NSArray *)permissions
                               expirationDate:(NSDate *)expirationDate
                                    loginType:(FBSessionLoginType)loginType
                                  refreshDate:(NSDate *)refreshDate
                       permissionsRefreshDate:(NSDate *)permissionsRefreshDate
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
    
    FBAccessTokenData* fbAccessToken = [[FBAccessTokenData alloc] initWithToken:accessToken
                                                                    permissions:permissions
                                                                 expirationDate:expirationDate
                                                                      loginType:loginType
                                                                    refreshDate:refreshDate
                                                         permissionsRefreshDate:permissionsRefreshDate];
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
    result = prime * result + [self.expirationDate hash];
    result = prime * result + [self.refreshDate hash];
    result = prime * result + self.loginType;
    result = prime * result + [self.permissionsRefreshDate hash];
    
    return result;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[FBAccessTokenData alloc] initWithToken:self.accessToken
                                           permissions:self.permissions
                                        expirationDate:self.expirationDate
                                             loginType:self.loginType
                                           refreshDate:self.refreshDate
                                permissionsRefreshDate:self.permissionsRefreshDate];
    return copy;
}

- (BOOL) isEqualToAccessTokenData:(FBAccessTokenData *)accessTokenData {
    if (self == accessTokenData) {
        return YES;
    }
    
    if ([self.accessToken isEqualToString:accessTokenData.accessToken]
        && [[NSSet setWithArray:self.permissions] isEqualToSet:[NSSet setWithArray:accessTokenData.permissions]]
        && [self.expirationDate isEqualToDate:accessTokenData.expirationDate]
        && self.loginType == accessTokenData.loginType
        && [self.refreshDate isEqualToDate:accessTokenData.refreshDate]
        && [self.permissionsRefreshDate isEqualToDate:accessTokenData.permissionsRefreshDate]) {
        return YES;
    }
    
    return NO;
}

- (NSMutableDictionary *) dictionary {
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
    if (self.permissionsRefreshDate) {
        dict[FBTokenInformationPermissionsRefreshDateKey] = self.permissionsRefreshDate;
    }
    return [dict autorelease];
}

- (NSString*)description {
	return self.accessToken;
}

@end
