/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

// swiftformat:disable indent
@objcMembers
class TestAEMReporter: NSObject, AEMReporterProtocol {

  static var enableWasCalled = false
  static var setConversionFilteringEnabledWasCalled = false
  static var capturedConversionFilteringEnabled = false
  static var setCatalogMatchingEnabledWasCalled = false
  static var capturedCatalogMatchingEnabled = false
  static var capturedEvent: String?
  static var capturedCurrency: String?
  static var capturedValue: NSNumber?
  static var capturedParameters: [String: Any]?

  static func enable() {
    enableWasCalled = true
  }

  static func recordAndUpdate(
    event: String,
    currency: String?,
    value: NSNumber?,
    parameters: [String: Any]?
  ) {
    capturedEvent = event
    capturedCurrency = currency
    capturedValue = value
    capturedParameters = parameters
  }

  static func setConversionFilteringEnabled(_ enabled: Bool) {
    setConversionFilteringEnabledWasCalled = true
    capturedConversionFilteringEnabled = enabled
  }

  static func setCatalogMatchingEnabled(_ enabled: Bool) {
    setCatalogMatchingEnabledWasCalled = true
    capturedCatalogMatchingEnabled = enabled
  }

  static func reset() {
    enableWasCalled = false
    setConversionFilteringEnabledWasCalled = false
    capturedConversionFilteringEnabled = false
    setCatalogMatchingEnabledWasCalled = false
    capturedCatalogMatchingEnabled = false
    capturedEvent = nil
    capturedCurrency = nil
    capturedValue = nil
    capturedParameters = nil
  }
}
