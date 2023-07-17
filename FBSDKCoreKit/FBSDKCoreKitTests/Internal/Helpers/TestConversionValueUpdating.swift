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
final class TestConversionValueUpdating: NSObject, _ConversionValueUpdating {

  static var wasUpdateVersionValueCalled = false

  static func updateConversionValue(_ conversionValue: Int) {
    wasUpdateVersionValueCalled = true
  }

  @available(iOS 15.4, *)
  // swiftlint:disable:next line_length
  static func updatePostbackConversionValue(_ conversionValue: Int, completionHandler completion: @escaping (Error) -> Void) {
    wasUpdateVersionValueCalled = true
  }

  @available(iOS 16.0, *)
  // swiftlint:disable:next line_length
  static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: SKAdNetwork.CoarseConversionValue, completionHandler completion: @escaping (Error) -> Void) {
    wasUpdateVersionValueCalled = true
  }

  @available(iOS 16.0, *)
  // swiftlint:disable:next line_length
  static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: SKAdNetwork.CoarseConversionValue, lockWindow: Bool, completionHandler completion: @escaping (Error) -> Void) {
    wasUpdateVersionValueCalled = true
  }

  static func reset() {
    wasUpdateVersionValueCalled = false
  }
}
