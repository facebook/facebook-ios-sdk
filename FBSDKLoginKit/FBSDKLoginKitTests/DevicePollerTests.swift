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
    let poller = DevicePoller()
    let expectation = self.expectation(description: name)

    func block() {
      expectation.fulfill()
    }

    poller.scheduleBlock(block, interval: 1)

    waitForExpectations(timeout: 2, handler: nil)
  }
}
