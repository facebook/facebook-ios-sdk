/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class ImpressionLoggingButtonTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var impressionLoggerFactory: TestImpressionLoggerFactory!

  override func setUp() {
    super.setUp()

    impressionLoggerFactory = TestImpressionLoggerFactory()

    ImpressionLoggingButton.resetClassDependencies()
  }

  override func tearDown() {
    ImpressionLoggingButton.resetClassDependencies()

    impressionLoggerFactory = nil

    super.tearDown()
  }

  func testDefaultClassDependencies() {
    XCTAssertNil(
      ImpressionLoggingButton.impressionLoggerFactory,
      "Should not have an impression logger factory by default"
    )
  }

  func testConfiguringClassDependencies() {
    ImpressionLoggingButton.configure(impressionLoggerFactory: impressionLoggerFactory)

    XCTAssertTrue(
      ImpressionLoggingButton.impressionLoggerFactory === impressionLoggerFactory,
      "Should be able to configure with an impression logger factory"
    )
  }

  func testLayoutSubviews() {
    ImpressionLoggingButton.configure(impressionLoggerFactory: impressionLoggerFactory)

    let button = TestImpressionButton(frame: .zero)

    button.layoutSubviews()

    XCTAssertEqual(
      impressionLoggerFactory.capturedEventName,
      button.impressionTrackingEventName,
      "Should make an event logger with the expected event name"
    )
    XCTAssertEqual(
      impressionLoggerFactory.impressionLogger.capturedIdentifier,
      button.impressionTrackingIdentifier,
      "Should log an event with the expected identifier"
    )
    XCTAssertEqual(
      impressionLoggerFactory.impressionLogger.capturedParameters as? [String: String],
      button.analyticsParameters as? [String: String],
      "Should log an event with the expected parameters"
    )
  }
}
