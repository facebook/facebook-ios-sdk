/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The error domain for all errors from FBSDKShareKit.

 Error codes from the SDK in the range 200-299 are reserved for this domain.
 */
FOUNDATION_EXPORT NSErrorDomain const FBSDKShareErrorDomain
NS_SWIFT_NAME(ShareErrorDomain);

#ifndef NS_ERROR_ENUM
 #define NS_ERROR_ENUM(_domain, _name) \
  enum _name : NSInteger _name; \
  enum __attribute__((ns_error_domain(_domain))) _name: NSInteger
#endif

/**
 FBSDKShareError
 Error codes for FBSDKShareErrorDomain.
 */
typedef NS_ERROR_ENUM (FBSDKShareErrorDomain, FBSDKShareError)
{
  /**
   Reserved.
   */
  FBSDKShareErrorReserved = 200,

  /**
   The error code for errors from uploading open graph objects.
   */
  FBSDKShareErrorOpenGraph,

  /**
   The error code for when a sharing dialog is not available.

   Use the canShare methods to check for this case before calling show.
   */
  FBSDKShareErrorDialogNotAvailable,

  /**
   @The error code for unknown errors.
   */
  FBSDKShareErrorUnknown,
} NS_SWIFT_NAME(ShareError);

NS_ASSUME_NONNULL_END
