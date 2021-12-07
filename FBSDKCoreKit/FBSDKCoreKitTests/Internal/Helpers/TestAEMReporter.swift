/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
  static var setCatalogReportEnabledWasCalled = false
  static var capturedSetCatalogReportEnabled = false
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

  static func setCatalogReportEnabled(_ enabled: Bool) {
    setCatalogReportEnabledWasCalled = true
    capturedSetCatalogReportEnabled = enabled
  }

  static func reset() {
    enableWasCalled = false
    setCatalogReportEnabledWasCalled = false
    capturedSetCatalogReportEnabled = false
    capturedEvent = nil
    capturedCurrency = nil
    capturedValue = nil
    capturedParameters = nil
  }
}
