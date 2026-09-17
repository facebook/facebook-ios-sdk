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
  var manager: _FeatureManager!
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

    manager = _FeatureManager()
    _FeatureManager.setDependencies(
      .init(
        gateKeeperManager: TestGateKeeperManager.self,
        settings: settings,
        store: store
      )
    )
  }

  override func tearDown() {
    super.tearDown()

    _FeatureManager.resetDependencies()
    TestGateKeeperManager.reset()
    settings = nil
    store = nil
    manager = nil
  }

  func testDefaultTypeDependencies() throws {
    _FeatureManager.resetDependencies()
    let dependencies = try _FeatureManager.getDependencies()

    XCTAssertIdentical(
      dependencies.gateKeeperManager as AnyObject,
      _GateKeeperManager.self,
      .defaultDependency("the gatekeeper manager", for: "gatekeeper managing")
    )

    XCTAssertIdentical(
      dependencies.settings as AnyObject,
      Settings.shared,
      .defaultDependency("the shared settings", for: "settings sharing")
    )

    XCTAssertIdentical(
      dependencies.store as AnyObject,
      UserDefaults.standard,
      .defaultDependency("the shared user defaults", for: "data persisting")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try _FeatureManager.getDependencies()

    XCTAssertIdentical(
      dependencies.gateKeeperManager as AnyObject,
      TestGateKeeperManager.self,
      .customDependency(for: "gatekeeper managing")
    )

    XCTAssertIdentical(
      dependencies.settings as AnyObject,
      settings,
      .customDependency(for: "settings sharing")
    )

    XCTAssertIdentical(
      dependencies.store as AnyObject,
      store,
      .customDependency(for: "data persisting")
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
      let featureString = _FeatureManager.shared.featureName(for: featureName)
      XCTAssertEqual(
        store.capturedSetObjectKey,
        userDefaultsPrefix + featureString
      )
    }
  }

  func testResolvesAgainstARealGateKeeperPayload() {
    // The other tests here use a gate keeper double, which answers whatever key it is asked
    // for and so cannot notice a wrong key. This drives the real `_GateKeeperManager` with the
    // payload shape `{app-id}/mobile_sdk_gk` actually returns, so the whole chain runs:
    // featureName(for:) -> "FBSDKFeature" + name -> a lookup that only succeeds if the name
    // matches what the server publishes. Before this fix both features resolved the key
    // "FBSDKFeatureNONE", which is absent from any payload, and fell back to false.
    _GateKeeperManager.reset()
    _GateKeeperManager.parse(
      result: [
        "data": [
          [
            "gatekeepers": [
              // FBSDKFeatureAppEvents is deliberately absent: the real payload does not
              // include it, and the grandparent resolves through defaultStatus(for:) instead.
              ["key": "FBSDKFeaturePrivacyProtection", "value": true],
              ["key": "FBSDKFeatureStdParamEnforcement", "value": true],
              ["key": "FBSDKFeatureBannedParamFiltering", "value": true],
            ],
          ],
        ],
      ],
      error: nil
    )

    _FeatureManager.setDependencies(
      .init(
        gateKeeperManager: _GateKeeperManager.self,
        settings: settings,
        store: store
      )
    )

    XCTAssertTrue(
      manager.isEnabled(.stdParamEnforcement),
      "Should resolve FBSDKFeatureStdParamEnforcement from the payload, not a key that is absent from it"
    )
    XCTAssertTrue(
      manager.isEnabled(.bannedParamFiltering),
      "Should resolve FBSDKFeatureBannedParamFiltering from the payload, not a key that is absent from it"
    )

    _GateKeeperManager.reset()
  }

  func testFeatureNamesMatchTheirGateKeepers() {
    // The gate keeper key is "FBSDKFeature" + featureName(for:), so a feature that is
    // missing from that switch falls through to "NONE" and reads a gate keeper that does
    // not exist -- returning the default rather than the server's value, silently. These
    // two did exactly that, and were off on iOS while enabled server side.
    let expected: [(SDKFeature, String)] = [
      (.stdParamEnforcement, "StdParamEnforcement"),
      (.bannedParamFiltering, "BannedParamFiltering"),
    ]

    for (feature, name) in expected {
      XCTAssertEqual(
        _FeatureManager.shared.featureName(for: feature),
        name,
        "\(name) must resolve to its own gate keeper, not fall through to NONE"
      )
    }
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The _FeatureManager type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The _FeatureManager type uses a custom \(type) dependency when provided"
  }
}
