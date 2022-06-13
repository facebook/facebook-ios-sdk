/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKDevicePoller)
public final class _DevicePoller: NSObject, DevicePolling {
  public func schedule(interval: UInt, block: @escaping () -> Void) {
    let dispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(Int(interval))
    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: block)
  }
}
