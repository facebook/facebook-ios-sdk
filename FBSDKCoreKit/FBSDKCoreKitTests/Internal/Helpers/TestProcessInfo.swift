/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
class TestProcessInfo: NSObject, OperatingSystemVersionComparing {
  let stubbedOperatingSystemCheckResult: Bool

  override convenience init() {
    self.init(stubbedOperatingSystemCheckResult: true)
  }

  init(stubbedOperatingSystemCheckResult: Bool = true) {
    self.stubbedOperatingSystemCheckResult = stubbedOperatingSystemCheckResult
  }

  func isOperatingSystemAtLeast(_ version: OperatingSystemVersion) -> Bool {
    stubbedOperatingSystemCheckResult
  }
}
