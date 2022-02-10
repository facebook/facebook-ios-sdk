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
final class TestAppEventsParameterProcessor: NSObject, AppEventsParameterProcessing, EventsProcessing {
  var enableWasCalled = false
  var capturedParameters: [AppEvents.ParameterName: Any]?
  var capturedEventName: AppEvents.Name?
  var capturedEvents: [[String: Any]]?

  func enable() {
    enableWasCalled = true
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name
  ) -> [AppEvents.ParameterName: Any]? {
    capturedParameters = parameters
    capturedEventName = eventName
    return parameters
  }

  func processEvents(_ events: NSMutableArray) {
    capturedEvents = events.copy() as? [[String: Any]]
  }
}
