/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract The error domain for all errors from FBSDKTVOSKit.
 @discussion Error codes from the SDK in the range 400-499 are reserved for this domain.
 */
FOUNDATION_EXPORT NSErrorDomain const FBSDKTVOSErrorDomain
NS_SWIFT_NAME(TVOSErrorDomain);

/*!
 FBSDKTVOSError
 @abstract Error codes for FBSDKTVOSErrorDomain.
 */
typedef NS_ERROR_ENUM (FBSDKTVOSErrorDomain, FBSDKTVOSError)
{
  /*!
   @abstract Reserved.
   */
  FBSDKTVOSErrorReserved = 400,

  /*!
   @abstract The error code for unknown errors.
   */
  FBSDKTVOSErrorUnknown,
} NS_SWIFT_NAME(TVOSError);

NS_ASSUME_NONNULL_END
