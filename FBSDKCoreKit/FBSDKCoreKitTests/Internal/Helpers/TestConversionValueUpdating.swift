/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

@objcMembers
class TestConversionValueUpdating: NSObject, ConversionValueUpdating {

  static var wasUpdateVersionValueCalled = false

  static func updateConversionValue(_ conversionValue: Int) {
    wasUpdateVersionValueCalled = true
  }

  static func reset() {
    wasUpdateVersionValueCalled = false
  }
}
