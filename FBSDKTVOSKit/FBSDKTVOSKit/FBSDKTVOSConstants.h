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
 The error domain for all errors from FBSDKTVOSKit.
 Error codes from the SDK in the range 400-499 are reserved for this domain.
 */
FOUNDATION_EXPORT NSErrorDomain const FBSDKTVOSErrorDomain
NS_SWIFT_NAME(TVOSErrorDomain);

/**
 FBSDKTVOSError
 Error codes for FBSDKTVOSErrorDomain.
 */
typedef NS_ERROR_ENUM (FBSDKTVOSErrorDomain, FBSDKTVOSError)
{
  /// Reserved.
  FBSDKTVOSErrorReserved = 400,

  /// The error code for unknown errors.
  FBSDKTVOSErrorUnknown,
} NS_SWIFT_NAME(TVOSError);

NS_ASSUME_NONNULL_END
