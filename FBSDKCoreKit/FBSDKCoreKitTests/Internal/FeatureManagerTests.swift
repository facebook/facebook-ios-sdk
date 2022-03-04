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

final class FeatureManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var manager: FeatureManager!
  var settings: TestSettings!
  var store: UserDefaultsSpy!
  let userDefaultsPrefix = "com.facebook.sdk:FBSDKFeatureManager.FBSDKFeature"
  let gatekeeperKeyPrefix = "FBSDKFeature"
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    TestGateKeeperManager.reset()
    settings = TestSettings()
    store = UserDefaultsSpy()

    manager = FeatureManager()
    manager.configure(
      gateKeeperManager: TestGateKeeperManager.self,
      settings: settings,
      store: store
    )
  }

  override func tearDown() {
    super.tearDown()

    TestGateKeeperManager.reset()
    settings = nil
    store = nil
    manager = nil
  }

  func testCreatingWithDefaults() {
    manager = FeatureManager()

    XCTAssertNil(
      manager.gateKeeperManager,
      "Should not have a gatekeeper manager by default"
    )
    XCTAssertNil(
      manager.settings,
      "Should not have settings by default"
    )
    XCTAssertNil(
      manager.store,
      "Should not have a persistent data store by default"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertTrue(
      manager.gateKeeperManager === TestGateKeeperManager.self,
      "Should create with the provided gatekeeper manager"
    )
    XCTAssertTrue(
      manager.settings === settings,
      "Should create with the provided settings"
    )
    XCTAssertTrue(
      manager.store === store,
      "Should create with the provided persistent data store"
    )
  }

  func testCheckingCoreFeature() {
    var capturedEnabled = false
    manager.check(.core) { enabled in
      capturedEnabled = enabled
    }

    TestGateKeeperManager.capturedLoadGateKeepersCompletion?(nil)

    XCTAssertTrue(
      capturedEnabled,
      "CoreKit shiould always be considered enabled"
    )
    XCTAssertTrue(
      TestGateKeeperManager.loadGateKeepersWasCalled,
      "Checking if core is enabled should load the gatekeepers"
    )
    XCTAssertTrue(
      TestGateKeeperManager.capturedBoolForGateKeeperKeys.isEmpty,
      "Checking if core is enabled should not check for the loaded gatekeepers"
    )
  }

  func testCheckingTopLevelFeatures() {
    let testData: [(feature: SDKFeature, name: String)] = [
      (.appEvents, "AppEvents"),
      (.instrument, "Instrument"),
      (.login, "LoginKit"),
      (.share, "ShareKit"),
      (.gamingServices, "GamingServicesKit"),
    ]
    testData.forEach { data in
      manager.check(data.feature) { _ in }

      TestGateKeeperManager.capturedLoadGateKeepersCompletion?(nil)

      XCTAssertTrue(
        TestGateKeeperManager.loadGateKeepersWasCalled,
        "Checking if \(data.name) is enabled should load the gatekeepers"
      )
      XCTAssertEqual(
        TestGateKeeperManager.capturedBoolForGateKeeperKeys.first,
        gatekeeperKeyPrefix + data.name,
        """
        Checking if top-level feature: \(data.name) is enabled
        should check for the feature name: \(data.name) in the loaded gatekeepers
        """
      )
      TestGateKeeperManager.reset()
    }
  }

  func testCheckingNonTopLevelFeaturesWithParentFeaturesEnabled() {
    let testData: [(feature: SDKFeature, parentFeatureName: String, name: String)] = [
      (.codelessEvents, "AppEvents", "CodelessEvents"),
      (.restrictiveDataFiltering, "AppEvents", "RestrictiveDataFiltering"),
      (.AAM, "AppEvents", "AAM"),
      (.privacyProtection, "AppEvents", "PrivacyProtection"),
      (.suggestedEvents, "AppEvents", "SuggestedEvents"),
      (.intelligentIntegrity, "AppEvents", "IntelligentIntegrity"),
      (.modelRequest, "AppEvents", "ModelRequest"),
      (.eventDeactivation, "AppEvents", "EventDeactivation"),
      (.skAdNetwork, "AppEvents", "SKAdNetwork"),
      (.skAdNetworkConversionValue, "AppEvents", "SKAdNetworkConversionValue"),
      (.ateLogging, "AppEvents", "ATELogging"),
      (.crashReport, "Instrument", "CrashReport"),
      (.crashShield, "Instrument", "CrashShield"),
      (.errorReport, "Instrument", "ErrorReport"),
    ]
    testData.forEach { data in
      manager.check(data.feature) { _ in }

      TestGateKeeperManager.capturedLoadGateKeepersCompletion?(nil)

      XCTAssertTrue(
        TestGateKeeperManager.loadGateKeepersWasCalled,
        "Checking if \(data.name) is enabled should load the gatekeepers"
      )
      let key = gatekeeperKeyPrefix + data.parentFeatureName
      XCTAssertTrue(
        TestGateKeeperManager.capturedBoolForGateKeeperKeys.contains(key),
        """
        Checking if top-level feature: \(data.parentFeatureName) is enabled
        should check for the feature name: \(data.name) in the loaded gatekeepers
        """
      )
      TestGateKeeperManager.reset()
    }
  }

  func testChecksIfFeaturesAreDisabledBeforeCheckingGateKeeper() {
    let testData: [(feature: SDKFeature, name: String)] = [
      (.appEvents, "AppEvents"),
      (.instrument, "Instrument"),
      (.login, "LoginKit"),
      (.share, "ShareKit"),
      (.gamingServices, "GamingServicesKit"),
      (.codelessEvents, "CodelessEvents"),
      (.restrictiveDataFiltering, "RestrictiveDataFiltering"),
      (.AAM, "AAM"),
      (.privacyProtection, "PrivacyProtection"),
      (.suggestedEvents, "SuggestedEvents"),
      (.intelligentIntegrity, "IntelligentIntegrity"),
      (.modelRequest, "ModelRequest"),
      (.eventDeactivation, "EventDeactivation"),
      (.skAdNetwork, "SKAdNetwork"),
      (.skAdNetworkConversionValue, "SKAdNetworkConversionValue"),
      (.ateLogging, "ATELogging"),
      (.crashReport, "CrashReport"),
      (.crashShield, "CrashShield"),
      (.errorReport, "ErrorReport"),
    ]
    testData.forEach { data in
      var capturedKey: String?
      store.stringForKeyCallback = { key in
        capturedKey = key
        // The existence of the sdk version for a feature key in user defaults
        // is interpreted to mean that the feature is disabled for that version
        return self.settings.sdkVersion
      }
      manager.check(data.feature) { _ in }

      TestGateKeeperManager.capturedLoadGateKeepersCompletion?(nil)

      XCTAssertEqual(
        capturedKey,
        userDefaultsPrefix + data.name,
        "Should check if the feature has been disabled as indicated by its existence in user defaults"
      )
      XCTAssertFalse(
        TestGateKeeperManager.loadGateKeepersWasCalled,
        "Should not check the gatekeeper for \(data.name) if the feature is disabled"
      )
      TestGateKeeperManager.reset()
    }
  }

  func testDisablingFeatures() {
    let testData: [SDKFeature] = [
      .none,
      .AAM,
      .codelessEvents,
      .restrictiveDataFiltering,
      .errorReport,
      .privacyProtection,
      .suggestedEvents,
      .intelligentIntegrity,
      .eventDeactivation,
      .skAdNetworkConversionValue,
    ]

    testData.forEach { featureName in
      manager.disableFeature(featureName)
      let featureString = FeatureManager.featureName(featureName)
      XCTAssertEqual(
        store.capturedSetObjectKey,
        userDefaultsPrefix + featureString
      )
    }
  }
}
