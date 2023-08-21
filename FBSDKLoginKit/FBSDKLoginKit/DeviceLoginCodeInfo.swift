/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Describes the initial response when starting the device login flow.
 This is used by `DeviceLoginManager`.
 */
@objcMembers
@objc(FBSDKDeviceLoginCodeInfo)
public final class DeviceLoginCodeInfo: NSObject {
  /// The unique id for this login flow.
  public let identifier: String

  /// The short "user_code" that should be presented to the user.
  public let loginCode: String

  /// The verification URL.
  public let verificationURL: URL

  /// The expiration date.
  public let expirationDate: Date

  /// The polling interval
  public let pollingInterval: UInt

  private static let minPollingInterval: UInt = 5

  public init(
    identifier: String,
    loginCode: String,
    verificationURL: URL,
    expirationDate: Date,
    pollingInterval: UInt
  ) {
    self.identifier = identifier
    self.loginCode = loginCode
    self.verificationURL = verificationURL
    self.expirationDate = expirationDate
    self.pollingInterval = max(pollingInterval, Self.minPollingInterval)
  }
}
