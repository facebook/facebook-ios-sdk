/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
class TestAppEventsParameterProcessor: NSObject, AppEventsParameterProcessing, EventsProcessing {
  var enableWasCalled = false
  var capturedParameters: [String: Any]?
  var capturedEventName: String?
  var capturedEvents: [[String: Any]]?

  func enable() {
    enableWasCalled = true
  }

  func processParameters(_ parameters: [String: Any]?, eventName: String) -> [String: Any]? {
    capturedParameters = parameters
    capturedEventName = eventName
    return parameters
  }

  func processEvents(_ events: NSMutableArray) {
    self.capturedEvents = events.copy() as? [[String: Any]]
  }
}
