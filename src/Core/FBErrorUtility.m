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

#import "FBErrorUtility+Internal.h"

#import "FBAccessTokenData+Internal.h"
#import "FBError.h"
#import "FBSafeCollections.h"
#import "FBSession.h"
#import "FBUtility.h"

const int FBOAuthError = 190;
static const int FBAPISessionError = 102;
static const int FBAPIServiceError = 2;
static const int FBAPIUnknownError = 1;
static const int FBAPITooManyCallsError = 4;
static const int FBAPIUserTooManyCallsError = 17;
static const int FBAPIPermissionDeniedError = 10;
static const int FBAPIPermissionsStartError = 200;
static const int FBAPIPermissionsEndError = 299;
static const int FBSDKRetryErrorSubcode = 65000;
static const int FBSDKSystemPasswordErrorSubcode = 65001;

@implementation FBErrorUtility

+ (FBErrorCategory)errorCategoryForError:(NSError *)error {
    int code = 0, subcode = 0;

    [FBErrorUtility fberrorGetCodeValueForError:error
                                          index:0
                                           code:&code
                                        subcode:&subcode];

    return [FBErrorUtility fberrorCategoryFromError:error
                                               code:code
                                            subcode:subcode
                               returningUserMessage:nil
                                andShouldNotifyUser:nil];
}

+ (BOOL)shouldNotifyUserForError:(NSError *)error {
    BOOL shouldNotifyUser = NO;
    int code = 0, subcode = 0;

    [FBErrorUtility fberrorGetCodeValueForError:error
                                          index:0
                                           code:&code
                                        subcode:&subcode];

    [FBErrorUtility fberrorCategoryFromError:error
                                        code:code
                                     subcode:subcode
                        returningUserMessage:nil
                         andShouldNotifyUser:&shouldNotifyUser];
    return shouldNotifyUser;
}

+ (NSString *)userMessageForError:(NSError *)error {
    NSString *message = nil;
    int code = 0, subcode = 0;
    [FBErrorUtility fberrorGetCodeValueForError:error
                                          index:0
                                           code:&code
                                        subcode:&subcode];

    [FBErrorUtility fberrorCategoryFromError:error
                                        code:code
                                     subcode:subcode
                        returningUserMessage:&message
                         andShouldNotifyUser:nil];
    return message;
}

