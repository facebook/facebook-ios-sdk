/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestDeviceLoginManagerDelegate: NSObject, DeviceLoginManagerDelegate {
  var capturedLoginManager: DeviceLoginManager?
  var capturedCodeInfo: DeviceLoginCodeInfo?
  var capturedResult: DeviceLoginManagerResult?
  var capturedError: Error?

  func deviceLoginManager(
    _ loginManager: DeviceLoginManager,
    startedWith codeInfo: DeviceLoginCodeInfo
  ) {
    capturedLoginManager = loginManager
    capturedCodeInfo = codeInfo
  }

  func deviceLoginManager(
    _ loginManager: DeviceLoginManager,
    completedWith result: DeviceLoginManagerResult?,
    error: Error?
  ) {
    capturedLoginManager = loginManager
    capturedResult = result
    capturedError = error
  }
}
