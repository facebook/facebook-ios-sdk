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

  // swiftlint:disable implicitly_unwrapped_optional
  var bundleWithIdentifier: TestBundle!
  var bundleWithoutIdentifier: TestBundle!
  var logger: TestEventLogger!
  var backgroundEventLogger: BackgroundEventLogger!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    bundleWithIdentifier = TestBundle(infoDictionary: ["BGTaskSchedulerPermittedIdentifiers": ["123"]])
    bundleWithoutIdentifier = TestBundle()
    logger = TestEventLogger()

    BackgroundEventLogger.setDependencies(
      .init(
        infoDictionaryProvider: bundleWithIdentifier,
        eventLogger: logger
      )
    )
    backgroundEventLogger = BackgroundEventLogger()
  }

  override func tearDown() {
    bundleWithIdentifier = nil
    bundleWithoutIdentifier = nil
    logger = nil
    backgroundEventLogger = nil
    BackgroundEventLogger.resetDependencies()
    super.tearDown()
  }

  func testDefaultTypeDependencies() throws {
    BackgroundEventLogger.resetDependencies()
    let dependencies = try BackgroundEventLogger.getDependencies()

    XCTAssertIdentical(
      dependencies.infoDictionaryProvider as AnyObject,
      Bundle.main,
      .defaultDependency("the main bundle", for: "providing dictionaries")
    )

    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      AppEvents.shared,
      .defaultDependency("the shared AppEvents", for: "event logging")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try BackgroundEventLogger.getDependencies()

    XCTAssertIdentical(
      dependencies.infoDictionaryProvider as AnyObject,
      bundleWithIdentifier,
      .customDependency(for: "providing dictionaries")
    )

    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      logger,
      .customDependency(for: "event logging")
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
      backgroundEventLogger.isNewBackgroundRefresh,
      "Should expect background refresh API is the new one if the identifier exists"
    )
  }

  func testIsNewBackgroundRefreshWithoutIdentifiers() {
    BackgroundEventLogger.resetDependencies()
    BackgroundEventLogger.setDependencies(
      .init(
        infoDictionaryProvider: bundleWithoutIdentifier,
        eventLogger: logger
      )
    )
    backgroundEventLogger = BackgroundEventLogger()

    XCTAssertFalse(
      backgroundEventLogger.isNewBackgroundRefresh,
      "Should expect background refresh API is the new one if the identifier exists"
    )
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The BackgroundEventLogger type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The BackgroundEventLogger type uses a custom \(type) dependency when provided"
  }
}
