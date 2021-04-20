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

import XCTest

class SuggestedEventsIndexerTests: XCTestCase {

  let requestProvider = TestGraphRequestFactory()
  let settings = TestSettings()
  let eventLogger = TestEventLogger()
  var eventProcessor: EventProcessing? = TestEventProcessor()
  var indexer: SuggestedEventsIndexer! // swiftlint:disable:this implicitly_unwrapped_optional

  enum Keys {
    static let productionEvents = "production_events"
    static let predictionEvents = "eligible_for_prediction_events"
    static let setting = "suggestedEventsSetting"
  }

  enum Values {
    static let productionEvents = ["foo", "bar", "baz"]
    static let predictionEvents = productionEvents.map { return $0 + "1" }
  }

  override func setUp() {
    super.setUp()

    SuggestedEventsIndexerTests.reset()

    indexer = SuggestedEventsIndexer(
      requestProvider: requestProvider,
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      swizzler: TestSwizzler.self,
      settings: settings,
      eventLogger: eventLogger,
      featureExtractor: TestFeatureExtractor.self,
      eventProcessor: eventProcessor! // swiftlint:disable:this force_unwrapping
    )
  }

  override class func tearDown() {
    super.tearDown()

    reset()
  }

  static func reset() {
    TestServerConfigurationProvider.reset()
    TestSwizzler.reset()
    TestFeatureExtractor.reset()
  }

  func testDefaultDependencies() {
    indexer = SuggestedEventsIndexer()

    XCTAssertTrue(
      indexer.requestProvider is GraphRequestFactory,
      "Should have a request provider of the expected default type"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider is ServerConfigurationManager.Type,
      "Should have a server configuration manager of the expected default type"
    )
    XCTAssertTrue(
      indexer.swizzler is Swizzler.Type,
      "Should have a swizzler of the expected default type"
    )
    XCTAssertTrue(
      indexer.settings is Settings,
      "Should have a settings of the expected default type"
    )
    XCTAssertTrue(
      indexer.eventLogger is EventLogger,
      "Should have an event logger of the expected default type"
    )
    XCTAssertTrue(
      indexer.eventProcessor is ModelManager,
      "Should have an event processor of the expected default type"
    )
  }

  func testCustomDependencies() {
    XCTAssertTrue(
      indexer.requestProvider is TestGraphRequestFactory,
      "Should be able to create an instance with a custom request provider"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider is TestServerConfigurationProvider.Type,
      "Should be able to create an instance with a custom server configuration provider"
    )
    XCTAssertTrue(
      indexer.swizzler is TestSwizzler.Type,
      "Should be able to create an instance with a custom swizzer"
    )
    XCTAssertTrue(
      indexer.settings is TestSettings,
      "Should be able to create an instance with a custom settings"
    )
    XCTAssertTrue(
      indexer.eventLogger is TestEventLogger,
      "Should be able to create an instance with a custom event logger"
    )
    XCTAssertTrue(
      indexer.eventProcessor is TestEventProcessor,
      "Should be able to create an instance with a custom event processor"
    )
  }

  func testEventProcessorIsWeaklyHeld() {
    eventProcessor = nil

    XCTAssertNil(
      indexer.eventProcessor,
      "Should not hold a strong reference to the delegate"
    )
  }

  // MARK: - Enabling

  func testEnablingLoadsServerConfiguration() {
    indexer.enable()

    XCTAssertTrue(
      TestServerConfigurationProvider.loadServerConfigurationWasCalled,
      "Enabling should load a server configuration"
    )
  }

  func testCompletingEnablingWithErrorOnly() {
    indexer.enable()

    TestServerConfigurationProvider.capturedCompletionBlock?(nil, SampleError())

    XCTAssertTrue(
      indexer.optInEvents.isEmpty,
      "Should not set events if there is an error fetching the server configuration"
    )
    XCTAssertTrue(
      indexer.unconfirmedEvents.isEmpty,
      "Should not set events if there is an error fetching the server configuration"
    )
  }

  func testCompletingEnablingWithEmptySuggestedEventsSetting() {
    indexer.enable()

    TestServerConfigurationProvider.capturedCompletionBlock?(
      ServerConfigurationFixtures.defaultConfig(),
      nil
    )

    XCTAssertTrue(
      indexer.optInEvents.isEmpty,
      "Should not set events if there is no suggested events setting in the server configuration"
    )
    XCTAssertTrue(
      indexer.unconfirmedEvents.isEmpty,
      "Should not set events if there is no suggested events setting in the server configuration"
    )
  }

  func testCompletingEnablingWithSuggestedEventsSettingAndError() {
    indexer.enable()

    TestServerConfigurationProvider.capturedCompletionBlock?(
      ServerConfigurationFixtures.config(with: validSetting),
      SampleError()
    )

    XCTAssertTrue(
      indexer.optInEvents.isEmpty,
      "Should not set events if there is an error fetching the server configuration"
    )
    XCTAssertTrue(
      indexer.unconfirmedEvents.isEmpty,
      "Should not set events if there is an error fetching the server configuration"
    )
  }

  func testCompletingEnablingWithNonRepeatingSuggestedEventsSetting() {
    indexer.enable()

    TestServerConfigurationProvider.capturedCompletionBlock?(
      ServerConfigurationFixtures.config(with: validSetting),
      nil
    )

    XCTAssertEqual(
      indexer.optInEvents,
      Set(Values.productionEvents),
      "Should set up suggested events successfully"
    )
    XCTAssertEqual(
      indexer.unconfirmedEvents,
      Set(Values.predictionEvents),
      "Should set up suggested events successfully"
    )
  }

  let validSetting: [String: Any] = [
    Keys.setting: [
      Keys.productionEvents: Values.productionEvents,
      Keys.predictionEvents: Values.predictionEvents
    ]
  ]
}
