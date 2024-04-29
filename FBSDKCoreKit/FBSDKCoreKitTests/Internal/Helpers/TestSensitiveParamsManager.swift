/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestSensitiveParamsManager: _AppEventsParameterProcessing {

  var enabledWasCalled = false
  var processParametersWasCalled = false
  var capturedParameters: [AppEvents.ParameterName: Any]?
  var capturedEventName: AppEvents.Name?

  func enable() {
    enabledWasCalled = true
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name?
  ) -> [AppEvents.ParameterName: Any]? {
    processParametersWasCalled = true
    capturedParameters = parameters
    capturedEventName = eventName
    return parameters
  }
}
