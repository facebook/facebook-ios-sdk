/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class AppEventsUtilityTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var appEventsConfigurationProvider: TestAppEventsConfigurationProvider!
  var deviceInformationProvider: TestDeviceInformationProvider!
  var settings: TestSettings!
  var internalUtility: TestInternalUtility!
  var errorFactory: TestErrorFactory!
  var appEventsUtility: AppEventsUtility!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
    appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid
    deviceInformationProvider = TestDeviceInformationProvider()
    settings = TestSettings()
    internalUtility = TestInternalUtility()
    errorFactory = TestErrorFactory()
    appEventsUtility = AppEventsUtility()
    appEventsUtility.configure(
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      deviceInformationProvider: deviceInformationProvider,
      settings: settings,
      internalUtility: internalUtility,
      errorFactory: errorFactory
    )
  }

  override func tearDown() {
    appEventsConfigurationProvider = nil
    deviceInformationProvider = nil
    settings = nil
    internalUtility = nil
    errorFactory = nil
    appEventsUtility = nil

    TestGateKeeperManager.reset()

    super.tearDown()
  }

  func testLogNotification() throws {
    var error: TestSDKError?
    expectation(forNotification: .AppEventsLoggingResult, object: nil) { notification in
      error = notification.object as? TestSDKError
      return true
    }

    appEventsUtility.logAndNotify("test")

    waitForExpectations(timeout: 2)
    let sdkError = try XCTUnwrap(
      error,
      "The notification should contain an error created by the error factory"
    )
    XCTAssertEqual(
      sdkError.code,
      CoreError.errorAppEventsFlush.rawValue,
      "The app events flush error code should be used"
    )
    XCTAssertEqual(
      sdkError.message,
      "test",
      "The message should be added to the error"
    )
  }

  func testValidation() {
    XCTAssertFalse(appEventsUtility.validateIdentifier("x-9adc++|!@#"))
    XCTAssertTrue(appEventsUtility.validateIdentifier("4simple id_-3"))
    XCTAssertTrue(appEventsUtility.validateIdentifier("_4simple id_-3"))
    XCTAssertFalse(appEventsUtility.validateIdentifier("-4simple id_-3"))
  }

  func testActivityParametersWithoutUserID() {
    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertNil(
      parameters["app_user_id"],
      "Parameters should use not have a default user Any"
    )
  }

  func testActivityParametersWithUserID() {
    let userID = NSUUID().uuidString
    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: userID,
      userData: nil
    )

    XCTAssertEqual(
      userID,
      parameters["app_user_id"] as? String,
      "Parameters should use the provided user Any"
    )
  }

  func testActivityParametersWithoutUserData() {
    let dict = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual(
      "{}",
      dict["ud"] as? String,
      "Should represent missing user data as an empty dictionary"
    )
  }

  func testActivityParametersWithUserData() throws {
    let testEmail = "apptest@fb.com"
    let testFirstName = "test_fn"
    let testLastName = "test_ln"
    let testPhone = "123"
    let testGender = "m"
    let testCity = "menlopark"
    let testState = "test_s"
    let testExternalId = "facebook123"
    let store = UserDataStore()

    store.setUserData(testEmail, forType: .email)
    store.setUserData(testFirstName, forType: .firstName)
    store.setUserData(testLastName, forType: .lastName)
    store.setUserData(testPhone, forType: .phone)
    store.setUserData(testGender, forType: .gender)
    store.setUserData(testCity, forType: .city)
    store.setUserData(testState, forType: .state)
    store.setUserData(testExternalId, forType: .externalId)
    let hashedUserData = store.getUserData()

    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: hashedUserData
    )

    // These should be moved to the UserDataStoreTests since this is really just checking that we
    // store various user data fields as hashed strings
    let expectedUserDataDict = [
      "em": Utility.sha256Hash(testEmail as NSObject),
      "fn": Utility.sha256Hash(testFirstName as NSObject),
      "ln": Utility.sha256Hash(testLastName as NSObject),
      "ph": Utility.sha256Hash(testPhone as NSObject),
      "ge": Utility.sha256Hash(testGender as NSObject),
      "ct": Utility.sha256Hash(testCity as NSObject),
      "st": Utility.sha256Hash(testState as NSObject),
      "external_id": Utility.sha256Hash(testExternalId as NSObject)
    ]

    let udParam = parameters["ud"] as? String
    let jsonObject = try XCTUnwrap(udParam?.data(using: .utf8))

    let actualUserDataDict = try XCTUnwrap(TypeUtility.jsonObject(
      with: jsonObject,
      options: .allowFragments
    )) as? [String: String]

    XCTAssertNotNil(actualUserDataDict)
    XCTAssertNotNil(expectedUserDataDict)
    XCTAssertEqual(actualUserDataDict, expectedUserDataDict as? [String: String])
  }

  func testParametersDictionaryWithApplicationTrackingEnabled() {
    settings.isEventDataUsageLimited = false

    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual(
      "1",
      parameters["application_tracking_enabled"] as? String,
      "Application tracking is considered enabled when event data usage is not limited"
    )
  }

  func testParametersDictionaryWithApplicationTrackingDisabled() {
    settings.isEventDataUsageLimited = true

    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual(
      "0",
      parameters["application_tracking_enabled"] as? String,
      "Application tracking is considered disabled when event data usage is limited"
    )
  }

  func testParametersDictionaryWithAccessibleAdvertiserID() {
    settings.isAdvertiserIDCollectionEnabled = true

    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual("event", parameters["event"] as? String)
    XCTAssertEqual(
      parameters["advertiser_id"] as? String,
      "00000000-0000-0000-0000-000000000000",
      "Should attempt to return an advertiser ID when allowed"
    )
  }

  func testParametersDictionaryWithInaccessibleAdvertiserID() {
    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: false,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual("event", parameters["event"] as? String)
    XCTAssertNil(
      parameters["advertiser_id"],
      "Should not access the advertising ID when disallowed"
    )
  }

  func testParametersDictionaryWithCachedAdvertiserIDManager() throws {
    settings.isAdvertiserIDCollectionEnabled = true
    settings.shouldUseCachedValuesForExpensiveMetadata = true

    appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.create(
      advertiserIDCollectionEnabled: true
    )
    appEventsUtility.appEventsConfigurationProvider = appEventsConfigurationProvider

    let identifier = "68753A44-4D6F-1226-9C60-0050E4C00067"
    let uuid = try XCTUnwrap(UUID(uuidString: identifier))
    appEventsUtility.cachedAdvertiserIdentifierManager = TestASIdentifierManager(stubbedAdvertisingIdentifier: uuid)
    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual("event", parameters["event"] as? String)
    XCTAssertEqual(
      parameters["advertiser_id"] as? String,
      "68753A44-4D6F-1226-9C60-0050E4C00067",
      "Should use the advertiser ID from the cached advertiser identifier manager"
    )
  }

  func testActivityParametersWithNonEmptyLimitedDataProcessingOptions() {
    _ = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: false,
      userID: nil,
      userData: nil
    )

    XCTAssertNotNil(
      internalUtility.capturedExtensibleParameters,
      "Should ask the internal utility to extend the parameters with data processing options"
    )
  }

  func testActivityParametersWithEmptyLimitedDataProcessingOptions() {
    _ = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    XCTAssertNotNil(
      internalUtility.capturedExtensibleParameters,
      "Should ask the internal utility to extend the parameters with data processing options"
    )
  }

  func testGetAdvertiserIDWithCollectionEnabled() {
    settings.isAdvertiserIDCollectionEnabled = true
    let configuration = SampleAppEventsConfigurations.create(advertiserIDCollectionEnabled: true)
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertNotNil(
      appEventsUtility.advertiserID,
      "Advertiser id should not be nil when collection is enabled"
    )
  }

  func testGetAdvertiserIDWithCollectionDisabled() {
    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: false,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration
    XCTAssertNil(appEventsUtility.advertiserID)
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Allowed             | N/A                | N/A                 | YES                    | NO       |
  func testShouldDropAppEventWithSettingsATEAllowedEventCollectionEnabled() {
    settings.advertisingTrackingStatus = .allowed

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      appEventsUtility.shouldDropAppEvents,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Allowed             | N/A                | N/A                 | NO                     | NO       |
  func testShouldDropAppEventWithSettingsATEAllowedEventCollectionDisabled() {
    settings.advertisingTrackingStatus = .allowed

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      appEventsUtility.shouldDropAppEvents,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Unspecified         | N/A                | N/A                 | YES                    | NO       |
  func testShouldDropAppEventWithSettingsATEUnspecifiedEventCollectionEnabled() {
    settings.advertisingTrackingStatus = .unspecified

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      appEventsUtility.shouldDropAppEvents,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Unspecified         | N/A                | N/A                 | NO                     | NO       |
  func testShouldDropAppEventWithSettingsATEUnspecifiedEventCollectionDisabled() {
    settings.advertisingTrackingStatus = .allowed

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      appEventsUtility.shouldDropAppEvents,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Disallowed          | N/A                | N/A                 | YES                    | NO       |
  func testShouldDropAppEventWithSettingsATEDisallowedEventCollectionEnabled() {
    settings.advertisingTrackingStatus = .disallowed

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      appEventsUtility.shouldDropAppEvents,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Disallowed          | N/A                | N/A                 | NO                     | YES      |
  func testShouldDropAppEventWithSettingsATEDisallowedEventCollectionDisabled() {
    settings.advertisingTrackingStatus = .disallowed
    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertTrue(
      appEventsUtility.shouldDropAppEvents,
      "Should drop events when tracking is disallowed and event collection is disabled"
    )
  }

  func testAdvertiserTrackingEnabledInAppEventPayload() {
    [
      AdvertisingTrackingStatus.allowed,
      .disallowed,
      .unspecified
    ]
      .shuffled()
      .forEach { status in
        settings.advertisingTrackingStatus = status
        settings.isAdvertiserTrackingEnabled = (status == .allowed)

        let parameters = appEventsUtility.activityParametersDictionary(
          forEvent: "event",
          shouldAccessAdvertisingID: true,
          userID: nil,
          userData: nil
        )

        switch status {
        case .unspecified:
          XCTAssertNil(
            parameters["advertiser_tracking_enabled"] as? String,
            "advertiser_tracking_enabled should not be attached to event payload if ATE is unspecified"
          )

        case .allowed:
          XCTAssertEqual(
            "1",
            parameters["advertiser_tracking_enabled"] as? String,
            "advertiser_tracking_enabled should be default value when ATE is not set"
          )

        case .disallowed:
          XCTAssertEqual(
            "0",
            parameters["advertiser_tracking_enabled"] as? String,
            "advertiser_tracking_enabled should be equal to ATE explicitly setted via setAdvertiserTrackingStatus"
          )

        @unknown default:
          XCTFail("IMPOSSIBLE: Unknown advertiser tracking status -- add a new status to list and new case to switch")
        }
      }
  }

  func testFlushReasonToString() {
    let result1 = appEventsUtility.flushReason(toString: .explicit)
    XCTAssertEqual("Explicit", result1)

    let result2 = appEventsUtility.flushReason(toString: .timer)
    XCTAssertEqual("Timer", result2)

    let result3 = appEventsUtility.flushReason(toString: .sessionChange)
    XCTAssertEqual("SessionChange", result3)

    let result4 = appEventsUtility.flushReason(toString: .persistedEvents)
    XCTAssertEqual("PersistedEvents", result4)

    let result5 = appEventsUtility.flushReason(toString: .eventThreshold)
    XCTAssertEqual("EventCountThreshold", result5)

    let result6 = appEventsUtility.flushReason(toString: .eagerlyFlushingEvent)
    XCTAssertEqual("EagerlyFlushingEvent", result6)
  }

  func testGetStandardEvents() {
    let standardEvents = [
      "fb_mobile_complete_registration",
      "fb_mobile_content_view",
      "fb_mobile_search",
      "fb_mobile_rate",
      "fb_mobile_tutorial_completion",
      "fb_mobile_add_to_cart",
      "fb_mobile_add_to_wishlist",
      "fb_mobile_initiated_checkout",
      "fb_mobile_add_payment_info",
      "fb_mobile_purchase",
      "fb_mobile_level_achieved",
      "fb_mobile_achievement_unlocked",
      "fb_mobile_spent_credits",
      "Contact",
      "CustomizeProduct",
      "Donate",
      "FindLocation",
      "Schedule",
      "StartTrial",
      "SubmitApplication",
      "Subscribe",
      "AdImpression",
      "AdClick"
    ]

    for event in standardEvents {
      XCTAssertTrue(appEventsUtility.isStandardEvent(event))
    }
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientToken() {
    AccessToken.current = nil
    settings.appID = nil
    settings.clientToken = nil

    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)

    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an app id or client token"
    )
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithClientToken() {
    AccessToken.current = nil
    settings.appID = nil
    settings.clientToken = "toktok"

    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an app id"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithoutClientToken() {
    AccessToken.current = nil
    settings.appID = SampleAccessTokens.validToken.appID
    settings.clientToken = nil

    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without a client Token"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithClientToken() {
    AccessToken.current = nil
    settings.appID = "abc"
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertEqual(
      tokenString,
      "abc|toktok",
      "Should provide a token string with the app id and client token"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithClientToken() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = nil
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)

    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should provide the token string stored on the current access token"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithoutClientToken() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = nil
    settings.clientToken = nil
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      """
      Should provide the token string stored on the current access token when
      the app id on the token does not match the app id in settings
      """
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithoutClientToken() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = "456"
    settings.clientToken = nil
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      """
      Should provide the token string stored on the current access token when
      the app id on the token does not match the app id in settings
      """
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithClientToken() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = "456"
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should provide the token string stored on the current access token when the app id on the token does not match the app id in settings" // swiftlint:disable:this line_length
    )
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    settings.appID = nil
    settings.clientToken = nil
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an access token, app id, or client token"
    )
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    settings.appID = nil
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an access token or app id"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    settings.appID = SampleAccessTokens.validToken.appID
    settings.clientToken = nil
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without a client token"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    settings.appID = SampleAccessTokens.validToken.appID
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string with the logging app id and client token"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = nil
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = nil
    settings.clientToken = nil
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = "456"
    settings.clientToken = nil
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = "456"
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppIDMatching() {
    AccessToken.current = SampleAccessTokens.validToken
    settings.appID = "456"
    settings.clientToken = "toktok"
    let tokenString = appEventsUtility.tokenStringToUse(
      for: nil,
      loggingOverrideAppID: SampleAccessTokens.validToken.appID
    )
    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      """
      Should provide the token string stored on the access token when the
      access token's app id matches the logging override
      """
    )
  }

  func testDefaultDependencies() {
    appEventsUtility.reset()
    XCTAssertNil(
      appEventsUtility.appEventsConfigurationProvider,
      "Should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      appEventsUtility.deviceInformationProvider,
      "Should not have a device information provider by default"
    )
    XCTAssertNil(
      appEventsUtility.settings,
      "Should not have settings by default"
    )
    XCTAssertNil(
      appEventsUtility.internalUtility,
      "Should not have an internal utility by default"
    )
    XCTAssertNil(
      appEventsUtility.errorFactory,
      "Should not have an error factory by default"
    )
  }

  func testCustomDependencies() {
    XCTAssertTrue(
      appEventsUtility.appEventsConfigurationProvider === appEventsConfigurationProvider,
      "Should be able to set a custom app events configuration provider"
    )
    XCTAssertTrue(
      appEventsUtility.deviceInformationProvider === deviceInformationProvider,
      "Should be able to set a custom device information provider"
    )
    XCTAssertTrue(
      appEventsUtility.settings === settings,
      "Should be able to set custom settings"
    )
    XCTAssertTrue(
      appEventsUtility.internalUtility === internalUtility,
      "Should be able to set custom internal utility"
    )
    XCTAssertIdentical(
      appEventsUtility.errorFactory,
      errorFactory,
      "Should be able to set custom error factory"
    )
  }

  func testIsSensitiveUserData() {
    var text = "test@sample.com"
    XCTAssertTrue(appEventsUtility.isSensitiveUserData(text))

    text = "4716 5255 0221 9085"
    XCTAssertTrue(appEventsUtility.isSensitiveUserData(text))

    text = "4716525502219085"
    XCTAssertTrue(appEventsUtility.isSensitiveUserData(text))

    text = "4716525502219086"
    XCTAssertFalse(appEventsUtility.isSensitiveUserData(text))

    text = ""
    XCTAssertFalse(appEventsUtility.isSensitiveUserData(text))

    // number of digits less than 9 will not be considered as credit card number
    text = "4716525"
    XCTAssertFalse(appEventsUtility.isSensitiveUserData(text))
  }

  func testIdentifierManagerWithShouldUseCachedManagerWithCachedManager() {
    let cachedManager = ASIdentifierManager()
    appEventsUtility.cachedAdvertiserIdentifierManager = cachedManager
    let resolver = TestDylibResolver()

    let manager = appEventsUtility.asIdentifierManager(
      shouldUseCachedManager: true,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertEqual(
      manager,
      cachedManager,
      "Should use the cached manager when available and indicated"
    )
    XCTAssertFalse(
      resolver.didLoadIdentifierManagerClass,
      "Should not dynamically load the identifier manager class"
    )
  }

  func testIdentifierManagerWithShouldUseCachedManagerWithoutCachedManager() {
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self
    assert(
      appEventsUtility.cachedAdvertiserIdentifierManager == nil,
      "Should not begin the test with a cached manager"
    )

    let manager = appEventsUtility.asIdentifierManager(
      shouldUseCachedManager: true,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertTrue(
      resolver.didLoadIdentifierManagerClass,
      "Should dynamically load the identifier manager class"
    )
    XCTAssertNotNil(
      manager,
      "Should retrieve a manager instance when no cache is available"
    )
    XCTAssertEqual(
      manager,
      appEventsUtility.cachedAdvertiserIdentifierManager,
      "Should cache the retrieved manager instance"
    )
  }

  func testIdentifierManagerWithShouldNotUseCachedManagerWithCachedManager() {
    let cachedManager = ASIdentifierManager()
    appEventsUtility.cachedAdvertiserIdentifierManager = cachedManager
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self

    let manager = appEventsUtility.asIdentifierManager(
      shouldUseCachedManager: false,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertTrue(
      resolver.didLoadIdentifierManagerClass,
      "Should dynamically load the identifier manager class"
    )
    XCTAssertNotNil(
      manager,
      "Should retrieve a manager instance when a cache is available but caching is declined"
    )
    XCTAssertNil(
      appEventsUtility.cachedAdvertiserIdentifierManager,
      "Should clear the cache when caching is declined"
    )
  }

  func testIdentifierManagerWithShouldNotUseCachedManagerWithoutCachedManager() {
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self
    assert(
      appEventsUtility.cachedAdvertiserIdentifierManager == nil,
      "Should not begin the test with a cached manager"
    )

    let manager = appEventsUtility.asIdentifierManager(
      shouldUseCachedManager: false,
      dynamicFrameworkResolver: resolver
    )

    XCTAssertTrue(
      resolver.didLoadIdentifierManagerClass,
      "Should dynamically load the identifier manager class"
    )
    XCTAssertNotNil(
      manager,
      "Should retrieve a manager instance when caching is declined"
    )
    XCTAssertNil(
      appEventsUtility.cachedAdvertiserIdentifierManager,
      "Should clear the cache when caching is declined"
    )
  }

  func testActivityParametersUsesDeviceInformation() throws {
    let deviceInformationProvider = TestDeviceInformationProvider(stubbedEncodedDeviceInfo: name)
    appEventsUtility.deviceInformationProvider = deviceInformationProvider
    let parameters = appEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )

    let extraInformation = try XCTUnwrap(
      parameters[deviceInformationProvider.storageKey] as? String,
      "Should include extra information in the parameters"
    )
    XCTAssertEqual(
      extraInformation,
      deviceInformationProvider.encodedDeviceInfo,
      "Should provide the information from the device information provider"
    )
  }
}
