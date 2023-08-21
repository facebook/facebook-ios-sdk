/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// Represents the results of the a device login flow. This is used by `DeviceLoginManager`
@objcMembers
@objc(FBSDKDeviceLoginManagerResult)
public final class DeviceLoginManagerResult: NSObject {

  /// The token
  public private(set) var accessToken: AccessToken?

  /// Indicates if the login was cancelled by the user, or if the device login code has expired.
  public private(set) var isCancelled: Bool

  /**
   Internal method exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  public init(
    token: AccessToken?,
    isCancelled cancelled: Bool
  ) {
    accessToken = token
    isCancelled = cancelled
  }
}