// This method is responsible for error categorization and response policy for
// the SDK; for example, the rules in this method dictate when an auth error is
// categorized as *Retry vs *ReopenSession, which in turn impacts whether
// FBRequestConnection auto-closes a session for a given error; additionally,
// this method generates categories, and user messages for the public NSError
// category
+ (FBErrorCategory)fberrorCategoryFromError:(NSError *)error
                                       code:(int)errorCode
                                    subcode:(int)subcode
                       returningUserMessage:(NSString **)puserMessage
                        andShouldNotifyUser:(BOOL *)pshouldNotifyUser {

    NSString *userMessageKey = nil;
    NSString *userMessageDefault = nil;

    BOOL shouldNotifyUser = NO;

    // defaulting to a non-facebook category
    FBErrorCategory category = FBErrorCategoryInvalid;

    // determine if we have a facebook error category here
    if ([[error domain] isEqualToString:FacebookSDKDomain]) {
        // now defaulting to an unknown (future) facebook category
        category = FBErrorCategoryFacebookOther;
        if ([error code] == FBErrorLoginFailedOrCancelled) {
            NSString *errorLoginFailedReason = [error userInfo][FBErrorLoginFailedReason];
            if (errorLoginFailedReason == FBErrorLoginFailedReasonInlineCancelledValue ||
                errorLoginFailedReason == FBErrorLoginFailedReasonUserCancelledSystemValue ||
                errorLoginFailedReason == FBErrorLoginFailedReasonUserCancelledValue ||
                errorLoginFailedReason == FBErrorReauthorizeFailedReasonUserCancelled ||
                errorLoginFailedReason == FBErrorReauthorizeFailedReasonUserCancelledSystem) {
                category = FBErrorCategoryUserCancelled;
            } else {
                // for now, we use "Retry" as a sentinal indicating any auth error
                category = FBErrorCategoryRetry;
            }
        } else if ([error code] == FBErrorHTTPError) {
            if ((errorCode == FBOAuthError || errorCode == FBAPISessionError)) {
                category = FBErrorCategoryAuthenticationReopenSession;
            } else if (errorCode == FBAPIServiceError || errorCode == FBAPIUnknownError) {
                category = FBErrorCategoryServer;
            } else if (errorCode == FBAPITooManyCallsError || errorCode == FBAPIUserTooManyCallsError) {
                category = FBErrorCategoryThrottling;
            } else if (errorCode == FBAPIPermissionDeniedError ||
                       (errorCode >= FBAPIPermissionsStartError && errorCode <= FBAPIPermissionsEndError)) {
                category = FBErrorCategoryPermissions;
            }
        }
    }

    // determine details about category, user notification, and message
    switch (category) {
        case FBErrorCategoryAuthenticationReopenSession:
            switch (subcode) {
                case FBSDKRetryErrorSubcode:
                    category = FBErrorCategoryRetry;
                    break;
                case FBAuthSubcodeExpired:
                    if (![FBErrorUtility fberrorIsErrorFromSystemSession:error]) {
                        userMessageKey = @"FBE:ReconnectApplication";
                        userMessageDefault = @"Please log into this app again to reconnect your Facebook account.";
                    }
                    break;
                case FBSDKSystemPasswordErrorSubcode:
                case FBAuthSubcodePasswordChanged:
                    if (subcode == FBSDKSystemPasswordErrorSubcode
                        || [FBErrorUtility fberrorIsErrorFromSystemSession:error]) {
                        userMessageKey = @"FBE:PasswordChangedDevice";
                        userMessageDefault = @"Your Facebook password has changed. To confirm your password, open Settings > Facebook and tap your name.";
                        shouldNotifyUser = YES;
                    } else {
                        userMessageKey = @"FBE:PasswordChanged";
                        userMessageDefault = @"Your Facebook password has changed. Please log into this app again to reconnect your Facebook account.";
                    }
                    break;
                case FBAuthSubcodeUserCheckpointed:
                    userMessageKey = @"FBE:WebLogIn";
                    userMessageDefault = @"Your Facebook account is locked. Please log into www.facebook.com to continue.";
                    shouldNotifyUser = YES;
                    category = FBErrorCategoryRetry;
                    break;
                case FBAuthSubcodeUnconfirmedUser:
                    userMessageKey = @"FBE:Unconfirmed";
                    userMessageDefault = @"Your Facebook account is locked. Please log into www.facebook.com to continue.";
                    shouldNotifyUser = YES;
                    break;
                case FBAuthSubcodeAppNotInstalled:
                    userMessageKey = @"FBE:AppNotInstalled";
                    userMessageDefault = @"Please log into this app again to reconnect your Facebook account.";
                    break;
                default:
                    if ([FBErrorUtility fberrorIsErrorFromSystemSession:error] && errorCode == FBOAuthError) {
                        // This would include the case where the user has toggled the app slider in iOS 6 (and the session
                        //  had already been open).
                        userMessageKey = @"FBE:OAuthDevice";
                        userMessageDefault = @"To use your Facebook account with this app, open Settings > Facebook and make sure this app is turned on.";
                        shouldNotifyUser = YES;
                    }
                    break;
            }
            break;
        case FBErrorCategoryPermissions:
            userMessageKey = @"FBE:GrantPermission";
            userMessageDefault = @"This app doesn't have permission to do this. To change permissions, try logging into the app again.";
            break;
        case FBErrorCategoryRetry:
            if ([error code] == FBErrorLoginFailedOrCancelled) {
                if ([[error userInfo][FBErrorLoginFailedReason] isEqualToString:FBErrorLoginFailedReasonSystemDisallowedWithoutErrorValue]) {
                    // This maps to the iOS 6 slider disabled case.
                    userMessageKey = @"FBE:OAuthDevice";
                    userMessageDefault = @"To use your Facebook account with this app, open Settings > Facebook and make sure this app is turned on.";
                    shouldNotifyUser = YES;
                    category = FBErrorCategoryServer;
                } else if ([[error userInfo][FBErrorLoginFailedReason] isEqualToString:FBErrorLoginFailedReasonSystemError]) {
                    // For other system auth errors, we assume it is not retriable and will surface
                    // an underlying message is possible (e.g., when there is no connectivity,
                    // Apple will report "The Internet connection appears to be offline.")
                    userMessageKey = @"FBE:DeviceError";
                    userMessageDefault = [[error userInfo][FBErrorInnerErrorKey] userInfo][NSLocalizedDescriptionKey] ? : ([[error userInfo][FBErrorInnerErrorKey] userInfo][NSLocalizedFailureReasonErrorKey] ? :
                    @"Something went wrong. Please make sure you're connected to the internet and try again.");

                    shouldNotifyUser = YES;
                    category = FBErrorCategoryServer;
                } else if ([[error userInfo][FBErrorLoginFailedOriginalErrorCode] integerValue] == FBErrorOperationDisallowedForRestrictedTreatment) {
                    category = FBErrorCategoryUserCancelled;
                }
            }
            break;
        case FBErrorCategoryInvalid:
        case FBErrorCategoryServer:
        case FBErrorCategoryThrottling:
        case FBErrorCategoryBadRequest:
        case FBErrorCategoryFacebookOther:
        default:
            userMessageKey = nil;
            userMessageDefault = nil;
            break;
    }

    // If error_user_msg error message is available - always show it to the user
    NSString *apiUserMessage = [self apiUserMessageForError:error];
    if ([apiUserMessage length]) {
        userMessageDefault = apiUserMessage;
        userMessageKey = apiUserMessage;
        shouldNotifyUser = YES;
    }

    if (pshouldNotifyUser) {
        *pshouldNotifyUser = shouldNotifyUser;
    }

    if (puserMessage) {
        if (userMessageKey) {
            *puserMessage = [FBUtility localizedStringForKey:userMessageKey
                                                 withDefault:userMessageDefault];
        } else {
            *puserMessage = nil;
        }
    }
    return category;
}

