/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 The error domain for all errors from FBSDKShareKit.

 Error codes from the SDK in the range 200-299 are reserved for this domain.
 */
public let ShareErrorDomain = "com.facebook.sdk.share" // swiftlint:disable:this identifier_name

/**
 ShareError
 Error codes for ShareErrorDomain.
 */
@objc(FBSDKShareError)
public enum ShareError: Int {
  /// Reserved
  case reserved = 200

  /// The error code for errors from uploading open graph objects.
  case openGraph

  /// The error code for when a sharing dialog is not available.
  /// Use the canShare methods to check for this case before calling show.
  case dialogNotAvailable

  /// The error code for unknown errors.
  case unknown
}
