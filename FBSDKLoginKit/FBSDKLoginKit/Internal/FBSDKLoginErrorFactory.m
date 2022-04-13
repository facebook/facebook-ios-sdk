/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginErrorFactory.h"

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

@end

#endif
