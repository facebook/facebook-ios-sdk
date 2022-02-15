/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import FBSDKCoreKit
import TestTools
import XCTest

final class AppEventsTests: XCTestCase {

  let mockAppID = "mockAppID"
  let mockUserID = "mockUserID"
  let purchaseAmount = 1.0
  let currency = "USD"
  var eventName = AppEvents.Name("fb_mock_event")
  var payload = ["fb_push_payload": ["campaign": "testCampaign"]]

  // swiftlint:disable implicitly_unwrapped_optional
  var appEvents: AppEvents!
  var atePublisherFactory: TestATEPublisherFactory!
  var atePublisher: TestATEPublisher!
  var timeSpentRecorder: TestTimeSpentRecorder!
  var integrityParametersProcessor: TestAppEventsParameterProcessor!
  var graphRequestFactory: TestGraphRequestFactory!
  var primaryDataStore: UserDefaultsSpy!
  var featureManager: TestFeatureManager!
  var settings: TestSettings!
  var onDeviceMLModelManager: TestOnDeviceMLModelManager!
  var paymentObserver: TestPaymentObserver!
  var appEventsStateStore: TestAppEventsStateStore!
  var metadataIndexer: TestMetadataIndexer!
  var appEventsConfigurationProvider: TestAppEventsConfigurationProvider!
  var eventDeactivationParameterProcessor: TestAppEventsParameterProcessor!
  var restrictiveDataFilterParameterProcessor: TestAppEventsParameterProcessor!
  var appEventsStateProvider: TestAppEventsStateProvider!
  var advertiserIDProvider: TestAdvertiserIDProvider!
  var skAdNetworkReporter: TestAppEventsReporter!
  var serverConfigurationProvider: TestServerConfigurationProvider!
  var userDataStore: TestUserDataStore!
  var appEventsUtility: TestAppEventsUtility!
  var internalUtility: TestInternalUtility!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    resetTestHelpers()

    appEvents = AppEvents(
      flushBehavior: .explicitOnly,
      flushPeriodInSeconds: 0
    )
    settings = TestSettings()
    settings.isAutoLogAppEventsEnabled = true
    integrityParametersProcessor = TestAppEventsParameterProcessor()
    onDeviceMLModelManager = TestOnDeviceMLModelManager()
    onDeviceMLModelManager.integrityParametersProcessor = integrityParametersProcessor
    paymentObserver = TestPaymentObserver()
    metadataIndexer = TestMetadataIndexer()

    graphRequestFactory = TestGraphRequestFactory()
    primaryDataStore = UserDefaultsSpy()
    featureManager = TestFeatureManager()
    paymentObserver = TestPaymentObserver()
    appEventsStateStore = TestAppEventsStateStore()
    eventDeactivationParameterProcessor = TestAppEventsParameterProcessor()
    restrictiveDataFilterParameterProcessor = TestAppEventsParameterProcessor()
    appEventsConfigurationProvider = TestAppEventsConfigurationProvider()
    appEventsStateProvider = TestAppEventsStateProvider()
    atePublisherFactory = TestATEPublisherFactory()
    timeSpentRecorder = TestTimeSpentRecorder()
    advertiserIDProvider = TestAdvertiserIDProvider()
    skAdNetworkReporter = TestAppEventsReporter()
    serverConfigurationProvider = TestServerConfigurationProvider(
      configuration: ServerConfigurationFixtures.defaultConfig
    )
    userDataStore = TestUserDataStore()
    appEventsUtility = TestAppEventsUtility()
    internalUtility = TestInternalUtility()
    appEventsUtility.stubbedIsIdentifierValid = true

    // Must be stubbed before the configure method is called
    atePublisher = TestATEPublisher()
    atePublisherFactory.stubbedPublisher = atePublisher

