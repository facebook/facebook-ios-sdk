/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class AppLinkURLTests: XCTestCase {

  override class func setUp() {
    super.setUp()

    AppLinkURL.reset()
  }

  override func tearDown() {
    AppLinkURL.reset()

    super.tearDown()
  }

  func testDefaultDependencies() {
    XCTAssertNil(
      AppLinkURL.settings,
      "Should not have settings by default"
    )
    XCTAssertNil(
      AppLinkURL.appLinkFactory,
      "Should not have an app link factory by default"
    )
    XCTAssertNil(
      AppLinkURL.appLinkTargetFactory,
      "Should not have an app link target factory by default"
    )
  }

  func testConfiguringDependencies() {
    let settings = TestSettings()
    let appLinkFactory = TestAppLinkFactory()
    let appLinkTargetFactory = TestAppLinkTargetFactory()

    AppLinkURL.configure(
      settings: settings,
      appLinkFactory: appLinkFactory,
      appLinkTargetFactory: appLinkTargetFactory
    )

    XCTAssertTrue(
      AppLinkURL.settings === settings,
      "Should be able to configure dependencies"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkFactory === appLinkFactory,
      "Should be able to configure dependencies"
    )
    XCTAssertTrue(
      AppLinkURL.appLinkTargetFactory === appLinkTargetFactory,
      "Should be able to configure dependencies"
    )
  }
}
