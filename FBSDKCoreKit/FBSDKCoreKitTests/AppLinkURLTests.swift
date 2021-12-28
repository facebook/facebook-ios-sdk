/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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
    XCTAssertNil(
      AppLinkURL.appLinkEventPoster,
      "Should not have an app link event poster"
    )
  }

  func testConfiguringDependencies() {
    let settings = TestSettings()
    let appLinkFactory = TestAppLinkFactory()
    let appLinkTargetFactory = TestAppLinkTargetFactory()
    let appLinkEventPoster = TestMeasurementEvent()

    AppLinkURL.configure(
      settings: settings,
      appLinkFactory: appLinkFactory,
      appLinkTargetFactory: appLinkTargetFactory,
      appLinkEventPoster: appLinkEventPoster
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
    XCTAssertTrue(
      AppLinkURL.appLinkEventPoster === appLinkEventPoster,
      "Should be able to configure dependencies"
    )
  }
}
