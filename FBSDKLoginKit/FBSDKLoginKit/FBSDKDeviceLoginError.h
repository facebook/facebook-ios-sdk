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

/// Custom error type for device login errors in the login error domain
typedef NS_ERROR_ENUM (FBSDKLoginErrorDomain, FBSDKDeviceLoginError) {
  /// Your device is polling too frequently
  FBSDKDeviceLoginErrorExcessivePolling = 1349172,

  /// User has declined to authorize your application
  FBSDKDeviceLoginErrorAuthorizationDeclined = 1349173,

  /// User has not yet authorized your application. Continue polling.
  FBSDKDeviceLoginErrorAuthorizationPending = 1349174,

  /// The code you entered has expired
  FBSDKDeviceLoginErrorCodeExpired = 1349152
} NS_SWIFT_NAME(DeviceLoginError);

NS_ASSUME_NONNULL_END
