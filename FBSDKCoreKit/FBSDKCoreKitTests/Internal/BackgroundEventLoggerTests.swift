/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class BackgroundEventLoggerTests: XCTestCase {

  let bundleWithIdentifier = TestBundle(infoDictionary: ["BGTaskSchedulerPermittedIdentifiers": ["123"]])
  let bundleWithoutIdentifier = TestBundle()
  let logger = TestEventLogger()
  lazy var backgroundEventLogger = BackgroundEventLogger(
    infoDictionaryProvider: bundleWithIdentifier,
    eventLogger: logger
  )

  func testCreating() {
    XCTAssertTrue(
      backgroundEventLogger.infoDictionaryProvider is TestBundle,
      "Should use the provided info dictionary provider type"
    )
    XCTAssertTrue(
      backgroundEventLogger.eventLogger is TestEventLogger,
      "Should use the provided event logger type"
    )
  }

  func testLogBackgroundStatusWithBackgroundRefreshStatusAvailable() {
    backgroundEventLogger.logBackgroundRefreshStatus(.available)

    XCTAssertEqual(
      logger.capturedEventName,
      .backgroundStatusAvailable,
      "AppEvents instance should log fb_sdk_background_status_available if background refresh status is available"
    )
  }

  func testLogBackgroundStatusWithBackgroundRefreshStatusDenied() {
    backgroundEventLogger.logBackgroundRefreshStatus(.denied)

    XCTAssertEqual(
      logger.capturedEventName,
      .backgroundStatusDenied,
      "AppEvents instance should log fb_sdk_background_status_denied if background refresh status is available"
    )
  }

  func testLogBackgroundStatusWithBackgroundRefreshStatusRestricted() {
    backgroundEventLogger.logBackgroundRefreshStatus(.restricted)

    XCTAssertEqual(
      logger.capturedEventName,
      .backgroundStatusRestricted,
      "AppEvents instance should log fb_sdk_background_status_restricted if background refresh status is available"
    )
  }

  func testIsNewBackgroundRefreshWithIdentifiers() {
    XCTAssertTrue(
      backgroundEventLogger._isNewBackgroundRefresh(),
      "Should expect background refresh API is the new one if the identifier exists"
    )
  }

  func testIsNewBackgroundRefreshWithoutIdentifiers() {
    backgroundEventLogger = BackgroundEventLogger(
      infoDictionaryProvider: bundleWithoutIdentifier,
      eventLogger: logger
    )

    XCTAssertFalse(
      backgroundEventLogger._isNewBackgroundRefresh(),
      "Should expect background refresh API is the new one if the identifier exists"
    )
  }
}
