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

@available(iOS 14, *)
final class AEMManagerTests: XCTestCase {

  let swizzler = TestSwizzler.self
  let aemReporter = TestAEMReporter.self
  let eventLogger = TestEventLogger()
  let crashHandler = TestCrashHandler()
  let featureChecker = TestFeatureManager()
  let appEventsUtility = TestAppEventsUtility()

  override func setUp() {
    super.setUp()

    _AEMManager.shared.configure(
      swizzler: swizzler,
      reporter: aemReporter,
      eventLogger: eventLogger,
      crashHandler: crashHandler,
      featureChecker: featureChecker,
      appEventsUtility: appEventsUtility
    )
  }

  func testConfigure() {
    XCTAssertIdentical(
      swizzler as AnyObject,
      _AEMManager.shared.swizzler,
      "Should configure with the expected swizzler"
    )
    XCTAssertIdentical(
      aemReporter as AnyObject,
      _AEMManager.shared.aemReporter,
      "Should configure with the expected AEM reporter"
    )
    XCTAssertIdentical(
      eventLogger as AnyObject,
      _AEMManager.shared.eventLogger,
      "Should configure with the expected event logger"
    )
    XCTAssertIdentical(
      crashHandler as AnyObject,
      _AEMManager.shared.crashHandler,
      "Should configure with the expected crash handler"
    )
    XCTAssertIdentical(
      featureChecker as AnyObject,
      _AEMManager.shared.featureChecker,
      "Should configure with the expected feature checker"
    )
    XCTAssertIdentical(
      appEventsUtility as AnyObject,
      _AEMManager.shared.appEventsUtility,
      "Should configure with the expected app events utility"
    )
  }

  func testLogAutoSetupStatus() {
    _AEMManager.shared.logAutoSetupStatus(true, source: "test_source1")
    XCTAssertEqual(
      eventLogger.capturedEventName?.rawValue,
      "fb_mobile_aem_auto_setup_opt_in",
      "Should log the correct opt in event name"
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [AppEvents.ParameterName: String],
      [.init("source"): "test_source1"],
      "Should log the correct opt in event parameter"
    )

    _AEMManager.shared.logAutoSetupStatus(false, source: "test_source2")
    XCTAssertEqual(
      eventLogger.capturedEventName?.rawValue,
      "fb_mobile_aem_auto_setup_opt_out",
      "Should log the correct opt out event name"
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [AppEvents.ParameterName: String],
      [.init("source"): "test_source2"],
      "Should log the correct opt out event parameter"
    )
  }
}
