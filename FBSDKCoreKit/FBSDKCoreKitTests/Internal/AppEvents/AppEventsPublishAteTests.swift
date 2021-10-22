/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

class AppEventsPublishAteTests: XCTestCase {

  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    AppEvents.setSettings(settings)
  }

  func testDefaultAppEventsAtePublisher() {
    settings.appID = name

    let appEvents = AppEvents(flushBehavior: .auto, flushPeriodInSeconds: 15)

    XCTAssertNil(
      appEvents.atePublisher,
      "App events should be provided with an ATE publisher on initialization"
    )
  }

  func testPublishingAteWithoutPublisher() {
    let appEvents = AppEvents(flushBehavior: .explicitOnly, flushPeriodInSeconds: 0)

    // checking that there is no crash
    appEvents.publishATE()
  }

  func testPublishingAteAgainAfterSettingAppID() {
    let publisher = TestAtePublisher()
    let factory = TestAtePublisherFactory()
    factory.stubbedPublisher = publisher
    let appEvents = AppEvents(flushBehavior: .explicitOnly, flushPeriodInSeconds: 0)
    appEvents.publishATE()

    XCTAssertFalse(
      publisher.publishAteWasCalled,
      "App events Should not invoke the ATE publisher when there is not App ID"
    )

    settings.appID = name

    appEvents.configure(
      withGateKeeperManager: TestGateKeeperManager.self,
      appEventsConfigurationProvider: TestAppEventsConfigurationProvider.self,
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
      publisher.publishAteWasCalled,
      "App events should use the ATE publisher created by the configure method"
    )
  }
}
