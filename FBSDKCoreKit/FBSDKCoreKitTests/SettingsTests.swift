/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class SettingsTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var logger: TestEventLogger!
  var appEventsConfigurationProvider: TestAppEventsConfigurationProvider!
  var userDefaultsSpy: UserDefaultsSpy!
  var settings: Settings!
  var bundle: InfoDictionaryProviding!
  // swiftlint:enable implicitly_unwrapped_optional

  var testBundle: TestBundle {
    bundle as! TestBundle // swiftlint:disable:this force_cast
  }

  var userAgentSuffix = ""

  static let emptyString = ""
  static let whiteSpaceToken = "  "

  override func setUp() {
    super.setUp()

    logger = TestEventLogger()
    appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
    userDefaultsSpy = UserDefaultsSpy()
    bundle = TestBundle()
    settings = Settings()
    configureSettings()
  }

  override func tearDown() {
    logger = nil
    appEventsConfigurationProvider = nil
    userDefaultsSpy = nil
    bundle = nil
    settings = nil

    super.tearDown()
  }

  private func configureSettings() {
    settings.configure(
      store: userDefaultsSpy,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      infoDictionaryProvider: bundle,
      eventLogger: logger
    )
  }

  func testDefaultUserDefaultsSpy() {
    settings.reset()
    XCTAssertNil(
      settings.store,
      "Settings should not have a default data userDefaultsSpy"
    )
  }

  func testConfiguringWithUserDefaultsSpy() {
    XCTAssertTrue(
      settings.store === userDefaultsSpy,
      "Should be able to set a persistent data userDefaultsSpy"
    )
  }

  func testDefaultAppEventsConfigurationProvider() {
    settings.reset()
    XCTAssertNil(
      settings.appEventsConfigurationProvider,
      "Settings should not have a default app events configuration provider"
    )
  }

  func testConfiguringWithAppEventsConfigurationProvider() {
    XCTAssertTrue(
      settings.appEventsConfigurationProvider === appEventsConfigurationProvider,
      "Should be able to set an app events configuration provider"
    )
  }

  func testDefaultInfoDictionaryProvider() {
    settings.reset()
    XCTAssertNil(
      settings.infoDictionaryProvider,
      "Settings should not have a default info dictionary provider"
    )
  }

  func testConfiguringWithInfoDictionaryProvider() {
    XCTAssertTrue(
      settings.infoDictionaryProvider === bundle,
      "Should be able to set an info dictionary provider"
    )
  }

  func testDefaultEventLogger() {
    settings.reset()
    XCTAssertNil(
      settings.eventLogger,
      "Settings should not have a default event logger"
    )
  }

  func testConfiguringWithEventLogger() {
    XCTAssertTrue(
      settings.eventLogger === logger,
      "Should be able to set an event logger"
    )
  }

  // MARK: Advertiser Tracking Status

  func testFacebookAdvertiserTrackingStatusDefaultValue() {
    let configuration = TestAppEventsConfiguration(defaultATEStatus: .disallowed)
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertEqual(
      settings.advertisingTrackingStatus,
      configuration.defaultATEStatus,
      """
      Advertiser tracking status should use the cached app events configuration
      when there is no persisted overridden value
      """
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus",
      """
      Should attempt to retrieve the tracking status from the data userDefaultsSpy before
      checking the cached configuration
      """
    )
    XCTAssertTrue(
      appEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testGettingExplicitlySetFacebookAdvertiserTrackingStatus() {
    settings.setAdvertiserTrackingStatus(.disallowed)
    XCTAssertEqual(
      settings.advertisingTrackingStatus,
      .disallowed,
      "Should return the explicitly set tracking status"
    )
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to retrieve the tracking status from the data userDefaultsSpy"
    )
    XCTAssertFalse(
      appEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should not attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testGettingPersistedFacebookAdvertiserTrackingStatus() {
    let key = "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus"
    userDefaultsSpy.set(
      NSNumber(value: AdvertisingTrackingStatus.allowed.rawValue),
      forKey: key
    )
    XCTAssertEqual(
      settings.advertisingTrackingStatus,
      .allowed,
      "Should return the tracking status from the data userDefaultsSpy"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      key,
      "Should retrieve the tracking status from the data userDefaultsSpy"
    )
    XCTAssertFalse(
      appEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should not attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testGettingCachedFacebookAdvertiserTrackingStatus() {
    let key = "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus"
    userDefaultsSpy.set(
      NSNumber(value: AdvertisingTrackingStatus.allowed.rawValue),
      forKey: key
    )
    XCTAssertEqual(
      settings.advertisingTrackingStatus,
      .allowed,
      "Should return the tracking status from the data userDefaultsSpy"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      key,
      "Should retrieve the tracking status from the data userDefaultsSpy"
    )
    XCTAssertFalse(
      appEventsConfigurationProvider.didRetrieveCachedConfiguration,
      "Should not attempt to retrieve the tracking status from a cached configuration"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToEnabled() {
    settings.isAdvertiserTrackingEnabled = true
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to enabled"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToDisallowed() {
    settings.isAdvertiserTrackingEnabled = false
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to disallowed"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToEnabledProperty() {
    settings.isAdvertiserTrackingEnabled = true

    XCTAssertTrue(
      settings.isAdvertiserTrackingEnabled,
      "Setting advertiser tracking status should be allowed"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to enabled"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToDisallowedProperty() {
    settings.isAdvertiserTrackingEnabled = false

    XCTAssertFalse(
      settings.isAdvertiserTrackingEnabled,
      "Setting advertiser tracking status should be disallowed"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp",
      "Should persist the time when the tracking status is set to disallowed"
    )
  }

  func testSettingFacebookAdvertiserTrackingStatusToUnspecified() {
    settings.setAdvertiserTrackingStatus(.unspecified)

    XCTAssertNil(
      userDefaultsSpy.object(forKey: "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"),
      "Should not capture the time the status is set to unspecified"
    )
  }

  // MARK: - Logging behaviors

  func testLoggingBehaviors() {
    let behaviors = Set([LoggingBehavior.accessTokens, .appEvents])
    settings.loggingBehaviors = behaviors

    XCTAssertEqual(
      settings.loggingBehaviors,
      behaviors,
      "Should be able to set and retrieve logging behaviors"
    )
  }

  func testEnableLoggingBehaviors() {
    let appEvents = LoggingBehavior(rawValue: "app_events")
    let networkRequests = LoggingBehavior(rawValue: "network_requests")
    let mockLoggingBehaviors = Set([appEvents, networkRequests])
    let informationBehaviort = LoggingBehavior(rawValue: "informational")

    settings.setLoggingBehaviors(mockLoggingBehaviors)

    XCTAssertEqual(mockLoggingBehaviors, settings.loggingBehaviors)

    // test enable logging behavior
    settings.enableLoggingBehavior(LoggingBehavior(rawValue: "informational"))
    XCTAssertTrue(settings.loggingBehaviors.contains(informationBehaviort))
    settings.disableLoggingBehavior(informationBehaviort)
    XCTAssertFalse(settings.loggingBehaviors.contains(informationBehaviort))
  }

  // MARK: - Graph Error Recovery Enabled

  func testDefaultGraphErrorRecoveryEnabled() {
    XCTAssertTrue(
      settings.isGraphErrorRecoveryEnabled,
      "isGraphErrorRecoveryEnabled should be enabled by default"
    )
  }

  func testDefaultGraphAPIVersion() {
    XCTAssertEqual(
      settings.graphAPIVersion,
      FBSDK_DEFAULT_GRAPH_API_VERSION,
      "Settings should provide a default graph api version"
    )
  }

  // MARK: - Logging Behaviors

  func testSettingsBehaviorsFromMissingPlistEntry() {
    let expected: Set = [LoggingBehavior.developerErrors]
    XCTAssertEqual(
      settings.loggingBehaviors,
      expected,
      "Logging behaviors should default to developer errors when there is no plist entry"
    )
  }

  func testSettingBehaviorsFromPlistWithInvalidEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookLoggingBehavior": ["Foo"]])
    configureSettings()

    XCTAssertEqual(
      settings.loggingBehaviors.first,
      LoggingBehavior(rawValue: "Foo"),
      "Logging behaviors should default to developer errors when"
        + "settings are created with a plist that only has invalid entries but it does not"
    )
  }

  func testSettingBehaviorsFromPlistWithValidEntry() {
    bundle = Bundle(for: Settings.self)
    configureSettings()

    let expected = Set([LoggingBehavior.developerErrors])
    XCTAssertEqual(settings.loggingBehaviors, expected)
  }

  func testLoggingBehaviorsInternalStorage() throws {
    settings.loggingBehaviors = Set([LoggingBehavior.informational])
    XCTAssertNotNil(settings.loggingBehaviors, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Domain Prefix

  func testSettingDomainPrefixFromMissingPlistEntry() {
    XCTAssertNil(
      settings.facebookDomainPart,
      "There should be no default value for a facebook domain prefix"
    )
  }

  func testSettingDomainPrefixFromEmptyPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookDomainPart": Self.emptyString])
    configureSettings()

    XCTAssertEqual(
      settings.facebookDomainPart,
      Self.emptyString,
      "Should not use an empty string as a facebook domain prefix but it does"
    )
  }

  func testSettingFacebookDomainPrefixFromPlist() {
    bundle = TestBundle(infoDictionary: ["FacebookDomainPart": "beta"])
    configureSettings()

    XCTAssertEqual(
      settings.facebookDomainPart,
      "beta",
      "A developer should be able to set any string as the facebook domain prefix to use in building urls"
    )
  }

  func testSettingDomainPrefixWithPlistEntry() {
    let domainPrefix = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookDomainPart": domainPrefix])
    configureSettings()
    settings.facebookDomainPart = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDomainPart"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.facebookDomainPart,
      "foo",
      "Settings should return the explicitly set domain prefix over one gleaned from a plist entry"
    )
  }

  func testSettingDomainPrefixWithoutPlistEntry() {
    settings.facebookDomainPart = "foo"
    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDomainPart"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.facebookDomainPart,
      "foo",
      "Settings should return the explicitly set domain prefix"
    )
  }

  func testSettingEmptyDomainPrefix() {
    settings.facebookDomainPart = Self.emptyString
    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDomainPart"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.facebookDomainPart,
      Self.emptyString,
      "Settings should return the explicitly set domain prefix"
    )
  }

  func testSettingWhitespaceOnlyDomainPrefix() {
    settings.facebookDomainPart = Self.whiteSpaceToken
    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDomainPart"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.facebookDomainPart,
      Self.whiteSpaceToken,
      "Settings should return the explicitly set domain prefix"
    )
  }

  func testDomainPartInternalStorage() {
    settings.facebookDomainPart = "foo"
    resetLoggingSideEffects()

    XCTAssertNotNil(settings.facebookDomainPart, "sanity check")

    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Client Token

  func testClientTokenFromPlist() {
    let clientToken = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookClientToken": clientToken])
    configureSettings()

    XCTAssertEqual(
      settings.clientToken,
      clientToken,
      "A developer should be able to set any string as the client token"
    )
  }

  func testClientTokenFromMissingPlistEntry() {
    XCTAssertNil(
      settings.clientToken,
      "A client token should not have a default value if it is not available in the plist"
    )
  }

  func testSettingClientTokenFromEmptyPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookClientToken": Self.emptyString])
    configureSettings()

    XCTAssertEqual(
      settings.clientToken,
      Self.emptyString,
      "Should not use an empty string as a facebook client token but it will"
    )
  }

  func testSettingClientTokenWithPlistEntry() {
    let clientToken = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookClientToken": clientToken])
    configureSettings()

    settings.clientToken = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookClientToken"],
      "Should not persist the value of a non-cachable property when setting it"
    )

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookClientToken"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.clientToken,
      "foo",
      "Settings should return the explicitly set client token over one gleaned from a plist entry"
    )
  }

  func testSettingClientTokenWithoutPlistEntry() {
    settings.clientToken = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookClientToken"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.clientToken,
      "foo",
      "Settings should return the explicitly set client token"
    )
  }

  func testSettingEmptyClientToken() {
    settings.clientToken = Self.emptyString

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookClientToken"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.clientToken,
      Self.emptyString,
      "Should not userDefaultsSpy an invalid token but it will"
    )
  }

  func testSettingWhitespaceOnlyClientToken() {
    settings.clientToken = Self.whiteSpaceToken

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookClientToken"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.clientToken,
      Self.whiteSpaceToken,
      "Should not userDefaultsSpy a whitespace only client token but it will"
    )
  }

  func testClientTokenInternalStorage() {
    settings.clientToken = "foo"

    resetLoggingSideEffects()

    XCTAssertNotNil(settings.clientToken, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - App Identifier

  func testAppIdentifierFromPlist() {
    let appIdentifier = "abc1234"
    bundle = TestBundle(infoDictionary: ["FacebookAppID": appIdentifier])
    configureSettings()

    XCTAssertEqual(
      settings.appID,
      appIdentifier,
      "A developer should be able to set any string as the app identifier"
    )
  }

  func testAppIdentifierFromMissingPlistEntry() {
    XCTAssertNil(
      settings.appID,
      "An app identifier should not have a default value if it is not available in the plist"
    )
  }

  func testSettingAppIdentifierFromEmptyPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookAppID": Self.emptyString])
    configureSettings()

    XCTAssertEqual(
      settings.appID,
      Self.emptyString,
      "Should not use an empty string as an app identifier but it will"
    )
  }

  func testSettingAppIdentifierWithPlistEntry() {
    let appIdentifier = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookClientToken": appIdentifier])
    configureSettings()

    settings.appID = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookAppID"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appID,
      "foo",
      "Settings should return the explicitly set app identifier over one gleaned from a plist entry"
    )
  }

  func testSettingAppIdentifierWithoutPlistEntry() {
    settings.appID = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookAppID"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appID,
      "foo",
      "Settings should return the explicitly set app identifier"
    )
  }

  func testSettingEmptyAppIdentifier() {
    settings.appID = Self.emptyString

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookAppID"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appID,
      Self.emptyString,
      "Should not userDefaultsSpy an empty app identifier but it will"
    )
  }

  func testSettingWhitespaceOnlyAppIdentifier() {
    settings.appID = Self.whiteSpaceToken

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookAppID"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appID,
      Self.whiteSpaceToken,
      "Should not userDefaultsSpy a whitespace only app identifier but it will"
    )
  }

  func testAppIdentifierInternalStorage() {
    settings.appID = "foo"

    resetLoggingSideEffects()

    XCTAssertNotNil(settings.appID, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Display Name

  func testDisplayNameFromPlist() {
    let displayName = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookDisplayName": displayName])
    configureSettings()

    XCTAssertEqual(
      settings.displayName,
      displayName,
      "A developer should be able to set any string as the display name"
    )
  }

  func testDisplayNameFromMissingPlistEntry() {
    XCTAssertNil(
      settings.displayName,
      "A display name should not have a default value if it is not available in the plist"
    )
  }

  func testSettingDisplayNameFromEmptyPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookDisplayName": Self.emptyString])
    configureSettings()

    XCTAssertEqual(
      settings.displayName,
      Self.emptyString,
      "Should not use an empty string as a display name but it will"
    )
  }

  func testSettingDisplayNameWithPlistEntry() {
    let displayName = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookDisplayName": displayName])
    configureSettings()

    settings.displayName = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDisplayName"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.displayName,
      "foo",
      "Settings should return the explicitly set display name over one gleaned from a plist entry"
    )
  }

  func testSettingDisplayNameWithoutPlistEntry() {
    settings.displayName = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDisplayName"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.displayName,
      "foo",
      "Settings should return the explicitly set display name"
    )
  }

  func testSettingEmptyDisplayName() {
    settings.displayName = Self.emptyString

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDisplayName"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.displayName,
      Self.emptyString,
      "Should not userDefaultsSpy an empty display name but it will"
    )
  }

  func testSettingWhitespaceOnlyDisplayName() {
    settings.displayName = Self.whiteSpaceToken

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookDisplayName"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.displayName,
      Self.whiteSpaceToken,
      "Should not userDefaultsSpy a whitespace only display name but it will"
    )
  }

  func testDisplayNameInternalStorage() {
    settings.displayName = "foo"

    resetLoggingSideEffects()

    XCTAssertNotNil(settings.displayName, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - JPEG Compression Quality

  func testJPEGCompressionQualityFromPlist() {
    let jpegCompressionQuality = 0.1
    bundle = TestBundle(infoDictionary: ["FacebookJpegCompressionQuality": jpegCompressionQuality])
    configureSettings()

    XCTAssertEqual(
      Double(settings.jpegCompressionQuality),
      jpegCompressionQuality,
      accuracy: 0.01,
      "A developer should be able to set a jpeg compression quality via the plist"
    )
  }

  func testJPEGCompressionQualityFromMissingPlistEntry() {
    XCTAssertEqual(
      settings.jpegCompressionQuality,
      0.9,
      accuracy: 0.01,
      "There should be a known default value for jpeg compression quality"
    )
  }

  func testSettingJPEGCompressionQualityFromInvalidPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookJpegCompressionQuality": -2.0])
    configureSettings()

    XCTAssertNotEqual(
      settings.jpegCompressionQuality,
      -0.2,
      "Should not use a negative value as a jpeg compression quality"
    )
  }

  func testSettingJPEGCompressionQualityWithPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookJpegCompressionQuality": 0.2])
    configureSettings()
    settings.jpegCompressionQuality = 0.3

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookJpegCompressionQuality"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.jpegCompressionQuality,
      0.3,
      accuracy: 0.01,
      "Settings should return the explicitly set jpeg compression quality over one gleaned from a plist entry"
    )
  }

  func testSettingJPEGCompressionQualityWithoutPlistEntry() {
    settings.jpegCompressionQuality = 1.0

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookJpegCompressionQuality"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.jpegCompressionQuality,
      1.0,
      "Settings should return the explicitly set jpeg compression quality"
    )
  }

  func testSettingJPEGCompressionQualityTooLow() {
    settings.jpegCompressionQuality = -0.1

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookJpegCompressionQuality"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertNotEqual(
      settings.jpegCompressionQuality,
      -0.1,
      "Should not userDefaultsSpy a negative jpeg compression quality"
    )
  }

  func testSettingJPEGCompressionQualityTooHigh() {
    settings.jpegCompressionQuality = 1.1

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookJpegCompressionQuality"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertNotEqual(
      settings.jpegCompressionQuality,
      1.1,
      "Should not userDefaultsSpy a jpeg compression quality that is larger than 1.0"
    )
  }

  func testJPEGCompressionQualityInternalStorage() {
    settings.jpegCompressionQuality = 1

    resetLoggingSideEffects()

    XCTAssertEqual(settings.jpegCompressionQuality, 1, "Sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - URL Scheme Suffix

  func testURLSchemeSuffixFromPlist() {
    let urlSchemeSuffix = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookUrlSchemeSuffix": urlSchemeSuffix])
    configureSettings()

    XCTAssertEqual(
      settings.appURLSchemeSuffix,
      urlSchemeSuffix,
      "A developer should be able to set any string as the url scheme suffix"
    )
  }

  func testURLSchemeSuffixFromMissingPlistEntry() {
    XCTAssertNil(
      settings.appURLSchemeSuffix,
      "A url scheme suffix should not have a default value if it is not available in the plist"
    )
  }

  func testSettingURLSchemeSuffixFromEmptyPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookUrlSchemeSuffix": Self.emptyString])
    configureSettings()

    XCTAssertEqual(
      settings.appURLSchemeSuffix,
      Self.emptyString,
      "Should not use an empty string as a url scheme suffix but it will"
    )
  }

  func testSettingURLSchemeSuffixWithPlistEntry() {
    let urlSchemeSuffix = "abc123"
    bundle = TestBundle(infoDictionary: ["FacebookUrlSchemeSuffix": urlSchemeSuffix])
    configureSettings()
    settings.appURLSchemeSuffix = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookUrlSchemeSuffix"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appURLSchemeSuffix,
      "foo",
      "Settings should return the explicitly set url scheme suffix over one gleaned from a plist entry"
    )
  }

  func testSettingURLSchemeSuffixWithoutPlistEntry() {
    settings.appURLSchemeSuffix = "foo"

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookUrlSchemeSuffix"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appURLSchemeSuffix,
      "foo",
      "Settings should return the explicitly set url scheme suffix"
    )
  }

  func testSettingEmptyURLSchemeSuffix() {
    settings.appURLSchemeSuffix = Self.emptyString

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookUrlSchemeSuffix"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appURLSchemeSuffix,
      Self.emptyString,
      "Should not userDefaultsSpy an empty url scheme suffix but it will"
    )
  }

  func testSettingWhitespaceOnlyURLSchemeSuffix() {
    settings.appURLSchemeSuffix = Self.whiteSpaceToken

    XCTAssertNil(
      userDefaultsSpy.capturedValues["FacebookUrlSchemeSuffix"],
      "Should not persist the value of a non-cachable property when setting it"
    )
    XCTAssertEqual(
      settings.appURLSchemeSuffix,
      Self.whiteSpaceToken,
      "Should not userDefaultsSpy a whitespace only url scheme suffix but it will"
    )
  }

  func testURLSchemeSuffixInternalStorage() {
    settings.appURLSchemeSuffix = "foo"

    resetLoggingSideEffects()

    XCTAssertNotNil(settings.appURLSchemeSuffix, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Auto Log App Events Enabled

  func testAutoLogAppEventsEnabledFromPlist() {
    bundle = TestBundle(infoDictionary: ["FacebookAutoLogAppEventsEnabled": false])
    configureSettings()

    XCTAssertFalse(
      settings.isAutoLogAppEventsEnabled,
      "A developer should be able to set the value of auto log app events from the plist"
    )
  }

  func testAutoLogAppEventsEnabledDefaultValue() {
    XCTAssertTrue(
      settings.isAutoLogAppEventsEnabled,
      "Auto logging of app events should default to true when there is no plist value given"
    )
  }

  func testAutoLogAppEventsEnabledInvalidPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookAutoLogAppEventsEnabled": Self.emptyString])
    configureSettings()

    XCTAssertFalse(
      settings.isAutoLogAppEventsEnabled,
      "Auto logging of app events should default to true when there is an invalid plist value given but it does not"
    )
  }

  func testSettingAutoLogAppEventsEnabled() {
    settings.isAutoLogAppEventsEnabled = false

    XCTAssertNotNil(
      userDefaultsSpy.capturedValues["FacebookAutoLogAppEventsEnabled"],
      "Should persist the value of a cachable property when setting it"
    )
    XCTAssertFalse(
      settings.isAutoLogAppEventsEnabled,
      "Should use the explicitly set property"
    )
  }

  func testOverridingCachedAutoLogAppEventsEnabled() {
    XCTAssertTrue(settings.isAutoLogAppEventsEnabled)

    bundle = TestBundle(infoDictionary: ["FacebookAutoLogAppEventsEnabled": false])
    configureSettings()

    XCTAssertTrue(
      settings.isAutoLogAppEventsEnabled,
      "Should favor cached properties over those set in the plist"
    )
  }

  func testAutoLogAppEventsEnabledInternalStorage() {
    settings.isAutoLogAppEventsEnabled = true

    resetLoggingSideEffects()

    XCTAssertTrue(settings.isAutoLogAppEventsEnabled, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Advertiser Identifier Collection Enabled

  func testFacebookAdvertiserIDCollectionEnabled() {
    bundle = TestBundle(infoDictionary: ["FacebookAdvertiserIDCollectionEnabled": false])
    configureSettings()

    XCTAssertFalse(
      settings.isAdvertiserIDCollectionEnabled,
      "A developer should be able to set whether advertiser ID collection is enabled from the plist"
    )
  }

  func testFacebookAdvertiserIDCollectionEnabledDefaultValue() {
    XCTAssertTrue(
      settings.isAdvertiserIDCollectionEnabled,
      "Auto collection of advertiser Any should default to true when there is no plist value given"
    )
  }

  func testFacebookAdvertiserIDCollectionEnabledInvalidPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookAdvertiserIDCollectionEnabled": Self.emptyString])
    configureSettings()

    XCTAssertFalse(
      settings.isAdvertiserIDCollectionEnabled,
      "Auto collection of advertiser Any should default to true when"
        + "there is an invalid plist value given but it does not"
    )
  }

  func testSettingFacebookAdvertiserIDCollectionEnabled() {
    settings.isAdvertiserIDCollectionEnabled = false

    XCTAssertNotNil(
      userDefaultsSpy.capturedValues["FacebookAdvertiserIDCollectionEnabled"],
      "Should persist the value of a cachable property when setting it"
    )
    XCTAssertFalse(
      settings.isAdvertiserIDCollectionEnabled,
      "Should use the explicitly set property"
    )
  }

  func testOverridingCachedFacebookAdvertiserIDCollectionEnabled() {
    settings.isAdvertiserIDCollectionEnabled = true
    XCTAssertTrue(settings.isAdvertiserIDCollectionEnabled)

    bundle = TestBundle(infoDictionary: ["FacebookAdvertiserIDCollectionEnabled": false])
    configureSettings()

    XCTAssertTrue(
      settings.isAdvertiserIDCollectionEnabled,
      "Should favor cached properties over those set in the plist"
    )
  }

  func testAdvertiserIDCollectionEnabledInternalStorage() {
    settings.isAdvertiserIDCollectionEnabled = true

    resetLoggingSideEffects()

    XCTAssertTrue(settings.isAdvertiserIDCollectionEnabled, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - SKAdNetwork Report Enabled

  func testFacebookSKAdNetworkReportEnabledFromPlist() {
    bundle = TestBundle(infoDictionary: ["FacebookSKAdNetworkReportEnabled": false])
    configureSettings()

    XCTAssertFalse(
      settings.isSKAdNetworkReportEnabled,
      "A developer should be able to set the value of SKAdNetwork Report from the plist"
    )
  }

  func testFacebookSKAdNetworkReportEnabledDefaultValue() {
    XCTAssertTrue(
      settings.isSKAdNetworkReportEnabled,
      "SKAdNetwork Report should default to true when there is no plist value given"
    )
  }

  func testFacebookSKAdNetworkReportEnabledInvalidPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookSKAdNetworkReportEnabled": Self.emptyString])
    configureSettings()

    XCTAssertFalse(
      settings.isSKAdNetworkReportEnabled,
      "SKAdNetwork Report should default to true when there is an invalid plist value given but it does not"
    )
  }

  func testSettingFacebookSKAdNetworkReportEnabled() {
    settings.isSKAdNetworkReportEnabled = false

    XCTAssertNotNil(
      userDefaultsSpy.capturedValues["FacebookSKAdNetworkReportEnabled"],
      "Should persist the value of a cachable property when setting it"
    )
    XCTAssertFalse(
      settings.isSKAdNetworkReportEnabled,
      "Should use the explicitly set property"
    )
  }

  func testOverridingCachedFacebookSKAdNetworkReportEnabled() {
    XCTAssertTrue(settings.isSKAdNetworkReportEnabled)

    bundle = TestBundle(infoDictionary: ["FacebookSKAdNetworkReportEnabled": false])
    configureSettings()

    XCTAssertTrue(
      settings.isSKAdNetworkReportEnabled,
      "Should favor cached properties over those set in the plist"
    )
  }

  func testFacebookSKAdNetworkReportEnabledInternalStorage() {
    settings.isSKAdNetworkReportEnabled = true

    resetLoggingSideEffects()

    XCTAssertTrue(settings.isSKAdNetworkReportEnabled, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Codeless Debug Log Enabled

  func testFacebookCodelessDebugLogEnabled() {
    bundle = TestBundle(infoDictionary: ["FacebookCodelessDebugLogEnabled": false])
    configureSettings()

    XCTAssertFalse(
      settings.isCodelessDebugLogEnabled,
      "A developer should be able to set whether codeless debug logging is enabled from the plist"
    )
  }

  func testFacebookCodelessDebugLogEnabledDefaultValue() {
    bundle = TestBundle(infoDictionary: [:])
    configureSettings()

    XCTAssertFalse(
      settings.isCodelessDebugLogEnabled,
      "Codeless debug logging enabled should default to false when there is no plist value given"
    )
  }

  func testFacebookCodelessDebugLogEnabledInvalidPlistEntry() {
    bundle = TestBundle(infoDictionary: ["FacebookCodelessDebugLogEnabled": Self.emptyString])
    configureSettings()

    XCTAssertFalse(
      settings.isCodelessDebugLogEnabled,
      "Codeless debug logging enabled should default to true when there is an invalid plist value given but it does not"
    )
  }

  func testSettingFacebookCodelessDebugLogEnabled() {
    settings.isCodelessDebugLogEnabled = false

    XCTAssertNotNil(
      userDefaultsSpy.capturedValues["FacebookCodelessDebugLogEnabled"],
      "Should persist the value of a cachable property when setting it"
    )
    XCTAssertFalse(
      settings.isCodelessDebugLogEnabled,
      "Should use the explicitly set property"
    )
  }

  func testOverridingCachedFacebookCodelessDebugLogEnabled() {
    settings.isCodelessDebugLogEnabled = true
    XCTAssertTrue(settings.isCodelessDebugLogEnabled)

    bundle = TestBundle(infoDictionary: ["FacebookCodelessDebugLogEnabled": false])
    configureSettings()

    XCTAssertTrue(
      settings.isCodelessDebugLogEnabled,
      "Should favor cached properties over those set in the plist"
    )
  }

  func testCachedFacebookCodelessDebugLogEnabledInternalStorage() {
    settings.isCodelessDebugLogEnabled = true

    resetLoggingSideEffects()

    XCTAssertTrue(settings.isCodelessDebugLogEnabled, "sanity check")
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  // MARK: - Caching Properties

  func testInitialAccessForCachablePropertyWithNonEmptyCache() {
    // Using false because it is not the default value for `isAutoInitializationEnabled`
    userDefaultsSpy.capturedValues = ["FacebookAutoLogAppEventsEnabled": false]

    XCTAssertFalse(
      settings.isAutoLogAppEventsEnabled,
      "Should retrieve an initial value for a cachable property when there is a non-empty cache"
    )

    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "FacebookAutoLogAppEventsEnabled",
      "Should attempt to access the cache to retrieve the initial value for a cachable property"
    )
    XCTAssertFalse(
      testBundle.capturedKeys.contains("FacebookAutoLogAppEventsEnabled"),
      "Should not attempt to access the plist for cachable properties that have a value in the cache"
    )
  }

  func testInitialAccessForCachablePropertyWithEmptyCacheNonEmptyPlist() {
    // Using false because it is not the default value for `isAutoInitializationEnabled`
    bundle = TestBundle(infoDictionary: ["FacebookAutoLogAppEventsEnabled": false])
    configureSettings()

    XCTAssertFalse(
      settings.isAutoLogAppEventsEnabled,
      "Should retrieve an initial value from the property list"
    )

    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "FacebookAutoLogAppEventsEnabled",
      "Should attempt to access the cache to retrieve the initial value for a cachable property"
    )
    XCTAssertEqual(
      testBundle.capturedKeys.last,
      "FacebookAutoLogAppEventsEnabled",
      "Should attempt to access the plist for cachable properties that have no value in the cache"
    )
  }

  func testInitialAccessForCachablePropertyWithEmptyCacheEmptyPlistAndDefaultValue() {
    XCTAssertTrue(
      settings.isAutoLogAppEventsEnabled,
      "Should use the default value for a property when there are no values in the cache or plist"
    )

    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "FacebookAutoLogAppEventsEnabled",
      "Should attempt to access the cache to retrieve the initial value for a cachable property"
    )
    XCTAssertEqual(
      testBundle.capturedKeys.last,
      "FacebookAutoLogAppEventsEnabled",
      "Should attempt to access the plist for cachable properties that have no value in the cache"
    )
  }

  func testInitialAccessForNonCachablePropertyWithEmptyPlist() {
    XCTAssertNil(
      settings.clientToken,
      "A non-cachable property with no default value and no plist entry should not have a value"
    )

    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache for a non-cachable property"
    )
    XCTAssertEqual(
      testBundle.capturedKeys.last,
      "FacebookClientToken",
      "Should attempt to access the plist for non-cachable properties"
    )
  }

  func testInitialAccessForNonCachablePropertyWithNonEmptyPlist() {
    bundle = TestBundle(infoDictionary: ["FacebookClientToken": "abc123"])
    configureSettings()

    XCTAssertEqual(
      settings.clientToken,
      "abc123",
      "Should retrieve the initial value from the property list"
    )

    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache for a non-cachable property"
    )
    XCTAssertEqual(
      testBundle.capturedKeys.last,
      "FacebookClientToken",
      "Should attempt to access the plist for non-cachable properties"
    )
  }

  // MARK: - Graph Error Recovery Enabled

  func testSetGraphErrorRecoveryEnabled() {
    settings.isGraphErrorRecoveryEnabled = true
    XCTAssertTrue(settings.isGraphErrorRecoveryEnabled)

    settings.isGraphErrorRecoveryEnabled = false
    XCTAssertFalse(settings.isGraphErrorRecoveryEnabled)
  }

  // MARK: - Limit Event and Data Usage

  func testSetLimitEventAndDataUsageDefault() {
    XCTAssertFalse(
      settings.isEventDataUsageLimited,
      "Should limit event data usage by default"
    )
  }

  func testSetUseCachedValuesForExpensiveMetadata() {
    settings.shouldUseCachedValuesForExpensiveMetadata = true

    XCTAssertTrue(
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsUseCachedValuesForExpensiveMetadata"] as? Int != 0,
      "Should userDefaultsSpy whether or not to limit event and data usage in the user defaults"
    )
    XCTAssertTrue(
      settings.shouldUseCachedValuesForExpensiveMetadata,
      "should use cached values for expensive metadata"
    )
  }

  func testSetUseTokenOptimizations() {
    settings.shouldUseTokenOptimizations = false

    XCTAssertTrue(
      userDefaultsSpy.capturedValues["com.facebook.sdk.FBSDKSettingsUseTokenOptimizations"] as? Int == 0,
      "Should userDefaultsSpy whether or not to use token optimizations"
    )
    XCTAssertFalse(
      settings.shouldUseTokenOptimizations,
      "Should use token optimizations"
    )
  }

  func testSetLimitEventAndDataUsageWithEmptyCache() {
    settings.isEventDataUsageLimited = true

    XCTAssertTrue(
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsUseCachedValuesForExpensiveMetadata"] as? Int != 0,
      "Should userDefaultsSpy whether or not to limit event and data usage in the user defaults"
    )
    XCTAssertTrue(
      settings.isEventDataUsageLimited,
      "Should be able to set whether event data usage is limited"
    )
  }

  func testSetLimitEventAndDataUsageWithNonEmptyCache() {
    settings.isEventDataUsageLimited = true
    XCTAssertTrue(settings.isEventDataUsageLimited, "sanity check")

    settings.isEventDataUsageLimited = false
    XCTAssertFalse(
      settings.isEventDataUsageLimited,
      "Should be able to override the existing value of should limit event data usage"
    )

    XCTAssertTrue(
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsLimitEventAndDataUsage"] as? Int == 0,
      "Should userDefaultsSpy the overridden preference for limiting event data usage in the user defaults"
    )
  }

  // MARK: - Data Processing Options

  func testDataProcessingOptionDefaults() {
    settings.setDataProcessingOptions([])
    let dataProcessingOptions = settings.persistableDataProcessingOptions

    XCTAssertEqual(
      dataProcessingOptions?[DATA_PROCESSING_OPTIONS_COUNTRY] as! Int, // swiftlint:disable:this force_cast
      0,
      "Country should default to zero when not provided"
    )
    XCTAssertEqual(
      dataProcessingOptions?[DATA_PROCESSING_OPTIONS_STATE] as! Int, // swiftlint:disable:this force_cast
      0,
      "State should default to zero when not provided"
    )
  }

  func testSettingEmptyDataProcessingOptions() {
    settings.setDataProcessingOptions([])

    XCTAssertNotNil(
      settings.persistableDataProcessingOptions,
      "Should not be able to set data processing options to an empty list of options but you can"
    )
  }

  func testSettingInvalidDataProcessOptions() throws {
    settings.setDataProcessingOptions(["Foo", "Bar"])

    XCTAssertNotNil(
      settings.persistableDataProcessingOptions,
      "Should not be able to set data processing options to invalid list of options but you can"
    )

    let persistedData = NSKeyedArchiver.archivedData(withRootObject: settings.persistableDataProcessingOptions as Any)

    let capturedValues = userDefaultsSpy.capturedValues

    let capturedData = try XCTUnwrap(capturedValues["com.facebook.sdk:FBSDKSettingsDataProcessingOptions"] as? Data)

    let dict1 = try? NSKeyedUnarchiver.unarchivedObject(
      ofClasses: [NSDictionary.self, NSString.self, NSNumber.self, NSDate.self, NSSet.self, NSArray.self],
      from: capturedData
    )

    let dict2 = try? NSKeyedUnarchiver.unarchivedObject(
      ofClasses: [NSDictionary.self, NSString.self, NSNumber.self, NSDate.self, NSSet.self, NSArray.self],
      from: persistedData
    )

    let array1 = (dict1 as? [String: Any])?["data_processing_options"] as? [String]
    let array2 = (dict2 as? [String: Any])?["data_processing_options"] as? [String]
    XCTAssertEqual(array1, ["Foo", "Bar"])
    XCTAssertEqual(array2, ["Foo", "Bar"])
  }

  func testSettingDataProcessingOptionsWithCountryAndState() {
    let countryCode = -1000000000
    let stateCode = 100000000

    settings.setDataProcessingOptions([], country: Int32(countryCode), state: Int32(stateCode))
    let dataProcessingOptions = settings.persistableDataProcessingOptions
    XCTAssertEqual(
      (settings.persistableDataProcessingOptions?[DATA_PROCESSING_OPTIONS] as? [Any])?.isEmpty,
      true,
      "Should use the provided array of processing options"
    )
    XCTAssertEqual(
      dataProcessingOptions?[DATA_PROCESSING_OPTIONS_COUNTRY] as? Int,
      countryCode,
      "Should use the provided country code"
    )
    XCTAssertEqual(
      dataProcessingOptions?[DATA_PROCESSING_OPTIONS_STATE] as? Int,
      stateCode,
      "Should use the provided state code"
    )
  }

  func testDataProcessingOptionsWithEmptyCache() {
    XCTAssertNil(
      settings.persistableDataProcessingOptions,
      "Should not be able to get data processing options if there is none cached"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "com.facebook.sdk:FBSDKSettingsDataProcessingOptions",
      "Should attempt to access the cache to retrieve the initial value for a cachable property"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist for data processing options"
    )
  }

  func testDataProcessingOptionsWithNonEmptyCache() {
    settings.setDataProcessingOptions([])

    // Reset internal storage
    settings.reset()
    configureSettings()

    XCTAssertNotNil(
      settings.persistableDataProcessingOptions,
      "Should be able to retrieve data processing options from the cache"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "com.facebook.sdk:FBSDKSettingsDataProcessingOptions",
      "Should attempt to access the cache to retrieve the initial value for a cachable property"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist for data processing options"
    )
  }

  func testDataProcessingOptionsInternalStorage() {
    settings.setDataProcessingOptions([])

    XCTAssertNotNil(
      settings.persistableDataProcessingOptions,
      "sanity check"
    )
    XCTAssertNil(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "Should not attempt to access the cache to retrieve objects that have a current value"
    )
    XCTAssertNil(
      testBundle.capturedKeys.last,
      "Should not attempt to access the plist to retrieve objects that have a current value"
    )
  }

  func testRecordInstall() {
    XCTAssertNil(
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsInstallTimestamp"],
      "Should not persist the value of before setting it"
    )
    settings.recordInstall()
    XCTAssertNotNil(
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsInstallTimestamp"],
      "Should persist the value after setting it"
    )
    let date = userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsInstallTimestamp"]
    settings.recordInstall()
    XCTAssertEqual(
      date as? Date,
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsInstallTimestamp"] as? Date,
      "Should not change the cached install timesstamp"
    )
  }

  func testRecordSetAdvertiserTrackingEnabled() {
    settings.recordSetAdvertiserTrackingEnabled()
    XCTAssertNotNil(
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"],
      "Should persist the value after setting it"
    )
    let date = userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"]
    settings.recordSetAdvertiserTrackingEnabled()
    XCTAssertNotEqual(
      date as? Date,
      userDefaultsSpy.capturedValues["com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"] as? Date,
      "Should update set advertiser tracking enabled timesstamp"
    )
  }

  func testIsEventDelayTimerExpired() {
    settings.recordInstall()
    XCTAssertFalse(settings.isEventDelayTimerExpired())

    let today = Date()
    let calendar = Calendar(identifier: .gregorian)
    var addComponents = DateComponents()
    addComponents.month = -1
    let expiredDate = calendar.date(byAdding: addComponents, to: today, wrappingComponents: false)

    userDefaultsSpy.setValue(expiredDate, forKey: "com.facebook.sdk:FBSDKSettingsInstallTimestamp")

    XCTAssertTrue(settings.isEventDelayTimerExpired())
  }

  func testIsSetATETimeExceedsInstallTime() {
    settings.recordInstall()
    settings.recordSetAdvertiserTrackingEnabled()
    XCTAssertFalse(settings.isSetATETimeExceedsInstallTime)
    settings.recordSetAdvertiserTrackingEnabled()
    let today = Date()
    let calendar = Calendar(identifier: .gregorian)
    var addComponents = DateComponents()
    addComponents.month = -1
    let expiredDate = calendar.date(byAdding: addComponents, to: today, wrappingComponents: false)
    userDefaultsSpy.setValue(expiredDate, forKey: "com.facebook.sdk:FBSDKSettingsInstallTimestamp")
    XCTAssertTrue(settings.isSetATETimeExceedsInstallTime)
  }

  // MARK: - test for internal functions

  // MARK: - User Agent Suffix

  func testSettingEmptyUserAgentSuffix() {
    userAgentSuffix = Self.emptyString

    XCTAssertEqual(
      userAgentSuffix,
      Self.emptyString,
      "Should not userDefaultsSpy an empty user agent suffix but it will"
    )
  }

  func testSettingWhitespaceOnlyUserAgentSuffix() {
    userAgentSuffix = Self.whiteSpaceToken

    XCTAssertEqual(
      userAgentSuffix,
      Self.whiteSpaceToken,
      "Should not userDefaultsSpy a whitespace only user agent suffix but it will"
    )
  }

  func testSetGraphAPIVersion() {
    let mockGraphAPIVersion = "mockGraphAPIVersion"
    settings.graphAPIVersion = mockGraphAPIVersion
    XCTAssertEqual(mockGraphAPIVersion, settings.graphAPIVersion)
  }

  func testIsDataProcessingRestricted() {
    settings.setDataProcessingOptions(["LDU"])
    XCTAssertTrue(settings.isDataProcessingRestricted)
    settings.setDataProcessingOptions([])
    XCTAssertFalse(settings.isDataProcessingRestricted)
    settings.setDataProcessingOptions(["ldu"])
    XCTAssertTrue(settings.isDataProcessingRestricted)
    settings.setDataProcessingOptions(nil)
    XCTAssertFalse(settings.isDataProcessingRestricted)
  }

  func resetLoggingSideEffects() {
    bundle = TestBundle()
    userDefaultsSpy = UserDefaultsSpy()
  }
}
