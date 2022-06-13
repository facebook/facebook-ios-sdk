/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class DevicePollerTests: XCTestCase {
  func testScheduleBlock() {
    let poller = _DevicePoller()
    let expectation = self.expectation(description: name)

    func block() {
      expectation.fulfill()
    }

    poller.schedule(interval: 1, block: block)

    waitForExpectations(timeout: 2, handler: nil)
  }
}
