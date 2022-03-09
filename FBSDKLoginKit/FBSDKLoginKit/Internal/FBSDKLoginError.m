/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginError.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#ifndef NS_ERROR_ENUM
 #define NS_ERROR_ENUM(_domain, _name) \
  enum _name : NSInteger _name; \
  enum __attribute__((ns_error_domain(_domain))) _name: NSInteger
#endif

typedef NS_ERROR_ENUM(FBSDKLoginErrorDomain, FBSDKLoginErrorSubcode)
{
  FBSDKLoginErrorSubcodeUserCheckpointed = 459,
  FBSDKLoginErrorSubcodePasswordChanged = 460,
  FBSDKLoginErrorSubcodeUnconfirmedUser = 464,
};

@implementation FBSDKLoginErrorFactory

+ (NSError *)fbErrorForFailedLoginWithCode:(FBSDKLoginError)code
{
  return [self fbErrorForFailedLoginWithCode:code innerError:nil];
}

+ (NSError *)fbErrorForFailedLoginWithCode:(FBSDKLoginError)code
                                innerError:(NSError *)innerError
{
  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];

  [FBSDKTypeUtility dictionary:userInfo setObject:innerError forKey:NSUnderlyingErrorKey];

  NSString *errorDomain = FBSDKLoginErrorDomain;
  NSString *localizedDescription = nil;

  switch ((NSInteger)code) {
    case FBSDKErrorNetwork:
      errorDomain = FBSDKErrorDomain;
      localizedDescription =
      NSLocalizedStringWithDefaultValue(
        @"LoginError.SystemAccount.Network",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Unable to connect to Facebook. Check your network connection and try again.",
        @"The user facing error message when the Accounts framework encounters a network error."
      );
      break;
    case FBSDKLoginErrorUserCheckpointed:
      localizedDescription =
      NSLocalizedStringWithDefaultValue(
        @"LoginError.SystemAccount.UserCheckpointed",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"You cannot log in to apps at this time. Please log in to www.facebook.com and follow the instructions given.",
        @"The user facing error message when the Facebook account signed in to the Accounts framework has been checkpointed."
      );
      break;
    case FBSDKLoginErrorUnconfirmedUser:
      localizedDescription =
      NSLocalizedStringWithDefaultValue(
        @"LoginError.SystemAccount.UnconfirmedUser",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Your account is not confirmed. Please log in to www.facebook.com and follow the instructions given.",
        @"The user facing error message when the Facebook account signed in to the Accounts framework becomes unconfirmed."
      );
      break;
    case FBSDKLoginErrorSystemAccountAppDisabled:
      localizedDescription =
      NSLocalizedStringWithDefaultValue(
        @"LoginError.SystemAccount.Disabled",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"Access has not been granted to the Facebook account. Verify device settings.",
        @"The user facing error message when the app slider has been disabled and login fails."
      );
      break;
    case FBSDKLoginErrorSystemAccountUnavailable:
      localizedDescription =
      NSLocalizedStringWithDefaultValue(
        @"LoginError.SystemAccount.Unavailable",
        @"FacebookSDK",
        [FBSDKInternalUtility.sharedUtility bundleForStrings],
        @"The Facebook account has not been configured on the device.",
        @"The user facing error message when the device Facebook account is unavailable and login fails."
      );
      break;
    default:
      break;
  }

  [FBSDKTypeUtility dictionary:userInfo setObject:localizedDescription forKey:NSLocalizedDescriptionKey];
  [FBSDKTypeUtility dictionary:userInfo setObject:localizedDescription forKey:FBSDKErrorLocalizedDescriptionKey];

  return [NSError errorWithDomain:errorDomain
                             code:code
                         userInfo:userInfo];
}

+ (NSError *)fbErrorForSystemPasswordChange:(NSError *)innerError
{
  NSString *failureReasonAndDescription =
  NSLocalizedStringWithDefaultValue(
    @"LoginError.SystemAccount.PasswordChange",
    @"FacebookSDK",
    [FBSDKInternalUtility.sharedUtility bundleForStrings],
    @"Your Facebook password has changed. To confirm your password, open Settings > Facebook and tap your name.",
    @"The user facing error message when the device Facebook account password is incorrect and login fails."
  );
  NSMutableDictionary<NSString *, id> *userInfo = [@{
                                                     FBSDKErrorLocalizedDescriptionKey : failureReasonAndDescription,
                                                     NSLocalizedDescriptionKey : failureReasonAndDescription
                                                   } mutableCopy];

  [FBSDKTypeUtility dictionary:userInfo setObject:innerError forKey:NSUnderlyingErrorKey];

  return [NSError errorWithDomain:FBSDKLoginErrorDomain
                             code:FBSDKLoginErrorPasswordChanged
                         userInfo:userInfo];
}

