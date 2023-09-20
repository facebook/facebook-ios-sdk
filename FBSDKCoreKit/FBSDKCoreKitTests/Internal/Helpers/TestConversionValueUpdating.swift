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
  static var wasUpdateVersionCoarseValueCalled = false

  static func updateConversionValue(_ conversionValue: Int) {
    wasUpdateVersionValueCalled = true
  }

  static func updateCoarseConversionValue(_ coarseConversionValue: String) {
    wasUpdateVersionCoarseValueCalled = true
  }

  @available(iOS 15.4, *)
  // swiftlint:disable:next line_length
  static func updatePostbackConversionValue(_ conversionValue: Int, completionHandler completion: ((Error?) -> Void)? = nil) {
    wasUpdateVersionValueCalled = true
  }

  @available(iOS 16.1, *)
  // swiftlint:disable:next line_length
  static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: SKAdNetwork.CoarseConversionValue, completionHandler completion: ((Error?) -> Void)? = nil) {
    wasUpdateVersionValueCalled = true
    wasUpdateVersionCoarseValueCalled = true
  }

  @available(iOS 16.1, *)
  // swiftlint:disable:next line_length
  static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: SKAdNetwork.CoarseConversionValue, lockWindow: Bool, completionHandler completion: ((Error?) -> Void)? = nil) {
    wasUpdateVersionValueCalled = true
    wasUpdateVersionCoarseValueCalled = true
  }

  static func reset() {
    wasUpdateVersionValueCalled = false
    wasUpdateVersionCoarseValueCalled = false
  }
}
