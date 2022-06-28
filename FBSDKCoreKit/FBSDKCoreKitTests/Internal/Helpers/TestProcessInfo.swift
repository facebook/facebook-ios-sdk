/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
final class TestProcessInfo: OperatingSystemVersionComparing {
  var stubbedOperatingSystemCheckResult: Bool

  init(stubbedOperatingSystemCheckResult: Bool = true) {
    self.stubbedOperatingSystemCheckResult = stubbedOperatingSystemCheckResult
  }

  func fb_isOperatingSystemAtLeast(_ version: OperatingSystemVersion) -> Bool {
    stubbedOperatingSystemCheckResult
  }
}
