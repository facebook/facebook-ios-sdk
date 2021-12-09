/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class AppEventsDeviceInfoTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var settings: TestSettings!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AppEventsDeviceInfo.reset()

    settings = TestSettings()
    AppEventsDeviceInfo.shared.configure(with: settings)
  }

  override func tearDown() {
    AppEventsDeviceInfo.reset()

    settings = nil

    super.tearDown()
  }

  func testDefaultDependencies() {
    AppEventsDeviceInfo.reset()
    XCTAssertNil(
      AppEventsDeviceInfo.shared.settings,
      "Should not have settings by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      AppEventsDeviceInfo.shared.settings === settings,
      "Should use the provided settings"
    )
  }
}