+ (BOOL)fberrorIsErrorFromSystemSession:(NSError *)error {
    // Categorize the error as system error if we have session state, or the error is wrapping an error from Apple.
    return ((FBSession *)error.userInfo[FBErrorSessionKey]).accessTokenData.loginType == FBSessionLoginTypeSystemAccount
    || [((NSError *)error.userInfo[FBErrorInnerErrorKey]).domain isEqualToString:@"com.apple.accounts"];
}

+ (void)fberrorGetCodeValueForError:(NSError *)error
                              index:(NSUInteger)index
                               code:(int *)pcode
                            subcode:(int *)psubcode {
    NSDictionary *userInfo = error.userInfo;
    NSArray *responseAsArray = [FBSafeCollections arrayForKey:FBErrorParsedJSONResponseKey fromDictionary:userInfo];
    NSDictionary *item = [FBSafeCollections dictionaryAtIndex:index fromArray:responseAsArray];
    if (!item) {
        item = [FBSafeCollections dictionaryForKey:FBErrorParsedJSONResponseKey fromDictionary:userInfo];
    }

    // spelunking a JSON array & nested objects (eg. response[index].body.error.code)
    NSNumber *code = nil;
    NSNumber *subCode = nil;
    NSDictionary *body = [FBSafeCollections dictionaryForKey:@"body" fromDictionary:item];
    NSDictionary *innerError = [FBSafeCollections dictionaryForKey:@"error" fromDictionary:body];
    if (innerError) {
        // response[index].body.error.code
        if (pcode && (code = [FBSafeCollections numberForKey:@"code" fromDictionary:innerError])) {
            *pcode = [code intValue];
        }

        // response[index].body.error.error_subcode
        if (psubcode && (subCode = [FBSafeCollections numberForKey:@"error_subcode" fromDictionary:innerError])) {
            *psubcode = [subCode intValue];
        }
    }
}

