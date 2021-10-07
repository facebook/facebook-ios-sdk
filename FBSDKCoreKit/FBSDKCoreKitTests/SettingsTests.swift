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

class SettingsTests: XCTestCase {

  var store = UserDefaultsSpy()
  let bundle = TestBundle()
  let logger = TestEventLogger()

  override func setUp() {
    super.setUp()

    Settings.configure(
      store: store,
      appEventsConfigurationProvider: TestAppEventsConfigurationProvider.self,
      infoDictionaryProvider: bundle,
      eventLogger: logger
    )
  }

  override func tearDown() {
    super.tearDown()

    Settings.reset()
    TestAppEventsConfigurationProvider.reset()
    TestAppEventsConfiguration.reset()
  }

  func testDefaultStore() {
    Settings.reset()
    XCTAssertNil(
      Settings.store,
      "Settings should not have a default data store"
    )
  }

  func testConfiguringWithStore() {
    XCTAssertTrue(
      Settings.store === store,
      "Should be able to set a persistent data store"
    )
  }

  func testDefaultAppEventsConfigurationProvider() {
    Settings.reset()
    XCTAssertNil(
      Settings.appEventsConfigurationProvider,
      "Settings should not have a default app events configuration provider"
    )
  }

  func testConfiguringWithAppEventsConfigurationProvider() {
    XCTAssertTrue(
      Settings.appEventsConfigurationProvider === TestAppEventsConfigurationProvider.self,
      "Should be able to set an app events configuration provider"
    )
  }

  func testDefaultInfoDictionaryProvider() {
    Settings.reset()
    XCTAssertNil(
      Settings.infoDictionaryProvider,
      "Settings should not have a default info dictionary provider"
    )
  }

  func testConfiguringWithInfoDictionaryProvider() {
    XCTAssertTrue(
      Settings.infoDictionaryProvider === bundle,
      "Should be able to set an info dictionary provider"
    )
  }

  func testDefaultEventLogger() {
    Settings.reset()
    XCTAssertNil(
      Settings.eventLogger,
      "Settings should not have a default event logger"
    )
  }

  func testConfiguringWithEventLogger() {
    XCTAssertTrue(
      Settings.eventLogger === logger,
      "Should be able to set an event logger"
    )
  }

  // MARK: Advertiser Tracking Status

  func testFacebookAdvertiserTrackingStatusDefaultValue() {
    let configuration = TestAppEventsConfiguration(defaultAteStatus: .disallowed)
    TestAppEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertEqual(
      Settings.advertisingTrackingStatus(),
      configuration.defaultATEStatus,
      """
      Advertiser tracking status should use the cached app events configuration
      when there is no persisted overridden value
      """
    )
    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus",
      """
      Should attempt to retrieve the tracking status from the data store before
      checking the cached configuration
      """
    )
    XCTAssertTrue(
      TestAppEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testGettingExplicitlySetFacebookAdvertiserTrackingStatus() {
    Settings.setAdvertiserTrackingStatus(.disallowed)
    XCTAssertEqual(
      Settings.advertisingTrackingStatus(),
      .disallowed,
      "Should return the explicitly set tracking status"
    )
    XCTAssertNil(
      store.capturedObjectRetrievalKey,
      "Should not attempt to retrieve the tracking status from the data store"
    )
    XCTAssertFalse(
      TestAppEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should not attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testGettingPersistedFacebookAdvertiserTrackingStatus() {
    let key = "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus"
    store.set(
      NSNumber(value: AdvertisingTrackingStatus.allowed.rawValue),
      forKey: key
    )
    XCTAssertEqual(
      Settings.advertisingTrackingStatus(),
      .allowed,
      "Should return the tracking status from the data store"
    )
    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      key,
      "Should retrieve the tracking status from the data store"
    )
    XCTAssertFalse(
      TestAppEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should not attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testGettingCachedFacebookAdvertiserTrackingStatus() {
    let key = "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus"
    store.set(
      NSNumber(value: AdvertisingTrackingStatus.allowed.rawValue),
      forKey: key
    )
    XCTAssertEqual(
      Settings.advertisingTrackingStatus(),
      .allowed,
      "Should return the tracking status from the data store"
    )
    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      key,
      "Should retrieve the tracking status from the data store"
    )
    XCTAssertFalse(
      TestAppEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should not attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToEnabled() {
    Settings.shared.isAdvertiserTrackingEnabled = true
    XCTAssertEqual(
      store.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to enabled"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToDisallowed() {
    Settings.shared.isAdvertiserTrackingEnabled = false
    XCTAssertEqual(
      store.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to disallowed"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToEnabledProperty() {
    Settings.shared.isAdvertiserTrackingEnabled = true

    XCTAssertTrue(
      Settings.shared.isAdvertiserTrackingEnabled,
      "Setting advertiser tracking status should be allowed"
    )
    XCTAssertEqual(
      store.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to enabled"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToDisallowedProperty() {
    Settings.shared.isAdvertiserTrackingEnabled = false

    XCTAssertFalse(
      Settings.shared.isAdvertiserTrackingEnabled,
      "Setting advertiser tracking status should be disallowed"
    )
    XCTAssertEqual(
      store.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to disallowed"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToUnspecified() {
    Settings.setAdvertiserTrackingStatus(.unspecified)

    XCTAssertNil(
      store.object(forKey: "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"),
      "Should not capture the time the status is set to unspecified"
    )
  }

  // MARK: - Logging behaviors

  func testLoggingBehaviors() {
    let behaviors = Set([LoggingBehavior.accessTokens, .appEvents])
    Settings.shared.loggingBehaviors = behaviors

    XCTAssertEqual(
      Settings.shared.loggingBehaviors,
      behaviors,
      "Should be able to set and retrieve logging behaviors"
    )
  }
}
