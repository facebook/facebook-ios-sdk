/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAppEventsReporter: NSObject, AppEventsReporter {
  var enableWasCalled = false
  var capturedEvent: String?
  var capturedCurrency: String?
  var capturedValue: NSNumber?
  var capturedParameters: [String: Any]?

  func enable() {
    enableWasCalled = true
  }

  func recordAndUpdate(event: String, currency: String?, value: NSNumber?, parameters: [String: Any]?) {
    capturedEvent = event
    capturedCurrency = currency
    capturedValue = value
    capturedParameters = parameters
  }
}
