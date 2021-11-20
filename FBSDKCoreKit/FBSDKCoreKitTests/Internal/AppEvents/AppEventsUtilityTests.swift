/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class AppEventsUtilityTests: XCTestCase { // swiftlint:disable:this type_body_length

  // swiftlint:disable implicitly_unwrapped_optional
  var userDefaultsSpy: UserDefaultsSpy!
  var bundle: TestBundle!
  var logger: TestEventLogger!
  var appEventsStateProvider: TestAppEventsStateProvider!
  var appEventsConfigurationProvider: TestAppEventsConfigurationProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override class func setUp() {
    super.setUp()

    AppEventsUtility.cachedAdvertiserIdentifierManager = nil
  }

  override func setUp() {
    super.setUp()

    userDefaultsSpy = UserDefaultsSpy()
    bundle = TestBundle()
    logger = TestEventLogger()
    appEventsStateProvider = TestAppEventsStateProvider()
    appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
    appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.valid
    AppEventsUtility.shared.appEventsConfigurationProvider = appEventsConfigurationProvider

    Settings.configure(
      store: userDefaultsSpy,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      infoDictionaryProvider: bundle,
      eventLogger: logger
    )

    let appEvents = AppEvents(flushBehavior: .explicitOnly, flushPeriodInSeconds: 0)
    AppEvents.shared = appEvents
    AppEvents.shared.configure(
      withGateKeeperManager: TestGateKeeperManager.self,
      appEventsConfigurationProvider: TestAppEventsConfigurationProvider(),
      serverConfigurationProvider: TestServerConfigurationProvider(),
      graphRequestFactory: TestGraphRequestFactory(),
      featureChecker: TestFeatureManager(),
      primaryDataStore: userDefaultsSpy,
      logger: TestLogger.self,
      settings: TestSettings(),
      paymentObserver: TestPaymentObserver(),
      timeSpentRecorder: TestTimeSpentRecorder(),
      appEventsStateStore: TestAppEventsStateStore(),
      eventDeactivationParameterProcessor: TestAppEventsParameterProcessor(),
      restrictiveDataFilterParameterProcessor: TestAppEventsParameterProcessor(),
      atePublisherFactory: TestATEPublisherFactory(),
      appEventsStateProvider: appEventsStateProvider,
      advertiserIDProvider: AppEventsUtility.shared,
      userDataStore: TestUserDataStore()
    )
  }

  override func tearDown() {
    userDefaultsSpy = nil
    bundle = nil
    logger = nil
    appEventsStateProvider = nil
    appEventsConfigurationProvider = nil

    AppEvents.reset()
    TestGateKeeperManager.reset()
    AppEventsUtility.cachedAdvertiserIdentifierManager = nil
    Settings.shared.reset()
    super.tearDown()
  }

  func testLogNotification() {
    expectation(forNotification: .AppEventsLoggingResult, object: nil)
    AppEventsUtility.shared.logAndNotify("test")
    waitForExpectations(timeout: 2, handler: nil)
  }

  func testValidation() {
    XCTAssertFalse(AppEventsUtility.validateIdentifier("x-9adc++|!@#"))
    XCTAssertTrue(AppEventsUtility.validateIdentifier("4simple id_-3"))
    XCTAssertTrue(AppEventsUtility.validateIdentifier("_4simple id_-3"))
    XCTAssertFalse(AppEventsUtility.validateIdentifier("-4simple id_-3"))
  }

  func testActivityParametersWithoutUserID() {
    let parameters = AppEventsUtility.activityParametersDictionary(
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
    let parameters = AppEventsUtility.activityParametersDictionary(
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
    let dict = AppEventsUtility.activityParametersDictionary(
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

  func testActivityParametersWithUserData() throws { // swiftlint:disable:this function_body_length
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

    let parameters = AppEventsUtility.activityParametersDictionary(
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
    Settings.shared.isEventDataUsageLimited = false

    let parameters = AppEventsUtility.activityParametersDictionary(
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
    Settings.shared.isEventDataUsageLimited = true

    let parameters = AppEventsUtility.activityParametersDictionary(
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
    let parameters = AppEventsUtility.activityParametersDictionary(
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
    let parameters = AppEventsUtility.activityParametersDictionary(
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
    Settings.shared.shouldUseCachedValuesForExpensiveMetadata = true

    appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.create(
      advertiserIDCollectionEnabled: true
    )
    AppEventsUtility.shared.appEventsConfigurationProvider = appEventsConfigurationProvider

    let identifier = "68753A44-4D6F-1226-9C60-0050E4C00067"
    let uuid = try XCTUnwrap(UUID(uuidString: identifier))
    let identifierManager = TestASIdentifierManager(stubbedAdvertisingIdentifier: uuid)
    AppEventsUtility.cachedAdvertiserIdentifierManager = identifierManager
    let parameters = AppEventsUtility.activityParametersDictionary(
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
    Settings.shared.setDataProcessingOptions(["LDU"], country: 100, state: 1)
    let parameters = AppEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: false,
      userID: nil,
      userData: nil
    )

    XCTAssertEqual(#"["LDU"]"#, parameters["data_processing_options"] as? String)
    XCTAssertEqual(
      parameters["data_processing_options_country"] as? Int,
      100,
      "Should use the data processing options from the settings"
    )
    XCTAssertEqual(
      parameters["data_processing_options_state"] as? Int,
      1,
      "Should use the data processing options from the settings"
    )
  }

  func testActivityParametersWithEmptyLimitedDataProcessingOptions() {
    Settings.shared.setDataProcessingOptions([])
    let parameters = AppEventsUtility.activityParametersDictionary(
      forEvent: "event",
      shouldAccessAdvertisingID: true,
      userID: nil,
      userData: nil
    )
    XCTAssertEqual("[]", parameters["data_processing_options"] as? String)
    XCTAssertEqual(parameters["data_processing_options_country"] as? Int, 0)
    XCTAssertEqual(parameters["data_processing_options_state"] as? Int, 0)
  }

  func testLogImplicitEventsExists() throws {
    let appEventsClass: AnyClass = try XCTUnwrap(NSClassFromString("FBSDKAppEvents"))
    let logEventSelector = NSSelectorFromString("logImplicitEvent:valueToSum:parameters:accessToken:")
    XCTAssertTrue(appEventsClass.instancesRespond(to: logEventSelector))
  }

  func testGetAdvertiserIDWithCollectionEnabled() {
    let configuration = SampleAppEventsConfigurations.create(advertiserIDCollectionEnabled: true)
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertNotNil(
      AppEventsUtility.shared.advertiserID,
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
    XCTAssertNil(AppEventsUtility.shared.advertiserID)
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Allowed             | N/A                | N/A                 | YES                    | NO       |
  func testShouldDropAppEventWithSettingsATEAllowedEventCollectionEnabled() {
    Settings.setAdvertiserTrackingStatus(.allowed)

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      AppEventsUtility.shouldDropAppEvent,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Allowed             | N/A                | N/A                 | NO                     | NO       |
  func testShouldDropAppEventWithSettingsATEAllowedEventCollectionDisabled() {
    Settings.setAdvertiserTrackingStatus(.allowed)

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      AppEventsUtility.shouldDropAppEvent,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Unspecified         | N/A                | N/A                 | YES                    | NO       |
  func testShouldDropAppEventWithSettingsATEUnspecifiedEventCollectionEnabled() {
    Settings.setAdvertiserTrackingStatus(.unspecified)

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      AppEventsUtility.shouldDropAppEvent,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Unspecified         | N/A                | N/A                 | NO                     | NO       |
  func testShouldDropAppEventWithSettingsATEUnspecifiedEventCollectionDisabled() {
    Settings.setAdvertiserTrackingStatus(.allowed)

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      AppEventsUtility.shouldDropAppEvent,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Disallowed          | N/A                | N/A                 | YES                    | NO       |
  func testShouldDropAppEventWithSettingsATEDisallowedEventCollectionEnabled() {
    Settings.setAdvertiserTrackingStatus(.disallowed)

    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: true
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertFalse(
      AppEventsUtility.shouldDropAppEvent,
      "Should not drop events"
    )
  }

  // | Settings ATE status | default ATE status | idCollectionEnabled | eventCollectionEnabled | EXPECTED |
  // | Disallowed          | N/A                | N/A                 | NO                     | YES      |
  func testShouldDropAppEventWithSettingsATEDisallowedEventCollectionDisabled() {
    Settings.setAdvertiserTrackingStatus(.disallowed)
    let configuration = SampleAppEventsConfigurations.create(
      defaultATEStatus: .unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    XCTAssertTrue(
      AppEventsUtility.shouldDropAppEvent,
      "Should drop events when tracking is disallowed and event collection is disabled"
    )
  }

  func testAdvertiserTrackingEnabledInAppEventPayload() {
    let configuration = AppEventsConfiguration(json: [:])
    let statusList: [AdvertisingTrackingStatus] = [
      .allowed,
      .disallowed,
      .unspecified
    ]
    for defaultATEStatus in statusList {
      configuration.setDefaultATEStatus(defaultATEStatus)
      for status in statusList {
        appEventsConfigurationProvider.stubbedConfiguration = configuration
        Settings.shared.reset()
        Settings.configure(
          store: UserDefaultsSpy(),
          appEventsConfigurationProvider: appEventsConfigurationProvider,
          infoDictionaryProvider: TestBundle(),
          eventLogger: TestEventLogger()
        )
        if status != AdvertisingTrackingStatus.unspecified {
          Settings.setAdvertiserTrackingStatus(status)
        }

        let dict = AppEventsUtility.activityParametersDictionary(
          forEvent: "event",
          shouldAccessAdvertisingID: true,
          userID: nil,
          userData: nil
        )

        // If status is unspecified, ATE will be defaultATEStatus
        if status == .unspecified {
          if defaultATEStatus == .unspecified {
            XCTAssertNil(
              dict["advertiser_tracking_enabled"] as? String,
              "advertiser_tracking_enabled should not be attached to event payload if ATE is unspecified"
            )
          } else {
            let advertiserTrackingEnabled = defaultATEStatus == .allowed
            print("advertiserTrackingEnabled: \(advertiserTrackingEnabled)", dict)
            XCTAssertEqual(
              advertiserTrackingEnabled ? "1" : "0",
              dict["advertiser_tracking_enabled"] as? String,
              "advertiser_tracking_enabled should be default value when ATE is not set"
            )
          }
        } else {
          let advertiserTrackingEnabled = status == .allowed
          XCTAssertEqual(
            advertiserTrackingEnabled ? "1" : "0",
            dict["advertiser_tracking_enabled"] as? String,
            "advertiser_tracking_enabled should be equal to ATE explicitly setted via setAdvertiserTrackingStatus"
          )
        }
      }
    }
  }

  func testDropAppEvent() throws {
    // shouldDropAppEvent only when: advertisingTrackingStatus == Disallowed
    // && FBSDKAppEventsConfiguration.eventCollectionEnabled == NO
    Settings.setAdvertiserTrackingStatus(.disallowed)
    AppEventsConfigurationManager.shared.configuration = SampleAppEventsConfigurations.create(
      eventCollectionEnabled: false
    )
    Settings.shared.appID = "123"
    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "event"))
    XCTAssertNil(
      appEventsStateProvider.state,
      "State should be nil when dropping app event"
    )
  }

  func testSendAppEventWhenTrackingUnspecified() throws {
    Settings.setAdvertiserTrackingStatus(.unspecified)
    AppEventsConfigurationManager.shared.configuration = SampleAppEventsConfigurations.create(
      eventCollectionEnabled: false
    )
    Settings.shared.appID = "123"
    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "event"))

    let state = try XCTUnwrap(appEventsStateProvider.state)
    XCTAssertTrue(
      state.isAddEventCalled,
      "Should call addEvents on AppEventsState when dropping app event"
    )
    XCTAssertFalse(
      state.capturedIsImplicit,
      "Shouldn't implicitly call addEvents on AppEventsState when sending app event"
    )
  }

  func testSendAppEventWhenTrackingAllowed() throws {
    Settings.setAdvertiserTrackingStatus(.allowed)
    AppEventsConfigurationManager.shared.configuration = SampleAppEventsConfigurations.create(
      eventCollectionEnabled: true
    )
    Settings.shared.appID = "123"
    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "event"))

    let state = try XCTUnwrap(appEventsStateProvider.state)
    XCTAssertTrue(
      state.isAddEventCalled,
      "Should call addEvents on AppEventsState when dropping app event"
    )
    XCTAssertFalse(
      state.capturedIsImplicit,
      "Shouldn't implicitly call addEvents on AppEventsState when sending app event"
    )
  }

  func testSendAppEventWhenEventCollectionEnabled() throws {
    Settings.setAdvertiserTrackingStatus(.disallowed)
    appEventsConfigurationProvider.stubbedConfiguration = SampleAppEventsConfigurations.create(
      eventCollectionEnabled: true
    )
    Settings.shared.appID = "123"
    AppEvents.shared.logEvent(AppEvents.Name(rawValue: "event"))
    let state = try XCTUnwrap(appEventsStateProvider.state)
    XCTAssertTrue(
      state.isAddEventCalled,
      "Should call addEvents on AppEventsState when dropping app event"
    )
    XCTAssertFalse(
      state.capturedIsImplicit,
      "Shouldn't implicitly call addEvents on AppEventsState when sending app event"
    )
  }

  func testFlushReasonToString() {
    let result1 = AppEventsUtility.flushReason(toString: .explicit)
    XCTAssertEqual("Explicit", result1)

    let result2 = AppEventsUtility.flushReason(toString: .timer)
    XCTAssertEqual("Timer", result2)

    let result3 = AppEventsUtility.flushReason(toString: .sessionChange)
    XCTAssertEqual("SessionChange", result3)

    let result4 = AppEventsUtility.flushReason(toString: .persistedEvents)
    XCTAssertEqual("PersistedEvents", result4)

    let result5 = AppEventsUtility.flushReason(toString: .eventThreshold)
    XCTAssertEqual("EventCountThreshold", result5)

    let result6 = AppEventsUtility.flushReason(toString: .eagerlyFlushingEvent)
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
      XCTAssertTrue(AppEventsUtility.isStandardEvent(event))
    }
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientToken() {
    AccessToken.current = nil
    Settings.shared.appID = nil
    Settings.shared.clientToken = nil

    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)

    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an app id or client token"
    )
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithClientToken() {
    AccessToken.current = nil
    Settings.shared.appID = nil
    Settings.shared.clientToken = "toktok"

    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an app id"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithoutClientToken() {
    AccessToken.current = nil
    Settings.shared.appID = SampleAccessTokens.validToken.appID
    Settings.shared.clientToken = nil

    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without a client Token"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithClientToken() {
    AccessToken.current = nil
    Settings.shared.appID = "abc"
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertEqual(
      tokenString,
      "abc|toktok",
      "Should provide a token string with the app id and client token"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithClientToken() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = nil
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)

    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should provide the token string stored on the current access token"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithoutClientToken() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = nil
    Settings.shared.clientToken = nil
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
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
    Settings.shared.appID = "456"
    Settings.shared.clientToken = nil
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
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
    Settings.shared.appID = "456"
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: nil)
    XCTAssertEqual(
      tokenString,
      SampleAccessTokens.validToken.tokenString,
      "Should provide the token string stored on the current access token when the app id on the token does not match the app id in settings" // swiftlint:disable:this line_length
    )
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    Settings.shared.appID = nil
    Settings.shared.clientToken = nil
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an access token, app id, or client token"
    )
  }

  func testTokenStringWithoutAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    Settings.shared.appID = nil
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without an access token or app id"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    Settings.shared.appID = SampleAccessTokens.validToken.appID
    Settings.shared.clientToken = nil
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string without a client token"
    )
  }

  func testTokenStringWithoutAccessTokenWithAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = nil
    Settings.shared.appID = SampleAccessTokens.validToken.appID
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string with the logging app id and client token"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = nil
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithoutAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = nil
    Settings.shared.clientToken = nil
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithoutClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = "456"
    Settings.shared.clientToken = nil
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppID() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = "456"
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(for: nil, loggingOverrideAppID: "789")
    XCTAssertNil(
      tokenString,
      "Should not provide a token string when the logging override and access token app ids are mismatched"
    )
  }

  func testTokenStringWithAccessTokenWithAppIdWithClientTokenWithLoggingAppIDMatching() {
    AccessToken.current = SampleAccessTokens.validToken
    Settings.shared.appID = "456"
    Settings.shared.clientToken = "toktok"
    let tokenString = AppEventsUtility.tokenStringToUse(
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
    AppEventsUtility.reset()
    XCTAssertNil(
      AppEventsUtility.shared.appEventsConfigurationProvider,
      "Should not have an app events configuration provider by default"
    )
    XCTAssertNil(
      AppEventsUtility.shared.deviceInformationProvider,
      "Should not have a device information provider by default"
    )
  }

  func testCustomDependencies() {
    let appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
    AppEventsUtility.shared.appEventsConfigurationProvider = appEventsConfigurationProvider

    XCTAssertTrue(
      AppEventsUtility.shared.appEventsConfigurationProvider === appEventsConfigurationProvider,
      "Should be able to set a custom app events configuration provider"
    )

    let deviceInformationProvider = TestDeviceInformationProvider()
    AppEventsUtility.shared.deviceInformationProvider = deviceInformationProvider

    XCTAssertTrue(
      AppEventsUtility.shared.deviceInformationProvider === deviceInformationProvider,
      "Should be able to set a custom device information provider"
    )
  }

  func testIsSensitiveUserData() {
    var text = "test@sample.com"
    XCTAssertTrue(AppEventsUtility.isSensitiveUserData(text))

    text = "4716 5255 0221 9085"
    XCTAssertTrue(AppEventsUtility.isSensitiveUserData(text))

    text = "4716525502219085"
    XCTAssertTrue(AppEventsUtility.isSensitiveUserData(text))

    text = "4716525502219086"
    XCTAssertFalse(AppEventsUtility.isSensitiveUserData(text))

    text = ""
    XCTAssertFalse(AppEventsUtility.isSensitiveUserData(text))

    // number of digits less than 9 will not be considered as credit card number
    text = "4716525"
    XCTAssertFalse(AppEventsUtility.isSensitiveUserData(text))
  }

  func testIdentifierManagerWithShouldUseCachedManagerWithCachedManager() {
    let cachedManager = ASIdentifierManager()
    AppEventsUtility.cachedAdvertiserIdentifierManager = cachedManager
    let resolver = TestDylibResolver()

    let manager = AppEventsUtility.shared.asIdentifierManager(
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

    guard AppEventsUtility.cachedAdvertiserIdentifierManager == nil else {
      return XCTFail("Should not begin the test with a cached manager")
    }

    let manager = AppEventsUtility.shared.asIdentifierManager(
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
      AppEventsUtility.cachedAdvertiserIdentifierManager,
      "Should cache the retrieved manager instance"
    )
  }

  func testIdentifierManagerWithShouldNotUseCachedManagerWithCachedManager() {
    let cachedManager = ASIdentifierManager()
    AppEventsUtility.cachedAdvertiserIdentifierManager = cachedManager
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self

    let manager = AppEventsUtility.shared.asIdentifierManager(
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
      AppEventsUtility.cachedAdvertiserIdentifierManager,
      "Should clear the cache when caching is declined"
    )
  }

  func testIdentifierManagerWithShouldNotUseCachedManagerWithoutCachedManager() {
    let resolver = TestDylibResolver()
    resolver.stubbedASIdentifierManagerClass = ASIdentifierManager.self

    guard AppEventsUtility.cachedAdvertiserIdentifierManager == nil else {
      return XCTFail("Should not begin the test with a cached manager")
    }

    let manager = AppEventsUtility.shared.asIdentifierManager(
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
      AppEventsUtility.cachedAdvertiserIdentifierManager,
      "Should clear the cache when caching is declined"
    )
  }

  func testActivityParametersUsesDeviceInformation() throws {
    let deviceInformationProvider = TestDeviceInformationProvider(stubbedEncodedDeviceInfo: name)
    AppEventsUtility.shared.deviceInformationProvider = deviceInformationProvider
    let parameters = AppEventsUtility.shared.activityParametersDictionary(
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
} // swiftlint:disable:this file_length