+ (NSError *)fberrorForRetry:(NSError *)innerError {
    NSMutableDictionary *userInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:
                                               @{
                                                 FBErrorParsedJSONResponseKey : @{
                                                         @"body" : @{
                                                                 @"error" : @{
                                                                         @"code": [NSNumber numberWithInt:FBOAuthError],
                                                                         @"error_subcode" : [NSNumber numberWithInt:FBSDKRetryErrorSubcode]
                                                                         }
                                                                 }
                                                         }
                                                 }];
    if (innerError) {
        [userInfoDictionary setObject:innerError forKey:FBErrorInnerErrorKey];
    }
    return [NSError errorWithDomain:FacebookSDKDomain
                               code:FBErrorHTTPError
                           userInfo:userInfoDictionary];
}

+ (NSError *)fberrorForSystemPasswordChange:(NSError *)innerError {
    NSMutableDictionary *userInfoDictionary = [NSMutableDictionary dictionaryWithDictionary:
                                               @{
                                                 FBErrorParsedJSONResponseKey : @{
                                                         @"body" : @{
                                                                 @"error" : @{
                                                                         @"code": [NSNumber numberWithInt:FBOAuthError],
                                                                         @"error_subcode" : [NSNumber numberWithInt:FBSDKSystemPasswordErrorSubcode]
                                                                         }
                                                                 }
                                                         }
                                                 }];
    if (innerError) {
        [userInfoDictionary setObject:innerError forKey:FBErrorInnerErrorKey];
    }
    return [NSError errorWithDomain:FacebookSDKDomain
                               code:FBErrorHTTPError
                           userInfo:userInfoDictionary];
}

+ (NSDictionary *)jsonDictionaryForError:(NSError *)error
{
    if (error == nil) {
        return nil;
    }

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    dictionary[@"code"] = @(error.code);

    NSString *domain = error.domain;
    if (domain) {
        dictionary[@"domain"] = domain;
    }

    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [error.userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([NSJSONSerialization isValidJSONObject:obj]) {
            userInfo[key] = obj;
        }
    }];

    NSError *innerError = error.userInfo[FBErrorInnerErrorKey];
    if (innerError) {
        userInfo[FBErrorInnerErrorKey] = [self jsonDictionaryForError:innerError];
    }

    NSDictionary *resultUserInfo = [userInfo copy];
    [userInfo release];
    dictionary[@"userInfo"] = resultUserInfo;
    [resultUserInfo release];

    NSDictionary *result = [[dictionary copy] autorelease];
    [dictionary release];
    return result;
}

+ (BOOL)errorIsNetworkError:(NSError *)error
{
    if (error == nil) {
        return NO;
    }

    NSError *innerError = error.userInfo[FBErrorInnerErrorKey];
    if ([self errorIsNetworkError:innerError]) {
        return YES;
    }

    switch (error.code) {
        case NSURLErrorTimedOut:
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorInternationalRoamingOff:
        case NSURLErrorCallIsActive:
        case NSURLErrorDataNotAllowed:
            return YES;
        default:
            return NO;
    }
}

+ (NSDictionary *)innerErrorInfoFromError:(NSError *)error
{
    NSDictionary *jsonResponse = [FBSafeCollections dictionaryForKey:FBErrorParsedJSONResponseKey fromDictionary:error.userInfo];
    NSDictionary *body = [FBSafeCollections dictionaryForKey:@"body" fromDictionary:jsonResponse];
    return [FBSafeCollections dictionaryForKey:@"error" fromDictionary:body];
}

+ (NSString *)userTitleForError:(NSError *)error
{
    return [FBSafeCollections stringForKey:@"error_user_title" fromDictionary:[self innerErrorInfoFromError:error]];
}

+ (NSString *)apiUserMessageForError:(NSError *)error
{
    return [FBSafeCollections stringForKey:@"error_user_msg" fromDictionary:[self innerErrorInfoFromError:error]];
}

+ (BOOL)isTransientError:(NSError *)error
{
    NSDictionary *innerError = [self innerErrorInfoFromError:error];
    return [[FBSafeCollections numberForKey:@"is_transient" fromDictionary:innerError] boolValue];
}

@end
