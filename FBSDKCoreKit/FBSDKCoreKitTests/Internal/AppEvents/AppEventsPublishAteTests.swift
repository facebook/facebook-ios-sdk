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
      graphRequestProvider: TestGraphRequestFactory(),
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
      advertiserIDProvider: TestAdvertiserIDProvider()
    )

    appEvents.publishATE()
    XCTAssertTrue(
      publisher.publishAteWasCalled,
      "App events should use the ATE publisher created by the configure method"
    )
  }
}
