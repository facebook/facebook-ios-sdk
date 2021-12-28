/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestDevicePoller: DevicePolling {
  var capturedInterval: UInt = 0

  func scheduleBlock(_ block: @escaping () -> Void, interval: UInt) {
    capturedInterval = interval
    block()
  }
}
