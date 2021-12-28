/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class CrashObserverTests: XCTestCase {

  let graphRequestFactory = TestGraphRequestFactory()
  let settings = TestSettings()
  let featureChecker = TestFeatureManager()
  let crashHandler = TestCrashHandler()

  lazy var crashObserver = CrashObserver(
    featureChecker: featureChecker,
    graphRequestFactory: graphRequestFactory,
    settings: settings,
    crashHandler: crashHandler
  )

  func testCreatingWithDependencies() {
    XCTAssertTrue(
      crashObserver.graphRequestFactory === graphRequestFactory,
      "Should be able to create with a custom graph request factory"
    )
    XCTAssertTrue(
      crashObserver.settings === settings,
      "Should be able to create with custom settings"
    )
    XCTAssertTrue(
      crashObserver.featureChecker === featureChecker,
      "Should be able to create with a custom feature checker"
    )
    XCTAssertTrue(
      crashObserver.crashHandler === crashHandler,
      "Should be able to create with a custom crash handler"
    )
  }

  func testDidReceiveCrashLogs() {
    crashObserver.didReceiveCrashLogs([])
    XCTAssertEqual(featureChecker.capturedFeatures, [])

    let processedCrashLogs = CrashObserverTests.getCrashLogs()

    crashObserver.didReceiveCrashLogs(processedCrashLogs)

    XCTAssertTrue(
      featureChecker.capturedFeatures.contains(SDKFeature.crashShield),
      "Receiving crash logs should check to see if the crash shield feature is enabled"
    )
  }

  static func getCrashLogs() -> [[String: Any]] {
    let callstack = [
      "(4 DEV METHODS)",
      "+[FBSDKCodelessIndexer crash]+84",
      "(22 DEV METHODS)"
    ]

    let crashLogs = [
      [
        "callstack": callstack,
        "reason": "NSInternalInconsistencyException",
        "fb_sdk_version": "5.6.0",
        "timestamp": "1572036095",
        "app_id": "2416630768476176",
        "device_model": "iPad5,3",
        "device_os": "ios",
        "device_os_version": "13.1.3",
      ]
    ]
    return crashLogs
  }
}
