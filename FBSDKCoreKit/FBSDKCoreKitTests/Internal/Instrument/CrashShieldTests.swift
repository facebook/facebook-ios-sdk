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

final class CrashShieldTests: XCTestCase {
  let settings = TestSettings()
  let graphRequestFactory = TestGraphRequestFactory()
  let featureManager = TestFeatureManager()

  override func setUp() {
    super.setUp()

    settings.reset()
    CrashShield.reset()
    CrashShield.configure(
      with: settings,
      graphRequestFactory: graphRequestFactory,
      featureChecking: featureManager
    )
  }

  // MARK: - Get Feature

  func testGetFeatureForAAM() {
    let callstack1 = [
      "(4 DEV METHODS)",
      "+[FBSDKMetadataIndexer crash]+84",
      "(22 DEV METHODS)",
    ]

    let featureName1 = CrashShield._getFeature(callstack1)
    XCTAssertEqual(featureName1, "AAM")
  }

  func testGetFeatureForCodelessEvents() {
    let callstack2 = [
      "(4 DEV METHODS)",
      "+[FBSDKCodelessIndexer crash]+84",
      "(22 DEV METHODS)",
    ]

    let featureName2 = CrashShield._getFeature(callstack2)
    XCTAssertEqual(featureName2, "CodelessEvents")
  }

  func testGetFeatureForRestrictiveDataFiltering() {
    let callstack3 = [
      "(4 DEV METHODS)",
      "+[FBSDKRestrictiveDataFilterManager crash]+84",
      "(22 DEV METHODS)",
    ]

    let featureName3 = CrashShield._getFeature(callstack3)
    XCTAssertEqual(featureName3, "RestrictiveDataFiltering")
  }

  func testGetFeatureForErrorReport() {
    let callstack4 = [
      "(4 DEV METHODS)",
      "+[FBSDKErrorReport crash]+84",
      "(22 DEV METHODS)",
    ]

    let featureName4 = CrashShield._getFeature(callstack4)
    XCTAssertEqual(featureName4, "ErrorReport")
  }

  func testGetFeatureForNil() {
    // feature in other kit
    let callstack5 = [
      "(4 DEV METHODS)",
      "+[FBSDKVideoUploader crash]+84",
      "(22 DEV METHODS)",
    ]

    let featureName5 = CrashShield._getFeature(callstack5)
    XCTAssertNil(featureName5)
  }

  func testParsingFeatureFromValidCallstack() {
    let callstack = [
      "(4 DEV METHODS)",
      "+[FBSDKVideoUploader crash]+84",
      "(22 DEV METHODS)",
    ]

    for _ in 0 ..< 100 {
      _ = CrashShield._getFeature(Fuzzer.randomize(json: callstack))
    }
  }

  // MARK: - Get Class Name

  func testGetClassNameForClassMethod() {
    let entry1 = "+[FBSDKRestrictiveDataFilterManager crash]+84"
    let className1 = CrashShield._getClassName(entry1)
    XCTAssertTrue(className1 == "FBSDKRestrictiveDataFilterManager")
  }

  func testGetClassNameForInstanceMethod() {
    let entry2 = "-[FBSDKRestrictiveDataFilterManager crash]+84"
    let className2 = CrashShield._getClassName(entry2)
    XCTAssertTrue(className2 == "FBSDKRestrictiveDataFilterManager")
  }

  func testGetClassNameForIneligibleFormat() {
    let entry3 = "(6 DEV METHODS)"
    let className3 = CrashShield._getClassName(entry3)
    XCTAssertNil(className3)
  }

  func testParsingClassName() {
    for _ in 0 ..< 100 {
      CrashShield._getClassName(Fuzzer.random)
    }
  }

