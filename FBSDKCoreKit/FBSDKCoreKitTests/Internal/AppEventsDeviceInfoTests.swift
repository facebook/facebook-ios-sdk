/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class AppEventsDeviceInfoTests: XCTestCase {
  let appEventsDeviceInfo = AppEventsDeviceInfo()
  let settings = Settings.shared

  func testDefaultDependencies() {
    XCTAssertTrue(
      appEventsDeviceInfo.settings === settings,
      "Should use the expected default settings"
    )
  }
}
