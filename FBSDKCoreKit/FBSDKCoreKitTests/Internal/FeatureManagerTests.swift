// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import TestTools
import XCTest

class FeatureManagerTests: XCTestCase {

  var manager: FeatureManager! // swiftlint:disable:this implicitly_unwrapped_optional
  var store: UserDefaultsSpy! // swiftlint:disable:this implicitly_unwrapped_optional
  let userDefaultsPrefix = "com.facebook.sdk:FBSDKFeatureManager.FBSDKFeature"
  let gatekeeperKeyPrefix = "FBSDKFeature"

  override class func setUp() {
    super.setUp()

    TestGateKeeperManager.reset()
  }

  override func setUp() {
    super.setUp()

    store = UserDefaultsSpy()
    manager = FeatureManager(
      gateKeeperManager: TestGateKeeperManager.self,
      store: store
    )
  }

  override func tearDown() {
    super.tearDown()

    TestGateKeeperManager.reset()
  }

  func testCreatingWithDefaults() {
    XCTAssertTrue(
      FeatureManager.shared.gateKeeperManager is GateKeeperManager.Type,
      "Should create the shared feature manager with the correct default gatekeeper manager"
    )
    XCTAssertEqual(
      FeatureManager.shared.store as? UserDefaults,
      UserDefaults.standard,
      "Should use the shared instance of user defaults as a persistent data store"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertTrue(
      manager.gateKeeperManager is TestGateKeeperManager.Type,
      "Should create with the provided gatekeeper manager"
    )
    XCTAssertEqual(
      manager.store as? UserDefaultsSpy,
      store,
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
      (.gamingServices, "GamingServicesKit")
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
      (.errorReport, "Instrument", "ErrorReport")
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
      (.errorReport, "ErrorReport")
    ]
    testData.forEach { data in
      var capturedKey: String?
      store.stringForKeyCallback = { key in
        capturedKey = key
        // The existence of the sdk version for a feature key in user defaults
        // is interpreted to mean that the feature is disabled for that version
        return Settings.sdkVersion
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
      .skAdNetworkConversionValue
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