  func testAnalyzingEmptyCrashLogs() {
    // Should not create a graph request for posting a non-existent crash
    CrashShield.analyze([])
    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create a graph request for posting a non-existent crash"
    )
  }

  // MARK: - Analyze: Disabling Features

  func testDisablingCoreKitFeatureWithDataProcessingRestricted() {
    settings.isDataProcessingRestricted = true
    CrashShield.analyze(coreKitCrashLogs)

    XCTAssertTrue(
      featureManager.disabledFeaturesContains(.codelessEvents),
      "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
    )
  }

  func testDisablingNonCoreKitFeatureWithDataProcessingRestricted() {
    settings.isDataProcessingRestricted = true
    CrashShield.analyze(nonCoreKitCrashLogs)

    XCTAssertFalse(
      featureManager.disabledFeaturesContains(.codelessEvents),
      "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
    )
  }

  func testDisablingCoreKitFeatureWithDataProcessingUnrestricted() {
    settings.isDataProcessingRestricted = false

    CrashShield.analyze(coreKitCrashLogs)

    XCTAssertTrue(
      featureManager.disabledFeaturesContains(.codelessEvents),
      "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
    )
  }

  func testDisablingNonCoreKitFeatureWithDataProcessingUnrestricted() {
    settings.isDataProcessingRestricted = false
    CrashShield.analyze(nonCoreKitCrashLogs)

    XCTAssertFalse(
      featureManager.disabledFeaturesContains(.codelessEvents),
      "Should not disable a non core feature found in a crashlog regardless of data processing permissions"
    )
  }

  func testFeatureForStringWithFeatureNone() {
    let pairs = [
      "": SDKFeature.none,
      "CoreKit": SDKFeature.core,
      "AppEvents": SDKFeature.appEvents,
      "CodelessEvents": SDKFeature.codelessEvents,
      "RestrictiveDataFiltering": SDKFeature.restrictiveDataFiltering,
      "AAM": SDKFeature.AAM,
      "PrivacyProtection": SDKFeature.privacyProtection,
      "SuggestedEvents": SDKFeature.suggestedEvents,
      "IntelligentIntegrity": SDKFeature.intelligentIntegrity,
      "ModelRequest": SDKFeature.modelRequest,
      "EventDeactivation": SDKFeature.eventDeactivation,
      "SKAdNetwork": SDKFeature.skAdNetwork,
      "SKAdNetworkConversionValue": SDKFeature.skAdNetworkConversionValue,
      "Instrument": SDKFeature.instrument,
      "CrashReport": SDKFeature.crashReport,
      "CrashShield": SDKFeature.crashShield,
      "ErrorReport": SDKFeature.errorReport,
      "ATELogging": SDKFeature.ateLogging,
      "AEM": SDKFeature.AEM,
      "LoginKit": SDKFeature.login,
      "ShareKit": SDKFeature.share,
      "GamingServicesKit": SDKFeature.gamingServices,
    ]

    for (key, value) in pairs {
      XCTAssertEqual(CrashShield.feature(for: key), value)
    }
  }

  // MARK: - Analyze: Posting Crash Logs

  func testPostingCoreKitCrashLogsWithDataProcessingRestricted() {
    settings.isDataProcessingRestricted = true
    CrashShield.analyze(coreKitCrashLogs)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  func testPostingNonCoreKitCrashLogsWithDataProcessingRestricted() {
    settings.isDataProcessingRestricted = true

    CrashShield.analyze(nonCoreKitCrashLogs)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  func testPostingCoreKitCrashLogsWithDataProcessingUnrestricted() {
    // Setup
    settings.isDataProcessingRestricted = false
    settings.appID = "appID"

    // Act
    CrashShield.analyze(coreKitCrashLogs)
    XCTAssertNotNil(graphRequestFactory.capturedGraphPath)
  }

  func testPostingNonCoreKitCrashLogsWithDataProcessingUnrestricted() {
    settings.isDataProcessingRestricted = false
    settings.appID = "appID"
    CrashShield.analyze(nonCoreKitCrashLogs)
    XCTAssertNil(graphRequestFactory.capturedGraphPath)
  }

  // MARK: - Helpers

  private var coreKitCrashLogs: [[String: Any]] {
    CrashShieldTests.getCrashLogs(true)
  }

  private var nonCoreKitCrashLogs: [[String: Any]] {
    CrashShieldTests.getCrashLogs(false)
  }

  private class func getCrashLogs(_ isCoreKitFeature: Bool) -> [[String: Any]] {
    let className = isCoreKitFeature ? "FBSDKCodelessIndexer" : "FBSDKTooltipView"
    let callStack = [
      "(4 DEV METHODS)",
      "+[\(className) crash]+84",
      "(22 DEV METHODS)",
    ]

    let crashLogs = [
      [
        "callstack": callStack,
        "reason": "NSInternalInconsistencyException",
        "fb_sdk_version": "5.6.0",
        "timestamp": "1572036095",
        "app_id": "2416630768476176",
        "device_model": "iPad5,3",
        "device_os": "ios",
        "device_os_version": "13.1.3",
      ],
    ]
    return crashLogs
  }
}
