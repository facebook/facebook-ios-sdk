/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

class AppEventsPublishATETests: XCTestCase {

  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    AppEvents.setSettings(settings)
  }

  func testDefaultAppEventsATEPublisher() {
    settings.appID = name

    let appEvents = AppEvents(flushBehavior: .auto, flushPeriodInSeconds: 15)

    XCTAssertNil(
      appEvents.atePublisher,
      "App events should be provided with an ATE publisher on initialization"
    )
  }

  func testPublishingATEWithoutPublisher() {
    let appEvents = AppEvents(flushBehavior: .explicitOnly, flushPeriodInSeconds: 0)

    // checking that there is no crash
    appEvents.publishATE()
  }

  func testPublishingATEAgainAfterSettingAppID() {
    let publisher = TestATEPublisher()
    let factory = TestATEPublisherFactory()
    factory.stubbedPublisher = publisher
    let appEvents = AppEvents(flushBehavior: .explicitOnly, flushPeriodInSeconds: 0)
    appEvents.publishATE()

    XCTAssertFalse(
      publisher.publishATEWasCalled,
      "App events Should not invoke the ATE publisher when there is not App ID"
    )

    settings.appID = name

    appEvents.configure(
      withGateKeeperManager: TestGateKeeperManager.self,
      appEventsConfigurationProvider: TestAppEventsConfigurationProvider(),
      serverConfigurationProvider: TestServerConfigurationProvider(),
      graphRequestFactory: TestGraphRequestFactory(),
      featureChecker: TestFeatureManager(),
      store: UserDefaultsSpy(),
      logger: TestLogger.self,
      settings: self.settings,
      paymentObserver: TestPaymentObserver(),
      timeSpentRecorderFactory: TestTimeSpentRecorderFactory(),
      appEventsStateStore: TestAppEventsStateStore(),
      eventDeactivationParameterProcessor: TestAppEventsParameterProcessor(),
      restrictiveDataFilterParameterProcessor: TestAppEventsParameterProcessor(),
      atePublisherFactory: factory,
      appEventsStateProvider: TestAppEventsStateProvider(),
      swizzler: TestSwizzler.self,
      advertiserIDProvider: TestAdvertiserIDProvider(),
      userDataStore: TestUserDataStore()
    )

    appEvents.publishATE()
    XCTAssertTrue(
      publisher.publishATEWasCalled,
      "App events should use the ATE publisher created by the configure method"
    )
  }
}
