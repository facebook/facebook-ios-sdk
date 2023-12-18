/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestRedactedEventsManager: NSObject, _EventsProcessing {

  var enabledWasCalled = false
  var processEventsWasCalled = false

  func enable() {
    enabledWasCalled = true
  }

  func processEvents(_ events: NSMutableArray) {
    processEventsWasCalled = true
  }
}
