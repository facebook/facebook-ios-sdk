/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The error domain for all errors from FBSDKLoginKit

 Error codes from the SDK in the range 300-399 are reserved for this domain.
 */
FOUNDATION_EXPORT NSErrorDomain const FBSDKLoginErrorDomain
NS_SWIFT_NAME(LoginErrorDomain);

#ifndef NS_ERROR_ENUM
 #define NS_ERROR_ENUM(_domain, _name) \
  enum _name : NSInteger _name; \
  enum __attribute__((ns_error_domain(_domain))) _name: NSInteger
#endif

/**
 FBSDKLoginError
  Error codes for FBSDKLoginErrorDomain.
 */
typedef NS_ERROR_ENUM (FBSDKLoginErrorDomain, FBSDKLoginError)
{
  /**
    Reserved.
   */
  FBSDKLoginErrorReserved = 300,

  /**
    The error code for unknown errors.
   */
  FBSDKLoginErrorUnknown,

  /**
    The user's password has changed and must log in again
  */
  FBSDKLoginErrorPasswordChanged,

  /**
    The user must log in to their account on www.facebook.com to restore access
  */
  FBSDKLoginErrorUserCheckpointed,

  /**
    Indicates a failure to request new permissions because the user has changed.
   */
  FBSDKLoginErrorUserMismatch,

  /**
    The user must confirm their account with Facebook before logging in
  */
  FBSDKLoginErrorUnconfirmedUser,

  /**
    The Accounts framework failed without returning an error, indicating the
   app's slider in the iOS Facebook Settings (device Settings -> Facebook -> App Name) has
   been disabled.
   */
  FBSDKLoginErrorSystemAccountAppDisabled,

  /**
    An error occurred related to Facebook system Account store
  */
  FBSDKLoginErrorSystemAccountUnavailable,

  /**
    The login response was missing a valid challenge string.
  */
  FBSDKLoginErrorBadChallengeString,

  /**
    The ID token returned in login response was invalid
  */
  FBSDKLoginErrorInvalidIDToken,

  /**
   A current access token was required and not provided
   */
  FBSDKLoginErrorMissingAccessToken,
} NS_SWIFT_NAME(LoginError);

/**
 FBSDKDeviceLoginError
 Error codes for FBSDKDeviceLoginErrorDomain.
 */
typedef NS_ERROR_ENUM (FBSDKLoginErrorDomain, FBSDKDeviceLoginError) {
  /**
   Your device is polling too frequently.
   */
  FBSDKDeviceLoginErrorExcessivePolling = 1349172,
  /**
   User has declined to authorize your application.
   */
  FBSDKDeviceLoginErrorAuthorizationDeclined = 1349173,
  /**
   User has not yet authorized your application. Continue polling.
   */
  FBSDKDeviceLoginErrorAuthorizationPending = 1349174,
  /**
   The code you entered has expired.
   */
  FBSDKDeviceLoginErrorCodeExpired = 1349152
} NS_SWIFT_NAME(DeviceLoginError);

NS_ASSUME_NONNULL_END
