/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKLoginKit/FBSDKLoginErrorDomain.h>

NS_ASSUME_NONNULL_BEGIN

/// Custom error type for login errors in the login error domain
typedef NS_ERROR_ENUM (FBSDKLoginErrorDomain, FBSDKLoginError)
{
  /// Reserved
  FBSDKLoginErrorReserved = 300,

  /// The error code for unknown errors
  FBSDKLoginErrorUnknown,

  /// The user's password has changed and must log in again
  FBSDKLoginErrorPasswordChanged,

  /// The user must log in to their account on www.facebook.com to restore access
  FBSDKLoginErrorUserCheckpointed,

  /// Indicates a failure to request new permissions because the user has changed
  FBSDKLoginErrorUserMismatch,

  /// The user must confirm their account with Facebook before logging in
  FBSDKLoginErrorUnconfirmedUser,

  /// The Accounts framework failed without returning an error, indicating the app's slider in the
  /// iOS Facebook Settings (device Settings -> Facebook -> App Name) has been disabled.
  FBSDKLoginErrorSystemAccountAppDisabled,

  /// An error occurred related to Facebook system Account store
  FBSDKLoginErrorSystemAccountUnavailable,

  /// The login response was missing a valid challenge string
  FBSDKLoginErrorBadChallengeString,

  /// The ID token returned in login response was invalid
  FBSDKLoginErrorInvalidIDToken,

  /// A current access token was required and not provided
  FBSDKLoginErrorMissingAccessToken,
} NS_SWIFT_NAME(LoginError);

NS_ASSUME_NONNULL_END