+ (nullable NSError *)fbErrorFromReturnURLParameters:(NSDictionary<NSString *, id> *)parameters
{
  NSError *error = nil;

  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:userInfo setObject:[FBSDKTypeUtility dictionary:parameters objectForKey:@"error_message" ofType:NSString.class] forKey:FBSDKErrorDeveloperMessageKey];

  if (userInfo.count > 0) {
    [FBSDKTypeUtility dictionary:userInfo setObject:[FBSDKTypeUtility dictionary:parameters objectForKey:@"error" ofType:NSString.class] forKey:FBSDKErrorDeveloperMessageKey];
    [FBSDKTypeUtility dictionary:userInfo setObject:[FBSDKTypeUtility dictionary:parameters objectForKey:@"error_code" ofType:NSString.class] forKey:FBSDKGraphRequestErrorGraphErrorCodeKey];

    if (!userInfo[FBSDKErrorDeveloperMessageKey]) {
      [FBSDKTypeUtility dictionary:userInfo setObject:[FBSDKTypeUtility dictionary:parameters objectForKey:@"error_reason" ofType:NSString.class] forKey:FBSDKErrorDeveloperMessageKey];
    }

    [FBSDKTypeUtility dictionary:userInfo setObject:@(FBSDKGraphRequestErrorOther) forKey:FBSDKGraphRequestErrorKey];

    error = [NSError errorWithDomain:FBSDKErrorDomain
                                code:FBSDKErrorGraphRequestGraphAPI
                            userInfo:userInfo];
  }

  return error;
}

+ (nullable NSError *)fbErrorFromServerError:(NSError *)serverError
{
  NSError *loginError = nil;

  if ([serverError.domain isEqualToString:FBSDKErrorDomain]) {
    NSDictionary<NSString *, id> *response = [FBSDKTypeUtility dictionaryValue:serverError.userInfo[FBSDKGraphRequestErrorParsedJSONResponseKey]];
    NSDictionary<NSString *, id> *body = [FBSDKTypeUtility dictionaryValue:response[@"body"]];
    NSDictionary<NSString *, id> *error = [FBSDKTypeUtility dictionaryValue:body[@"error"]];
    NSInteger subcode = [FBSDKTypeUtility integerValue:error[@"error_subcode"]];

    switch (subcode) {
      case FBSDKLoginErrorSubcodeUserCheckpointed:
        loginError = [self fbErrorForFailedLoginWithCode:FBSDKLoginErrorUserCheckpointed
                                              innerError:serverError];
        break;
      case FBSDKLoginErrorSubcodePasswordChanged:
        loginError = [self fbErrorForFailedLoginWithCode:FBSDKLoginErrorPasswordChanged
                                              innerError:serverError];
        break;
      case FBSDKLoginErrorSubcodeUnconfirmedUser:
        loginError = [self fbErrorForFailedLoginWithCode:FBSDKLoginErrorUnconfirmedUser
                                              innerError:serverError];
        break;
    }
  }

  return loginError;
}

+ (NSError *)fbErrorWithSystemAccountStoreDeniedError:(NSError *)accountStoreError
                                       isCancellation:(BOOL *)cancellation
{
  // The Accounts framework returns an ACErrorPermissionDenied error for both user denied errors,
  // Facebook denied errors, and other things. Unfortunately examining the contents of the
  // description is the only means available to determine the reason for the error.
  NSString *description = accountStoreError.userInfo[NSLocalizedDescriptionKey];
  NSError *err = nil;

  if (description) {
    // If a parenthetical error code exists, map it ot a Facebook server error
    FBSDKLoginError errorCode = FBSDKLoginErrorReserved;
    if ([description rangeOfString:@"(459)"].location != NSNotFound) {
      // The Facebook server could not fulfill this access request: Error validating access token:
      // You cannot access the app till you log in to www.facebook.com and follow the instructions given. (459)

      // The OAuth endpoint directs people to www.facebook.com when an account has been
      // checkpointed. If the web address is present, assume it's due to a checkpoint.
      errorCode = FBSDKLoginErrorUserCheckpointed;
    } else if ([description rangeOfString:@"(452)"].location != NSNotFound
               || [description rangeOfString:@"(460)"].location != NSNotFound) {
      // The Facebook server could not fulfill this access request: Error validating access token:
      // Session does not match current stored session. This may be because the user changed the password since
      // the time the session was created or Facebook has changed the session for security reasons. (452)or(460)

      // If the login failed due to the session changing, maybe it's due to the password
      // changing. Direct the user to update the password in the Settings > Facebook.
      err = [self fbErrorForSystemPasswordChange:accountStoreError];
    } else if ([description rangeOfString:@"(464)"].location != NSNotFound) {
      // The Facebook server could not fulfill this access request: Error validating access token:
      // Sessions for the user  are not allowed because the user is not a confirmed user. (464)
      errorCode = FBSDKLoginErrorUnconfirmedUser;
    }

    if (errorCode != FBSDKLoginErrorReserved) {
      err = [self fbErrorForFailedLoginWithCode:errorCode];
    }
  } else {
    // If there is no description, assume this is a user cancellation. No error object is
    // returned for a cancellation.
    if (cancellation != NULL) {
      *cancellation = YES;
    }
  }

  return err;
}

@end

#endif
