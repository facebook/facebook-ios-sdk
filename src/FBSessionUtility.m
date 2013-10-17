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

#import "FBSessionUtility.h"

#import "FBLogger.h"
#import "FBSession+Internal.h"
#import "FBUtility.h"

@implementation FBSessionUtility

+ (BOOL)isOpenSessionResponseURL:(NSURL *)url {
    NSDictionary *params = [FBSessionUtility queryParamsFromLoginURL:url appID:nil urlSchemeSuffix:nil];
    NSDictionary *clientState = [FBSessionUtility clientStateFromQueryParams:params];
    if (!clientState) {
        return NO;
    }

    NSNumber *isOpenSessionBit = clientState[FBLoginUXClientStateIsOpenSession];
    return [isOpenSessionBit boolValue];
}

+ (NSDictionary *)queryParamsFromLoginURL:(NSURL *)url appID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    // if the URL's structure doesn't match the structure used for Facebook authorization, abort.
    if (appID) {
        NSString* expectedUrlPrefix = [FBUtility stringAppBaseUrlFromAppId:appID urlSchemeSuffix:urlSchemeSuffix];
        if (![[url absoluteString] hasPrefix:expectedUrlPrefix]) {
            return nil;
        }
    } else {
        // Don't have an App ID, just verify path.
        NSString *host = url.host;
        if (![host isEqualToString:@"authorize"]) {
            return nil;
        }
    }

    return [FBUtility queryParamsDictionaryFromFBURL:url];
}

+ (NSDictionary *)clientStateFromQueryParams:(NSDictionary *)params {
    NSDictionary *clientState = [FBUtility simpleJSONDecode:params[FBLoginUXClientState]];
    if (!clientState[FBLoginUXClientStateIsClientState]) {
        return nil;
    }
    return clientState;
}

+ (NSString *)sessionStateDescription:(FBSessionState)sessionState {
    NSString *stateDescription = nil;
    switch (sessionState) {
        case FBSessionStateCreated:
            stateDescription = @"FBSessionStateCreated";
            break;
        case FBSessionStateCreatedTokenLoaded:
            stateDescription = @"FBSessionStateCreatedTokenLoaded";
            break;
        case FBSessionStateCreatedOpening:
            stateDescription = @"FBSessionStateCreatedOpening";
            break;
        case FBSessionStateOpen:
            stateDescription = @"FBSessionStateOpen";
            break;
        case FBSessionStateOpenTokenExtended:
            stateDescription = @"FBSessionStateOpenTokenExtended";
            break;
        case FBSessionStateClosedLoginFailed:
            stateDescription = @"FBSessionStateClosedLoginFailed";
            break;
        case FBSessionStateClosed:
            stateDescription = @"FBSessionStateClosed";
            break;
        default:
            stateDescription = @"[Unknown]";
            break;
    }

    return stateDescription;
}

+ (void)addWebLoginStartTimeToParams:(NSMutableDictionary *)params {
    NSNumber *timeValue = [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])];
    NSString *e2eTimestampString = [FBUtility simpleJSONEncode:@{@"init":timeValue}];
    [params setObject:e2eTimestampString forKey:@"e2e"];
}

+ (NSDate *)expirationDateFromResponseParams:(NSDictionary *)parameters {
    NSString *expTime = [parameters objectForKey:@"expires_in"];
    NSDate *expirationDate = nil;
    if (expTime) {
        // If we have an interval, it is assumed to be since now. (e.g. 60 days)
        expirationDate = [FBUtility expirationDateFromExpirationTimeIntervalString:expTime];
    } else {
        // If we have an actual timestamp, create the date from that instead.
        expirationDate = [FBUtility expirationDateFromExpirationUnixTimeString:parameters[@"expires"]];
    }

    if (!expirationDate) {
        expirationDate = [NSDate distantFuture];
    }

    return expirationDate;
}

+ (BOOL)areRequiredPermissions:(NSArray*)requiredPermissions
          aSubsetOfPermissions:(NSArray*)cachedPermissions {
    NSSet *required = [NSSet setWithArray:requiredPermissions];
    NSSet *cached = [NSSet setWithArray:cachedPermissions];
    return [required isSubsetOfSet:cached];
}


+ (void)validateRequestForPermissions:(NSArray*)permissions
                      defaultAudience:(FBSessionDefaultAudience)defaultAudience
                   allowSystemAccount:(BOOL)allowSystemAccount
                               isRead:(BOOL)isRead {
    // validate audience argument
    if ([permissions count]) {
        if (allowSystemAccount && !isRead) {
            switch (defaultAudience) {
                case FBSessionDefaultAudienceEveryone:
                case FBSessionDefaultAudienceFriends:
                case FBSessionDefaultAudienceOnlyMe:
                    break;
                default:
                    [[NSException exceptionWithName:FBInvalidOperationException
                                             reason:@"FBSession: Publish permissions were requested "
                      @"without specifying an audience; use FBSessionDefaultAudienceJustMe, "
                      @"FBSessionDefaultAudienceFriends, or FBSessionDefaultAudienceEveryone"
                                           userInfo:nil]
                     raise];
                    break;
            }
        }
        // log unexpected permissions, and throw on read w/publish permissions
        if (allowSystemAccount &&
            [FBSessionUtility logIfFoundUnexpectedPermissions:permissions isRead:isRead] &&
            isRead) {
            [[NSException exceptionWithName:FBInvalidOperationException
                                     reason:@"FBSession: Publish or manage permissions are not permitted to "
              @"to be requested with read permissions."
                                   userInfo:nil]
             raise];
        }
    }
}

+ (BOOL)logIfFoundUnexpectedPermissions:(NSArray*)permissions
                                 isRead:(BOOL)isRead {
    BOOL publishPermissionFound = NO;
    BOOL readPermissionFound = NO;
    BOOL result = NO;
    for (NSString *p in permissions) {
        if ([FBUtility isPublishPermission:p]) {
            publishPermissionFound = YES;
        } else {
            readPermissionFound = YES;
        }

        // If we've found one of each we can stop looking.
        if (publishPermissionFound && readPermissionFound) {
            break;
        }
    }

    if (!isRead && readPermissionFound) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"FBSession: a permission request for publish or manage permissions contains unexpected read permissions"];
        result = YES;
    }
    if (isRead && publishPermissionFound) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:@"FBSession: a permission request for read permissions contains unexpected publish or manage permissions"];
        result = YES;
    }

    return result;
}

@end
