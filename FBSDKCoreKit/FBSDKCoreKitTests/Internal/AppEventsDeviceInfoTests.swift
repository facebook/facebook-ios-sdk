/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class AppEventsDeviceInfoTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var deviceInfo: AppEventsDeviceInfo!
  var settings: TestSettings!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    deviceInfo = AppEventsDeviceInfo()
    deviceInfo.configure(with: settings)
  }

  override func tearDown() {
    settings = nil
    deviceInfo = nil

    super.tearDown()
  }

  func testDefaultDependencies() {
    deviceInfo = AppEventsDeviceInfo()
    XCTAssertNil(
      deviceInfo.settings,
      "Should not have settings by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      deviceInfo.settings === settings,
      "Should use the provided settings"
    )
  }
}
