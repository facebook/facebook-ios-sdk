/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestCodelessEvents: NSObject, CodelessIndexing {

  static var wasEnabledCalled = false

  static func enable() {
    wasEnabledCalled = true
  }

  static func reset() {
    wasEnabledCalled = false
  }
}
