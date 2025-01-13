/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestIAPDedupeProcessor: _IAPDedupeProcessing {
  private(set) var isEnabled = false
  var enableWasCalled = false
  var disableWasCalled = false
  var processManualEventWasCalled = false
  var processImplicitEventWasCalled = false
  var saveNonProcessedEventsWasCalled = false
  var processSavedEventsWasCalled = false

  func enable() {
    enableWasCalled = true
  }

  func disable() {
    disableWasCalled = true
  }

  func saveNonProcessedEvents() {
    saveNonProcessedEventsWasCalled = true
  }

  func processSavedEvents() {
    processSavedEventsWasCalled = true
  }

  func shouldDedupeEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?
  ) -> Bool {
    true
  }

  func processManualEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?,
    accessToken: AccessToken?,
    operationalParameters: [AppOperationalDataType: [String: Any]]?
  ) {
    processManualEventWasCalled = true
  }

  func processImplicitEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?,
    accessToken: AccessToken?,
    operationalParameters: [AppOperationalDataType: [String: Any]]?
  ) {
    processImplicitEventWasCalled = true
  }
}
