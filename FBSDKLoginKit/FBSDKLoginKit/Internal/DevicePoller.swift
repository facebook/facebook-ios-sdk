/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

struct DevicePoller: DevicePolling {
  func schedule(interval: UInt, block: @escaping () -> Void) {
    let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(Int(interval))
    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: block)
  }
}
