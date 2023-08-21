/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// A delegate for `DeviceLoginManager`.
@objc(FBSDKDeviceLoginManagerDelegate)
public protocol DeviceLoginManagerDelegate {

  /**
   Indicates the device login flow has started. You should parse `codeInfo` to present the code to the user to enter.
   @param loginManager the login manager instance.
   @param codeInfo the code info data.
   */
  @objc(deviceLoginManager:startedWithCodeInfo:)
  func deviceLoginManager(
    _ loginManager: DeviceLoginManager,
    startedWith codeInfo: DeviceLoginCodeInfo
  )

  /**
   Indicates the device login flow has finished.
   @param loginManager the login manager instance.
   @param result the results of the login flow.
   @param error the error, if available.
   The flow can be finished if the user completed the flow, cancelled, or if the code has expired.
   */
  @objc(deviceLoginManager:completedWithResult:error:)
  func deviceLoginManager(
    _ loginManager: DeviceLoginManager,
    completedWith result: DeviceLoginManagerResult?,
    error: Error?
  )
}