    configureAppEvents()
    appEvents.loggingOverrideAppID = mockAppID
  }

  override func tearDown() {
    appEvents = nil
    atePublisherFactory = nil
    atePublisher = nil
    timeSpentRecorder = nil
    integrityParametersProcessor = nil
    graphRequestFactory = nil
    primaryDataStore = nil
    featureManager = nil
    settings = nil
    onDeviceMLModelManager = nil
    paymentObserver = nil
    appEventsStateStore = nil
    metadataIndexer = nil
    appEventsConfigurationProvider = nil
    eventDeactivationParameterProcessor = nil
    restrictiveDataFilterParameterProcessor = nil
    appEventsStateProvider = nil
    advertiserIDProvider = nil
    skAdNetworkReporter = nil
    serverConfigurationProvider = nil
    userDataStore = nil
    appEventsUtility = nil
    internalUtility = nil

    resetTestHelpers()

    super.tearDown()
  }

  func resetTestHelpers() {
    TestGateKeeperManager.reset()
    TestLogger.reset()
    TestCodelessEvents.reset()
    TestAEMReporter.reset()
  }

  func configureAppEvents() {
    appEvents.configure(
      withGateKeeperManager: TestGateKeeperManager.self,
      appEventsConfigurationProvider: appEventsConfigurationProvider,
      serverConfigurationProvider: serverConfigurationProvider,
      graphRequestFactory: graphRequestFactory,
      featureChecker: featureManager,
      primaryDataStore: primaryDataStore,
      logger: TestLogger.self,
      settings: settings,
      paymentObserver: paymentObserver,
      timeSpentRecorder: timeSpentRecorder,
      appEventsStateStore: appEventsStateStore,
      eventDeactivationParameterProcessor: eventDeactivationParameterProcessor,
      restrictiveDataFilterParameterProcessor: restrictiveDataFilterParameterProcessor,
      atePublisherFactory: atePublisherFactory,
      appEventsStateProvider: appEventsStateProvider,
      advertiserIDProvider: advertiserIDProvider,
      userDataStore: userDataStore,
      appEventsUtility: appEventsUtility,
      internalUtility: internalUtility
    )

    appEvents.configureNonTVComponents(
      onDeviceMLModelManager: onDeviceMLModelManager,
      metadataIndexer: metadataIndexer,
      skAdNetworkReporter: skAdNetworkReporter,
      codelessIndexer: TestCodelessEvents.self,
      swizzler: TestSwizzler.self,
      aemReporter: TestAEMReporter.self
    )
  }

  func testConfiguringSetsSwizzlerDependency() {
    XCTAssertIdentical(
      appEvents.swizzler,
      TestSwizzler.self,
      "Configuring should set the provided swizzler"
    )
  }

  func testConfiguringWithoutAvailableAppID() {
    appEvents.reset()
    configureAppEvents()

    XCTAssertNil(
      appEvents.atePublisher,
      "Configuring without an available app ID should not create an ate publisher"
    )
  }

  func testConfiguringWithAppIDFromSettingsCreatesATEPublisher() {
    settings.appID = mockAppID
    configureAppEvents()

    XCTAssertEqual(
      atePublisherFactory.capturedAppID,
      mockAppID,
      "Configuring should create an ate publisher with the expected app ID"
    )
    XCTAssertIdentical(
      appEvents.atePublisher,
      atePublisher,
      "Should store the publisher created by the publisher factory"
    )
  }

  func testConfiguringWithAppIDFromLoggingOverrideCreatesATEPublisher() {
    appEvents.loggingOverrideAppID = mockAppID
    configureAppEvents()

    XCTAssertEqual(
      atePublisherFactory.capturedAppID,
      mockAppID,
      "Configuring should create an ate publisher with the expected app ID"
    )
    XCTAssertIdentical(
      appEvents.atePublisher,
      atePublisher,
      "Should store the publisher created by the publisher factory"
    )
  }

  func testPublishingATEWithNilPublisher() {
    appEvents.atePublisher = nil
    appEvents.publishATE()

    XCTAssertIdentical(
      appEvents.atePublisher,
      atePublisher,
      "Should lazily create an ATE publisher when needed"
    )
  }

  func testLogPurchaseFlushesWhenFlushBehaviorIsExplicit() {
    appEvents.flushBehavior = .auto
    appEvents.logPurchase(amount: purchaseAmount, currency: currency)

    // Verifying flush
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)

    XCTAssertEqual(
      graphRequestFactory.capturedRequests.first?.graphPath,
      "mockAppID/activities"
    )
    validateAEMReporterCalled(
      eventName: .init("fb_mobile_purchase"),
      currency: currency,
      value: purchaseAmount,
      parameters: [.init("fb_currency"): "USD"]
    )
  }

  func testLogPurchase() throws {
    appEvents.logPurchase(amount: purchaseAmount, currency: currency)

    let state = try XCTUnwrap(
      appEventsStateProvider.state,
      "The app events state provider should provide a valid app events state"
    )

    XCTAssertEqual(
      state.capturedEventDictionary?["_eventName"] as? AppEvents.Name,
      .purchased,
      "Should log an event with the expected event name"
    )
    XCTAssertEqual(
      state.capturedEventDictionary?["_valueToSum"] as? Double,
      purchaseAmount,
      "Should log an event with the expected purchase amount"
    )
    XCTAssertEqual(
      state.capturedEventDictionary?["fb_currency"] as? String,
      currency,
      "Should log an event with the expected currency"
    )
    XCTAssertTrue(
      state.isAddEventCalled,
      "Should add events to AppEventsState when logging purshase"
    )
    XCTAssertFalse(
      state.capturedIsImplicit,
      "Shouldn't implicitly add events to AppEventsState when logging purshase"
    )
    validateAEMReporterCalled(
      eventName: .init("fb_mobile_purchase"),
      currency: currency,
      value: purchaseAmount,
      parameters: [.init("fb_currency"): "USD"]
    )
  }

  func testFlush() {
    let predicate = NSPredicate { _, _ in
      // A not-the-best proxy to determine if a flush occurred.
      self.appEventsConfigurationProvider.firstCapturedBlock != nil
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)

    appEvents.logEvent(AppEvents.Name(rawValue: "foo"))
    appEvents.flush()

    wait(for: [expectation], timeout: 2)

    validateAEMReporterCalled(
      eventName: .init("foo"),
      currency: nil,
      value: nil,
      parameters: [:]
    )
  }

  // MARK: - Tests for log product item

  func testLogProductItemNonNil() throws {
    appEvents.logProductItem(
      id: "F40CEE4E-471E-45DB-8541-1526043F4B21",
      availability: .inStock,
      condition: .new,
      description: "description",
      imageLink: "https://www.sample.com",
      link: "https://www.sample.com",
      title: "title",
      priceAmount: 1.0,
      currency: "USD",
      gtin: "BLUE MOUNTAIN",
      mpn: "BLUE MOUNTAIN",
      brand: "PHILZ",
      parameters: [:]
    )

    let expectedAEMParameters: [AppEvents.ParameterName: String] = [
      .init("fb_product_availability"): "IN_STOCK",
      .init("fb_product_brand"): "PHILZ",
      .init("fb_product_condition"): "NEW",
      .init("fb_product_description"): "description",
      .init("fb_product_gtin"): "BLUE MOUNTAIN",
      .init("fb_product_image_link"): "https://www.sample.com",
      .init("fb_product_item_id"): "F40CEE4E-471E-45DB-8541-1526043F4B21",
      .init("fb_product_link"): "https://www.sample.com",
      .init("fb_product_mpn"): "BLUE MOUNTAIN",
      .init("fb_product_price_amount"): "1.000",
      .init("fb_product_price_currency"): "USD",
      .init("fb_product_title"): "title",
    ]

    let capturedParameters = try XCTUnwrap(
      appEventsStateProvider.state?.capturedEventDictionary
    )
    XCTAssertEqual(
      capturedParameters["_eventName"] as? String,
      "fb_mobile_catalog_update"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_availability"] as? String,
      "IN_STOCK"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_brand"] as? String,
      "PHILZ"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_condition"] as? String,
      "NEW"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_description"] as? String,
      "description"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_gtin"] as? String,
      "BLUE MOUNTAIN"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_image_link"] as? String,
      "https://www.sample.com"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_item_id"] as? String,
      "F40CEE4E-471E-45DB-8541-1526043F4B21"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_link"] as? String,
      "https://www.sample.com"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_mpn"] as? String,
      "BLUE MOUNTAIN"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_price_amount"] as? String,
      "1.000"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_price_currency"] as? String,
      "USD"
    )
    XCTAssertEqual(
      capturedParameters["fb_product_title"] as? String,
      "title"
    )

    validateAEMReporterCalled(
      eventName: .init("fb_mobile_catalog_update"),
      currency: nil,
      value: nil,
      parameters: expectedAEMParameters
    )
  }

  func testLogProductItemNilGtinMpnBrand() {
    appEvents.logProductItem(
      id: "F40CEE4E-471E-45DB-8541-1526043F4B21",
      availability: .inStock,
      condition: .new,
      description: "description",
      imageLink: "https: //www.sample.com",
      link: "https: //www.sample.com",
      title: "title",
      priceAmount: 1.0,
      currency: "USD",
      gtin: nil,
      mpn: nil,
      brand: nil,
      parameters: [:]
    )

    XCTAssertNil(
      appEventsStateProvider.state?.capturedEventDictionary?["_eventName"],
      "Should not log a product item when key fields are missing"
    )
    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      .developerErrors,
      "A log entry of LoggingBehaviorDeveloperErrors should be posted when some parameters are nil for logProductItem"
    )
  }

  // MARK: - Tests for user data

  func testGettingUserData() {
    appEvents.getUserData()

    XCTAssertTrue(
      userDataStore.wasGetUserDataCalled,
      "Should rely on the underlying store for user data"
    )
  }

  func testSetAndClearUserData() {
    let email = "test_em"
    let firstName = "test_fn"
    let lastName = "test_ln"
    let phone = "test_phone"
    let dateOfBirth = "test_dateOfBirth"
    let gender = "test_gender"
    let city = "test_city"
    let state = "test_state"
    let zip = "test_zip"
    let country = "test_country"

    // Setting
    appEvents.setUser(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      city: city,
      state: state,
      zip: zip,
      country: country
    )

    XCTAssertEqual(userDataStore.capturedEmail, email)
    XCTAssertEqual(userDataStore.capturedFirstName, firstName)
    XCTAssertEqual(userDataStore.capturedLastName, lastName)
    XCTAssertEqual(userDataStore.capturedPhone, phone)
    XCTAssertEqual(userDataStore.capturedDateOfBirth, dateOfBirth)
    XCTAssertEqual(userDataStore.capturedGender, gender)
    XCTAssertEqual(userDataStore.capturedCity, city)
    XCTAssertEqual(userDataStore.capturedState, state)
    XCTAssertEqual(userDataStore.capturedZip, zip)
    XCTAssertEqual(userDataStore.capturedCountry, country)
    XCTAssertNil(userDataStore.capturedExternalId)

    // Clearing
    appEvents.clearUserData()
    XCTAssertTrue(
      userDataStore.wasClearUserDataCalled,
      "Should rely on the underlying store for clearing user data"
    )
  }

  func testSettingUserDataForType() {
    appEvents.setUserData(name, forType: .email)

    XCTAssertEqual(
      userDataStore.capturedSetUserDataForTypeData,
      name,
      "Should invoke the underlying store with the expected user data"
    )
    XCTAssertEqual(
      userDataStore.capturedSetUserDataForTypeType,
      .email,
      "Should invoke the underlying store with the expected user data type"
    )
  }

  func testClearingUserDataForType() {
    appEvents.clearUserData(forType: .email)

    XCTAssertEqual(
      userDataStore.capturedClearUserDataForTypeType,
      .email,
      "Should rely on the underlying store for clearing user data by type"
    )
  }

  func testSetAndClearUserID() {
    appEvents.userID = mockUserID
    XCTAssertEqual(appEvents.userID, mockUserID)
    appEvents.userID = nil
    XCTAssertNil(appEvents.userID)
  }

  func testSetLoggingOverrideAppID() {
    let mockOverrideAppID = "2"
    appEvents.loggingOverrideAppID = mockOverrideAppID
    XCTAssertEqual(appEvents.loggingOverrideAppID, mockOverrideAppID)
  }

  func testSetPushNotificationsDeviceTokenString() {
    let mockDeviceTokenString = "testDeviceTokenString"
    eventName = .init("fb_mobile_obtain_push_token")

    appEvents.pushNotificationsDeviceTokenString = mockDeviceTokenString

    XCTAssertEqual(
      appEventsStateProvider.state?.capturedEventDictionary?["_eventName"] as? String,
      eventName.rawValue
    )
    XCTAssertEqual(appEvents.pushNotificationsDeviceTokenString, mockDeviceTokenString)
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: nil,
      parameters: [:]
    )
  }

  func testActivateAppWithInitializedSDK() throws {
    appEvents.activateApp()

    XCTAssertTrue(
      timeSpentRecorder.restoreWasCalled,
      "Activating App with initialized SDK should restore recording time spent data."
    )
    XCTAssertTrue(
      timeSpentRecorder.capturedCalledFromActivateApp,
      """
      Activating App with initialized SDK should indicate its \
      calling from activateApp when restoring recording time spent data.
      """
    )

    // The publish call happens after both configs are fetched
    appEventsConfigurationProvider.firstCapturedBlock?()
    appEventsConfigurationProvider.lastCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    serverConfigurationProvider.secondCapturedCompletionBlock?(nil, nil)

    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    XCTAssertEqual(
      request.parameters["event"] as? String,
      "MOBILE_APP_INSTALL"
    )
  }

  func testApplicationBecomingActiveRestoresTimeSpentRecording() {
    appEvents.applicationDidBecomeActive()
    XCTAssertTrue(
      timeSpentRecorder.restoreWasCalled,
      "When application did become active, the time spent recording should be restored."
    )
    XCTAssertFalse(
      timeSpentRecorder.capturedCalledFromActivateApp,
      """
      When application did become active, the time spent recording restoration \
      should indicate that it's not activating.
      """
    )
  }

  func testApplicationTerminatingSuspendsTimeSpentRecording() {
    appEvents.applicationMovingFromActiveStateOrTerminating()
    XCTAssertTrue(
      timeSpentRecorder.suspendWasCalled,
      "When application terminates or moves from active state, the time spent recording should be suspended."
    )
  }

  func testApplicationTerminatingPersistingStates() {
    appEvents.flushBehavior = .explicitOnly
    appEvents.logEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: nil,
      isImplicitlyLogged: false,
      accessToken: SampleAccessTokens.validToken
    )
    appEvents.logEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: nil,
      isImplicitlyLogged: false,
      accessToken: SampleAccessTokens.validToken
    )
    appEvents.applicationMovingFromActiveStateOrTerminating()

    XCTAssertTrue(
      !appEventsStateStore.capturedPersistedState.isEmpty,
      "When application terminates or moves from active state, the existing state should be persisted."
    )
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: purchaseAmount,
      parameters: nil
    )
  }

  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable opening_brace
  func testUsingAppEventsWithUninitializedSDK() throws {
    let foo = "foo"
    appEvents = AppEvents(
      flushBehavior: .explicitOnly,
      flushPeriodInSeconds: 0
    )
    let exceptionRaisingClosures = [
      { self.appEvents.flushBehavior = .auto },
      { self.appEvents.loggingOverrideAppID = foo },
      { self.appEvents.logEvent(.searched) },
      { self.appEvents.logEvent(.searched, valueToSum: 2) },
      { self.appEvents.logEvent(.searched, parameters: [:]) },
      { self.appEvents.logEvent(.searched, valueToSum: 2, parameters: [:]) },
      {
        self.appEvents.logEvent(
          .searched,
          valueToSum: 2,
          parameters: [:],
          accessToken: SampleAccessTokens.validToken
        )
      },
      {
        self.appEvents.logPurchase(
          amount: 2,
          currency: foo,
          parameters: [:]
        )
      },
      {
        self.appEvents.logPurchase(
          amount: 2,
          currency: foo,
          parameters: [:],
          accessToken: SampleAccessTokens.validToken
        )
      },
      { self.appEvents.logPushNotificationOpen(payload: [:]) },
      { self.appEvents.logPushNotificationOpen(payload: [:], action: foo) },
      {
        self.appEvents.logProductItem(
          id: foo,
          availability: .inStock,
          condition: .new,
          description: foo,
          imageLink: foo,
          link: foo,
          title: foo,
          priceAmount: 1,
          currency: foo,
          gtin: nil,
          mpn: nil,
          brand: nil,
          parameters: [:]
        )
      },
      { self.appEvents.setPushNotificationsDeviceToken(Data()) },
      { self.appEvents.pushNotificationsDeviceTokenString = foo },
      { self.appEvents.flush() },
      { self.appEvents.requestForCustomAudienceThirdPartyID(accessToken: SampleAccessTokens.validToken) },
      { self.appEvents.augmentHybridWebView(WKWebView()) },
      { self.appEvents.sendEventBindingsToUnity() },
      { self.appEvents.activateApp() },
      { _ = self.appEvents.userID },
      { self.appEvents.userID = foo },
    ]

    exceptionRaisingClosures.forEach { closure in
      assertRaisesException(
        message: "Interacting with AppEvents in some ways before initializing the SDK should raise an exception"
      ) {
        closure()
      }
    }

    let nonExceptionRaisingClosures = [
      { self.appEvents.setIsUnityInitialized(true) },
      { _ = self.appEvents.anonymousID },
      { self.appEvents.setUserData(foo, forType: .email) },
      {
        self.appEvents.setUser(
          email: nil,
          firstName: nil,
          lastName: nil,
          phone: nil,
          dateOfBirth: nil,
          gender: nil,
          city: nil,
          state: nil,
          zip: nil,
          country: nil
        )
      },
      { self.appEvents.getUserData() },
      { self.appEvents.clearUserData(forType: .email) },
    ]
    // swiftlint:enable opening_brace

    nonExceptionRaisingClosures.forEach { closure in
      assertDoesNotRaiseException(
        message: """
          Interacting with AppEvents in certain ways before the SDK is initialized \
          should not raise an exception
          """
      ) {
        closure()
      }
    }

    XCTAssertFalse(
      timeSpentRecorder.restoreWasCalled,
      "Activating App without initialized SDK cannot restore recording time spent data."
    )
    validateAEMReporterCalled(
      eventName: nil,
      currency: nil,
      value: nil,
      parameters: nil
    )
  }

  // swiftlint:enable opening_brace

  func testLogEventFilteringOutDeactivatedParameters() {
    let parameters: [AppEvents.ParameterName: String] = [.init("key"): "value"]
    appEvents.logEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: parameters,
      isImplicitlyLogged: false,
      accessToken: nil
    )
    XCTAssertEqual(
      eventDeactivationParameterProcessor.capturedEventName,
      eventName,
      "AppEvents instance should submit the event name to event deactivation parameters processor."
    )
    XCTAssertEqual(
      eventDeactivationParameterProcessor.capturedParameters as? [AppEvents.ParameterName: String],
      parameters,
      "AppEvents instance should submit the parameters to event deactivation parameters processor."
    )
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: purchaseAmount,
      parameters: parameters
    )
  }

  func testLogEventProcessParametersWithRestrictiveDataFilterParameterProcessor() {
    let parameters: [AppEvents.ParameterName: String] = [.init("key"): "value"]
    appEvents.logEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: parameters,
      isImplicitlyLogged: false,
      accessToken: nil
    )
    XCTAssertEqual(
      restrictiveDataFilterParameterProcessor.capturedEventName,
      eventName,
      "AppEvents instance should submit the event name to the restrictive data filter parameters processor."
    )
    XCTAssertEqual(
      restrictiveDataFilterParameterProcessor.capturedParameters as? [AppEvents.ParameterName: String],
      parameters,
      "AppEvents instance should submit the parameters to the restrictive data filter parameters processor."
    )
  }

  // MARK: - Test for log push notification

  func testLogPushNotificationOpen() throws {
    eventName = .init("fb_mobile_push_opened")

    let expectedAEMParameters: [AppEvents.ParameterName: String] = [
      .init("fb_push_action"): "testAction",
      .init("fb_push_campaign"): "testCampaign",
    ]

    appEvents.logPushNotificationOpen(payload: payload, action: "testAction")
    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertEqual(capturedParameters["fb_push_action"] as? String, "testAction")
    XCTAssertEqual(capturedParameters["fb_push_campaign"] as? String, "testCampaign")
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: nil,
      parameters: expectedAEMParameters
    )
  }

  func testLogPushNotificationOpenWithEmptyAction() throws {
    eventName = .init("fb_mobile_push_opened")

    appEvents.logPushNotificationOpen(payload: payload)

    let expectedAEMParameters: [AppEvents.ParameterName: String] = [
      .init("fb_push_campaign"): "testCampaign",
    ]

    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertNil(capturedParameters["fb_push_action"])
    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertEqual(capturedParameters["fb_push_campaign"] as? String, "testCampaign")
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: nil,
      parameters: expectedAEMParameters
    )
  }

  func testLogPushNotificationOpenWithEmptyPayload() {
    appEvents.logPushNotificationOpen(payload: [:])

    XCTAssertNil(appEventsStateProvider.state?.capturedEventDictionary)
  }

  func testLogPushNotificationOpenWithEmptyCampaign() {
    payload = ["fb_push_payload": ["campaign": ""]]
    appEvents.logPushNotificationOpen(payload: payload)

    XCTAssertNil(appEventsStateProvider.state?.capturedEventDictionary)
    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      .developerErrors,
      """
      A log entry of LoggingBehaviorDeveloperErrors should be posted if \
      logPushNotificationOpen is fed with empty campagin
      """
    )
  }

  func testSetFlushBehavior() {
    appEvents.flushBehavior = .auto
    XCTAssertEqual(.auto, appEvents.flushBehavior)

    appEvents.flushBehavior = .explicitOnly
    XCTAssertEqual(.explicitOnly, appEvents.flushBehavior)
  }

  func testCheckPersistedEventsCalledWhenLogEvent() {
    appEvents.logEvent(
      .purchased,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: [:],
      accessToken: nil
    )

    XCTAssertTrue(
      appEventsStateStore.retrievePersistedAppEventStatesWasCalled,
      "Should retrieve persisted states when logEvent was called and flush behavior was FlushReasonEagerlyFlushingEvent"
    )
    validateAEMReporterCalled(
      eventName: .purchased,
      currency: nil,
      value: purchaseAmount,
      parameters: [:]
    )
  }

  func testRequestForCustomAudienceThirdPartyIDWithTrackingDisallowed() {
    settings.advertisingTrackingStatus = .disallowed

    XCTAssertNil(
      appEvents.requestForCustomAudienceThirdPartyID(
        accessToken: SampleAccessTokens.validToken
      ),
      """
      Should not create a request for third party Any if tracking is disallowed \
      even if there is a current access token
      """
    )
    XCTAssertNil(
      appEvents.requestForCustomAudienceThirdPartyID(accessToken: nil),
      "Should not create a request for third party Any if tracking is disallowed"
    )
  }

  func testRequestForCustomAudienceThirdPartyIDWithLimitedEventAndDataUsage() {
    settings.isEventDataUsageLimited = true
    settings.advertisingTrackingStatus = .allowed

    XCTAssertNil(
      appEvents.requestForCustomAudienceThirdPartyID(
        accessToken: SampleAccessTokens.validToken
      ),
      """
      Should not create a request for third party Any if event and data usage is \
      limited even if there is a current access token
      """
    )
    XCTAssertNil(
      appEvents.requestForCustomAudienceThirdPartyID(accessToken: nil),
      "Should not create a request for third party Any if event and data usage is limited"
    )
  }

  func testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithoutAdvertiserID() {
    settings.isEventDataUsageLimited = false
    settings.advertisingTrackingStatus = .allowed

    XCTAssertNil(
      appEvents.requestForCustomAudienceThirdPartyID(accessToken: nil),
      "Should not create a request for third party Any if there is no access token or advertiser Any"
    )
  }

  func testRequestForCustomAudienceThirdPartyIDWithoutAccessTokenWithAdvertiserID() {
    let advertiserID = "abc123"
    settings.isEventDataUsageLimited = false
    settings.advertisingTrackingStatus = .allowed
    advertiserIDProvider.advertiserID = advertiserID

    appEvents.requestForCustomAudienceThirdPartyID(accessToken: nil)
    XCTAssertEqual(
      graphRequestFactory.capturedParameters as? [String: String],
      ["udid": advertiserID],
      "Should include the udid in the request when there is no access token available"
    )
  }

  func testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithoutAdvertiserID() {
    let token = SampleAccessTokens.validToken
    settings.isEventDataUsageLimited = false
    settings.advertisingTrackingStatus = .allowed
    appEventsUtility.stubbedTokenStringToUse = token.tokenString
    appEvents.loggingOverrideAppID = token.appID

    appEvents.requestForCustomAudienceThirdPartyID(accessToken: token)
    XCTAssertEqual(
      graphRequestFactory.capturedTokenString,
      token.tokenString,
      "Should include the access token in the request when there is one available"
    )
    XCTAssertNil(
      graphRequestFactory.capturedParameters["udid"],
      "Should not include the udid in the request when there is none available"
    )
  }

  func testRequestForCustomAudienceThirdPartyIDWithAccessTokenWithAdvertiserID() {
    let token = SampleAccessTokens.validToken
    appEvents.loggingOverrideAppID = token.appID
    let expectedGraphPath = "\(token.appID)/custom_audience_third_party_id"
    let advertiserID = "abc123"
    settings.isEventDataUsageLimited = false
    settings.advertisingTrackingStatus = .allowed
    advertiserIDProvider.advertiserID = advertiserID
    appEventsUtility.stubbedTokenStringToUse = token.tokenString

    appEvents.requestForCustomAudienceThirdPartyID(accessToken: token)

    XCTAssertEqual(
      graphRequestFactory.capturedTokenString,
      token.tokenString,
      "Should include the access token in the request when there is one available"
    )
    XCTAssertNil(
      graphRequestFactory.capturedParameters["udid"],
      "Should not include the udid in the request when there is an access token available"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      expectedGraphPath,
      "Should use the expected graph path for the request"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedHttpMethod,
      .get,
      "Should use the expected http method for the request"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedFlags,
      [.doNotInvalidateTokenOnError, .disableErrorRecovery],
      "Should use the expected flags for the request"
    )
  }

  func testPublishInstall() {
    appEvents.publishInstall()

    XCTAssertNotNil(
      appEventsConfigurationProvider.firstCapturedBlock,
      "Should fetch a configuration before publishing installs"
    )
  }

  // MARK: - Tests for Kill Switch

  func testAppEventsKillSwitchDisabled() throws {
    TestGateKeeperManager.setGateKeeperValue(key: "app_events_killswitch", value: false)

    appEvents.logEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: nil,
      isImplicitlyLogged: false,
      accessToken: nil
    )

    let state = try XCTUnwrap(appEventsStateProvider.state)
    XCTAssertTrue(
      state.isAddEventCalled,
      "Should add events to AppEventsState when killswitch is disabled"
    )
    XCTAssertFalse(
      state.capturedIsImplicit,
      "Shouldn't implicitly add events to AppEventsState when killswitch is disabled"
    )
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: purchaseAmount,
      parameters: nil
    )
  }

  func testAppEventsKillSwitchEnabled() throws {
    TestGateKeeperManager.setGateKeeperValue(key: "app_events_killswitch", value: true)

    appEvents.logEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: nil,
      isImplicitlyLogged: false,
      accessToken: nil
    )

    TestGateKeeperManager.setGateKeeperValue(key: "app_events_killswitch", value: false)

    XCTAssertNil(
      appEventsStateProvider.state,
      "Shouldn't add events to AppEventsState when killswitch is enabled"
    )

    validateAEMReporterCalled(
      eventName: nil,
      currency: nil,
      value: nil,
      parameters: nil
    )
  }

  // MARK: - Tests for log event

  func testLogEventWithValueToSum() throws {
    appEvents.logEvent(
      eventName,
      valueToSum: purchaseAmount
    )

    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertEqual(capturedParameters["_valueToSum"] as? Int, 1)
  }

  func testLogInternalEvents() throws {
    appEvents.logInternalEvent(
      eventName,
      isImplicitlyLogged: false
    )

    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertNil(capturedParameters["_valueToSum"])
    XCTAssertNil(capturedParameters["_implicitlyLogged"])

    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: nil,
      parameters: [:]
    )
  }

  func testLogInternalEventsWithValue() throws {
    appEvents.logInternalEvent(
      eventName,
      valueToSum: purchaseAmount,
      isImplicitlyLogged: false
    )

    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertEqual(capturedParameters["_valueToSum"] as? Double, purchaseAmount)
    XCTAssertNil(capturedParameters["_implicitlyLogged"])

    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: purchaseAmount,
      parameters: [:]
    )
  }

  func testLogInternalEventWithAccessToken() throws {
    appEvents.logInternalEvent(
      eventName,
      parameters: [:],
      isImplicitlyLogged: false,
      accessToken: SampleAccessTokens.validToken
    )

    XCTAssertEqual(appEventsStateProvider.capturedAppID, mockAppID)

    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertNil(capturedParameters["_valueToSum"])
    XCTAssertNil(capturedParameters["_implicitlyLogged"])

    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: nil,
      parameters: [:]
    )
  }

  func testLogEventWhenAutoLogAppEventsDisabled() {
    settings.isAutoLogAppEventsEnabled = false
    appEvents.logInternalEvent(
      eventName,
      valueToSum: purchaseAmount,
      isImplicitlyLogged: false
    )

    XCTAssertNil(appEventsStateProvider.state)
  }

  func testLogEventWhenEventsAreDropped() {
    appEventsUtility.shouldDropAppEvents = true
    settings.appID = "123"

    appEvents.logEvent(eventName)

    XCTAssertNil(
      appEventsStateProvider.state,
      "State should be nil when dropping app events"
    )
  }

  func testLogEventWhenEventsAreNotDropped() {
    appEventsUtility.shouldDropAppEvents = false
    settings.appID = "123"

    appEvents.logEvent(eventName)

    XCTAssertNotNil(
      appEventsStateProvider.state,
      "State should not be nil when not dropping app events"
    )
  }

  func testLogEventWillRecordAndUpdateWithSKAdNetworkReporter() {
    if #available(iOS 11.3, *) {
      appEvents.logEvent(eventName, valueToSum: purchaseAmount)
      XCTAssertEqual(
        eventName.rawValue,
        skAdNetworkReporter.capturedEvent,
        "Logging a event should invoke the SKAdNetwork reporter with the expected event name"
      )
      XCTAssertEqual(
        purchaseAmount,
        skAdNetworkReporter.capturedValue?.doubleValue,
        "Logging a event should invoke the SKAdNetwork reporter with the expected event value"
      )
    }
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: purchaseAmount,
      parameters: [:]
    )
  }

  func testLogImplicitEvent() throws {
    appEvents.logImplicitEvent(
      eventName,
      valueToSum: NSNumber(value: purchaseAmount),
      parameters: [:],
      accessToken: SampleAccessTokens.validToken
    )

    let capturedParameters = try XCTUnwrap(appEventsStateProvider.state?.capturedEventDictionary)

    XCTAssertEqual(capturedParameters["_eventName"] as? String, eventName.rawValue)
    XCTAssertEqual(capturedParameters["_valueToSum"] as? Double, purchaseAmount)
    XCTAssertEqual(capturedParameters["_implicitlyLogged"] as? String, "1")
    validateAEMReporterCalled(
      eventName: eventName,
      currency: nil,
      value: purchaseAmount,
      parameters: [:]
    )
  }

  // MARK: - ParameterProcessing

  func testLoggingEventWithoutIntegrityParametersProcessor() throws {
    onDeviceMLModelManager.integrityParametersProcessor = nil

    appEvents.logEvent(eventName, parameters: [.init("foo"): "bar"])

    let logEntry = try XCTUnwrap(TestLogger.capturedLogEntry)
    XCTAssertTrue(
      logEntry.contains("foo = bar"),
      "Should not try to use a nil processor to filter the parameters"
    )
  }

  func testLoggingEventWithIntegrityParametersProcessor() {
    let parameters = [AppEvents.ParameterName("foo"): "bar"]
    appEvents.logEvent(eventName, parameters: parameters)

    XCTAssertEqual(
      integrityParametersProcessor.capturedParameters as? [AppEvents.ParameterName: String],
      [.init("foo"): "bar"],
      "Should use the integrity parameters processor to filter the parameters"
    )
  }

  // MARK: - Test for Server Configuration

  func testFetchServerConfiguration() {
    let configuration = AppEventsConfiguration(json: [:])
    appEventsConfigurationProvider.stubbedConfiguration = configuration

    var didRunCallback = false
    appEvents.fetchServerConfiguration {
      didRunCallback = true
    }
    XCTAssertNotNil(
      appEventsConfigurationProvider.firstCapturedBlock,
      "The expected block should be captured by the AppEventsConfiguration provider"
    )
    appEventsConfigurationProvider.firstCapturedBlock?()
    XCTAssertNotNil(
      serverConfigurationProvider.capturedCompletionBlock,
      "The expected block should be captured by the ServerConfiguration provider"
    )
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    XCTAssertTrue(
      didRunCallback,
      "fetchServerConfiguration should call the callback block"
    )
  }

  func testFetchingConfigurationIncludingCertainFeatures() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)

    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.ateLogging),
      "fetchConfiguration should check if the ATELogging feature is enabled"
    )
    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.codelessEvents),
      "fetchConfiguration should check if CodelessEvents feature is enabled"
    )
  }

  func testEnablingCodelessEvents() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    let configuration = TestServerConfiguration(appID: name)
    configuration.stubbedIsCodelessEventsEnabled = true

    serverConfigurationProvider.capturedCompletionBlock?(configuration, nil)
    featureManager.completeCheck(forFeature: .codelessEvents, with: true)

    XCTAssertTrue(
      TestCodelessEvents.wasEnabledCalled,
      "Should enable codeless events when the feature is enabled and the server configuration allows it"
    )
  }

  func testFetchingConfigurationIncludingEventDeactivation() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.eventDeactivation),
      "Fetching a configuration should check if the EventDeactivation feature is enabled"
    )
  }

  func testFetchingConfigurationEnablingEventDeactivationParameterProcessorIfEventDeactivationEnabled() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    featureManager.completeCheck(forFeature: .eventDeactivation, with: true)
    XCTAssertTrue(
      eventDeactivationParameterProcessor.enableWasCalled,
      """
      Fetching a configuration should enable event deactivation parameters \
      processor if event deactivation feature is enabled
      """
    )
  }

  func testFetchingConfigurationIncludingRestrictiveDataFiltering() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.restrictiveDataFiltering),
      "Fetching a configuration should check if the RestrictiveDataFiltering feature is enabled"
    )
  }

  func testFetchingConfigurationEnablingRestrictiveDataFilterParameterProcessorIfRestrictiveDataFilteringEnabled() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    featureManager.completeCheck(forFeature: .restrictiveDataFiltering, with: true)
    XCTAssertTrue(
      restrictiveDataFilterParameterProcessor.enableWasCalled,
      """
      Fetching a configuration should enable restrictive data filter parameters \
      processor if event deactivation feature is enabled
      """
    )
  }

  func testFetchingConfigurationIncludingAAM() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.AAM),
      "Fetch a configuration should check if the AAM feature is enabled"
    )
  }

  func testFetchingConfigurationEnablingMetadataIndexigIfAAMEnabled() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    featureManager.completeCheck(forFeature: .AAM, with: true)
    XCTAssertTrue(
      metadataIndexer.enableWasCalled,
      "Fetching a configuration should enable metadata indexer if AAM feature is enabled"
    )
  }

  func testFetchingConfigurationStartsPaymentObservingIfConfigurationAllowed() {
    settings.isAutoLogAppEventsEnabled = true
    let serverConfiguration = ServerConfigurationFixtures.config(
      withDictionary: ["implicitPurchaseLoggingEnabled": true]
    )
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(serverConfiguration, nil)
    XCTAssertTrue(
      paymentObserver.didStartObservingTransactions,
      "fetchConfiguration should start payment observing if the configuration allows it"
    )
    XCTAssertFalse(
      paymentObserver.didStopObservingTransactions,
      "fetchConfiguration shouldn't stop payment observing if the configuration allows it"
    )
  }

  func testFetchingConfigurationStopsPaymentObservingIfConfigurationDisallowed() {
    settings.isAutoLogAppEventsEnabled = true
    let serverConfiguration = ServerConfigurationFixtures.config(withDictionary: ["implicitPurchaseLoggingEnabled": 0])
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(serverConfiguration, nil)
    XCTAssertFalse(
      paymentObserver.didStartObservingTransactions,
      "Fetching a configuration shouldn't start payment observing if the configuration disallows it"
    )
    XCTAssertTrue(
      paymentObserver.didStopObservingTransactions,
      "Fetching a configuration should stop payment observing if the configuration disallows it"
    )
  }

  func testFetchingConfigurationStopPaymentObservingIfAutoLogAppEventsDisabled() {
    settings.isAutoLogAppEventsEnabled = false
    let serverConfiguration = ServerConfigurationFixtures.config(
      withDictionary: ["implicitPurchaseLoggingEnabled": true]
    )
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(serverConfiguration, nil)
    XCTAssertFalse(
      paymentObserver.didStartObservingTransactions,
      "Fetching a configuration shouldn't start payment observing if auto log app events is disabled"
    )
    XCTAssertTrue(
      paymentObserver.didStopObservingTransactions,
      "Fetching a configuration should stop payment observing if auto log app events is disabled"
    )
  }

  func testFetchingConfigurationIncludingSKAdNetworkIfSKAdNetworkReportEnabled() {
    settings.isSKAdNetworkReportEnabled = true
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.skAdNetwork),
      "fetchConfiguration should check if the SKAdNetwork feature is enabled when SKAdNetworkReport is enabled"
    )
  }

  func testFetchingConfigurationEnablesSKAdNetworkReporterWhenSKAdNetworkReportAndConversionValueEnabled() {
    settings.isSKAdNetworkReportEnabled = true
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    if #available(iOS 11.3, *) {
      featureManager.completeCheck(
        forFeature: .skAdNetwork,
        with: true
      )
      featureManager.completeCheck(
        forFeature: .skAdNetworkConversionValue,
        with: true
      )
      XCTAssertTrue(
        skAdNetworkReporter.enableWasCalled,
        """
        Fetching a configuration should enable SKAdNetworkReporter when SKAdNetworkReport \
        and SKAdNetworkConversionValue are enabled
        """
      )
    }
  }

  func testFetchingConfigurationDoesNotEnableSKAdNetworkReporterWhenSKAdNetworkConversionValueIsDisabled() {
    settings.isSKAdNetworkReportEnabled = true
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    if #available(iOS 11.3, *) {
      featureManager.completeCheck(
        forFeature: .skAdNetwork,
        with: true
      )
      featureManager.completeCheck(
        forFeature: .skAdNetworkConversionValue,
        with: false
      )
      XCTAssertFalse(
        skAdNetworkReporter.enableWasCalled,
        "Fetching a configuration should NOT enable SKAdNetworkReporter if SKAdNetworkConversionValue is disabled"
      )
    }
  }

  func testFetchingConfigurationNotIncludingSKAdNetworkIfSKAdNetworkReportDisabled() {
    settings.isSKAdNetworkReportEnabled = false
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)

    XCTAssertFalse(
      featureManager.capturedFeaturesContains(.skAdNetwork),
      "fetchConfiguration should NOT check if the SKAdNetwork feature is disabled when SKAdNetworkReport is disabled"
    )
  }

  func testFetchingConfigurationIncludingAEM() {
    if #available(iOS 14.0, *) {
      appEvents.fetchServerConfiguration(nil)
      appEventsConfigurationProvider.firstCapturedBlock?()
      serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
      XCTAssertTrue(
        featureManager.capturedFeaturesContains(.AEM),
        "Fetching a configuration should check if the AEM feature is enabled"
      )
    }
  }

  func testFetchingConfigurationIncludingAEMConversionFiltering() {
    if #available(iOS 14.0, *) {
      featureManager.enable(feature: .aemConversionFiltering)
      appEvents.fetchServerConfiguration(nil)
      appEventsConfigurationProvider.firstCapturedBlock?()
      serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
      featureManager.completeCheck(
        forFeature: .AEM,
        with: true
      )
      XCTAssertTrue(
        TestAEMReporter.setCatalogMatchingEnabledWasCalled,
        "Should enable or disable the Conversion Filtering"
      )
      XCTAssertTrue(
        TestAEMReporter.capturedConversionFilteringEnabled,
        "AEM Conversion Filtering should be enabled"
      )
    }
  }

  func testFetchingConfigurationIncludingAEMCatalogMatching() {
    if #available(iOS 14.0, *) {
      featureManager.enable(feature: .aemCatalogMatching)
      appEvents.fetchServerConfiguration(nil)
      appEventsConfigurationProvider.firstCapturedBlock?()
      serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
      featureManager.completeCheck(
        forFeature: .AEM,
        with: true
      )
      XCTAssertTrue(
        TestAEMReporter.setCatalogMatchingEnabledWasCalled,
        "Should enable or disable the Catalog Matching"
      )
      XCTAssertTrue(
        TestAEMReporter.capturedCatalogMatchingEnabled,
        "AEM Catalog Matching should be enabled"
      )
    }
  }

  func testFetchingConfigurationIncludingPrivacyProtection() {
    appEvents.fetchServerConfiguration(nil)
    appEventsConfigurationProvider.firstCapturedBlock?()
    serverConfigurationProvider.capturedCompletionBlock?(nil, nil)
    XCTAssertTrue(
      featureManager.capturedFeaturesContains(.privacyProtection),
      "Fetching a configuration should check if the PrivacyProtection feature is enabled"
    )
    featureManager.completeCheck(
      forFeature: .privacyProtection,
      with: true
    )
    XCTAssertTrue(
      onDeviceMLModelManager.isEnabled,
      "Fetching a configuration should enable event processing if PrivacyProtection feature is enabled"
    )
  }

  // MARK: - Test for Singleton Values

  func testApplicationStateValues() {
    XCTAssertEqual(appEvents.applicationState, .inactive, "The default value of applicationState should be .inactive")
    appEvents.applicationState = .background
    XCTAssertEqual(
      appEvents.applicationState,
      .background,
      "The value of applicationState after calling setApplicationState should be .background"
    )
  }

  // MARK: - Source Application Tracking

  func testSetSourceApplicationOpenURL() {
    let url = URL(string: "www.example.com")
    appEvents.setSourceApplication(name, open: url)

    XCTAssertEqual(
      timeSpentRecorder.capturedSetSourceApplication,
      name,
      "Should behave as a proxy for tracking the source application"
    )
    XCTAssertEqual(
      timeSpentRecorder.capturedSetSourceApplicationURL,
      url,
      "Should behave as a proxy for tracking the opened URL"
    )
  }

  func testSetSourceApplicationFromAppLink() {
    appEvents.setSourceApplication(name, isFromAppLink: true)

    XCTAssertEqual(
      timeSpentRecorder.capturedSetSourceApplicationFromAppLink,
      name,
      "Should behave as a proxy for tracking the source application"
    )
    XCTAssertTrue(
      timeSpentRecorder.capturedIsFromAppLink,
      "Should behave as a proxy for tracking whether the source application came from an app link"
    )
  }

  func testRegisterAutoResetSourceApplication() {
    appEvents.registerAutoResetSourceApplication()

    XCTAssertTrue(
      timeSpentRecorder.wasRegisterAutoResetSourceApplicationCalled,
      "Should have the source application tracker register for auto resetting"
    )
  }

  func registerAutoResetSourceApplication() {
    timeSpentRecorder.registerAutoResetSourceApplication()
  }

  // MARK: - Helpers

  private func validateAEMReporterCalled(
    eventName: AppEvents.Name?,
    currency: String?,
    value: Double?,
    parameters: [AppEvents.ParameterName: String]?
  ) {
    XCTAssertEqual(
      TestAEMReporter.capturedEvent,
      eventName?.rawValue,
      "Should invoke the AEM reporter with the expected event name"
    )
    XCTAssertEqual(
      TestAEMReporter.capturedCurrency,
      currency,
      "Should invoke the AEM reporter with the correct currency inferred from the parameters"
    )
    XCTAssertEqual(
      TestAEMReporter.capturedValue?.doubleValue,
      value,
      "Should invoke the AEM reporter with the expected value"
    )
    XCTAssertEqual(
      TestAEMReporter.capturedParameters as? [String: String],
      convertParameters(parameters),
      "Should invoke the AEM reporter with the expected parameters"
    )
  }

  private func convertParameters(_ potentialParameters: [AppEvents.ParameterName: String]?) -> [String: String]? {
    guard let parameters = potentialParameters else { return nil }

    return .init(
      uniqueKeysWithValues: parameters.map {
        ($0.key.rawValue, $0.value)
      }
    )
  }
}
