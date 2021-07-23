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

// swiftlint:disable type_body_length implicitly_unwrapped_optional
class SuggestedEventsIndexerTests: XCTestCase, UITableViewDelegate, UICollectionViewDelegate {

  let requestProvider = TestGraphRequestFactory()
  let settings = TestSettings()
  let eventLogger = TestEventLogger()
  var eventProcessor: TestOnDeviceMLModelManager! = TestOnDeviceMLModelManager()
  let collectionView = TestCollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewFlowLayout()
  )
  let tableView = TestTableView()
  let button = UIButton()
  var indexer: SuggestedEventsIndexer!

  enum Keys {
    static let productionEvents = "production_events"
    static let predictionEvents = "eligible_for_prediction_events"
    static let setting = "suggestedEventsSetting"
    static let eventName = "event_name"
    static let metadata = "metadata"
    static let buttonText = "button_text"
    static let eventButtonText = "_button_text"
    static let dense = "dense"
    static let isSuggestedEvent = "_is_suggested_event"
  }

  enum Values {
    static let optInEvents = ["foo", "bar", "baz"]
    static let unconfirmedEvents = optInEvents.map { $0 + "1" }
    static let buttonText = "Purchase"
    static let denseFeature = "1,2,3"
    static let processedEvent = "purchase"
  }

  override func setUp() {
    super.setUp()

    SuggestedEventsIndexerTests.reset()

    settings.appID = name

    indexer = SuggestedEventsIndexer(
      requestProvider: requestProvider,
      serverConfigurationProvider: TestServerConfigurationProvider.self,
      swizzler: TestSwizzler.self,
      settings: settings,
      eventLogger: eventLogger,
      featureExtractor: TestFeatureExtractor.self,
      eventProcessor: eventProcessor
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
    SuggestedEventsIndexer.reset()
  }

  // MARK: - Delegate methods

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}

  // MARK: - Dependencies

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
    XCTAssertEqual(
      ObjectIdentifier(indexer.eventLogger),
      ObjectIdentifier(AppEvents.singleton),
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
      indexer.eventProcessor is TestOnDeviceMLModelManager,
      "Should be able to create an instance with a custom event processor"
    )
  }

  func testEventProcessorIsWeaklyHeld() {
    eventProcessor = nil

    XCTAssertNil(
      indexer.eventProcessor,
      "Should not hold a strong reference to the event processor"
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
    enable(error: SampleError())

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
    enable()

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
    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: Values.unconfirmedEvents,
      error: SampleError()
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

  func testCompletingEnablingWithSuggestedEventsSetting() {
    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: Values.unconfirmedEvents
    )

    XCTAssertEqual(
      indexer.optInEvents,
      Set(Values.optInEvents),
      "Should set up suggested events successfully"
    )
    XCTAssertEqual(
      indexer.unconfirmedEvents,
      Set(Values.unconfirmedEvents),
      "Should set up suggested events successfully"
    )
  }

  func testEnablingWithSuggestedEventsSettingInvokesSetup() {
    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: Values.unconfirmedEvents
    )

    let expected = [
      SwizzleEvidence(
        selector: #selector(UIControl.didMoveToWindow),
        class: UIControl.self
      ),
      SwizzleEvidence(
        selector: #selector(setter: UITableView.delegate),
        class: UITableView.self
      ),
      SwizzleEvidence(
        selector: #selector(setter: UICollectionView.delegate),
        class: UICollectionView.self
      )
    ]
    XCTAssertEqual(
      TestSwizzler.evidence,
      expected,
      "Should swizzle the expected methods as part of setup"
    )
  }

  func testEnablingOnlySwizzlesOnce() {
    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: Values.unconfirmedEvents
    )

    TestSwizzler.reset()

    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: Values.unconfirmedEvents
    )

    XCTAssertEqual(
      TestSwizzler.evidence,
      [],
      "Enabling should only setup and swizzle methods once"
    )
  }

  // MARK: - Logging Suggested Event

  func testLoggingEventWithoutDenseFeature() {
    indexer.logSuggestedEvent(
      name,
      text: Values.buttonText,
      denseFeature: nil
    )

    XCTAssertNil(
      requestProvider.capturedGraphPath,
      "Should not create a request if there is no dense feature"
    )
  }

  func testLoggingEventWithDenseFeature() {
    indexer.logSuggestedEvent(
      name,
      text: Values.buttonText,
      denseFeature: Values.denseFeature
    )

    let expectedMetadata = [Keys.dense: Values.denseFeature, Keys.buttonText: Values.buttonText]
    guard let parameter = requestProvider.capturedParameters[Keys.metadata] as? String,
          let data = parameter.data(using: .utf8),
          let decodedMetadata = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
    else {
      return XCTFail("Should capture the metadata in the parameters")
    }

    XCTAssertEqual(
      requestProvider.capturedGraphPath,
      "\(name)/suggested_events",
      "Should use the app identifier from the settings"
    )
    XCTAssertEqual(
      requestProvider.capturedParameters[Keys.eventName] as? String,
      name,
      "Should capture the event name in the parameters"
    )
    XCTAssertEqual(
      decodedMetadata,
      expectedMetadata,
      "Should request the expected metadata"
    )
    XCTAssertNil(
      requestProvider.capturedTokenString,
      "The request should be tokenless"
    )
    XCTAssertEqual(
      requestProvider.capturedHttpMethod,
      .post,
      "Should use the expected http method"
    )
    XCTAssertTrue(
      requestProvider.capturedFlags.isEmpty,
      "Should not create the request with explicit request flags"
    )
  }

  // MARK: - Predicting Events

  func testPredictingEventWithTooMuchText() {
    indexer.predictEvent(
      with: UIResponder(),
      text: String(describing: Array(repeating: "A", count: 101))
    )

    XCTAssertEqual(
      eventProcessor.processSuggestedEventsCallCount,
      0,
      "Should not ask the event processor to process events if the text is too long"
    )
    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log an event if the text is too long"
    )
    XCTAssertNil(
      requestProvider.capturedGraphPath,
      "Should not create a request if the text is too long"
    )
  }

  func testPredictingEventWithEmptyText() {
    indexer.predictEvent(with: UIResponder(), text: "")

    XCTAssertEqual(
      eventProcessor.processSuggestedEventsCallCount,
      0,
      "Should not ask the event processor to process events if the text is empty"
    )
    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log an event if the text is empty"
    )
    XCTAssertNil(
      requestProvider.capturedGraphPath,
      "Should not create a request if the text is empty"
    )
  }

  func testPredictingEventWithSensitiveText() {
    indexer.predictEvent(with: UIResponder(), text: "me@example.com")

    XCTAssertEqual(
      eventProcessor.processSuggestedEventsCallCount,
      0,
      "Should not ask the event processor to process events if the text is sensitive"
    )
    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log an event if the text is sensitive"
    )
    XCTAssertNil(
      requestProvider.capturedGraphPath,
      "Should not create a request if the text is sensitive"
    )
  }

  func testPredictingEventWithoutEventProcessor() {
    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log if there is no event processor to process events"
    )
    XCTAssertNil(
      requestProvider.capturedGraphPath,
      "Should not create a request if there is no event processor to process events"
    )
  }

  // | has processed event | processed event matches optin event | matches unconfirmed event |
  // | no                  | n/a                                 | n/a                       |
  func testPredictingWithoutProcessedEvents() {
    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertEqual(
      eventProcessor.processSuggestedEventsCallCount,
      1,
      "Should ask the event processor to process events"
    )
    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log if there are no processed events from the event processor"
    )
  }

  // | has processed event | processed event matches optin event | matches unconfirmed event |
  // | yes                 | no                                  | no                        |
  func testPredictingWithProcessedEventsMatchingNone() {
    eventProcessor.stubbedProcessedEvents = Values.processedEvent

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertEqual(
      eventProcessor.processSuggestedEventsCallCount,
      1,
      "Should ask the event processor to process events"
    )
    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log if there are no processed events from the event processor"
    )
  }

  // | has processed event | processed event matches optin event | matches unconfirmed event |
  // | yes                 | yes                                 | no                        |
  func testPredictingWithProcessedEventsMatchingOptinEvent() {
    eventProcessor.stubbedProcessedEvents = Values.processedEvent

    enable(
      optInEvents: [Values.processedEvent],
      unconfirmedEvents: Values.unconfirmedEvents
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      Values.processedEvent,
      "Should log an opt-in event with the expected event name"
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [String: String],
      [
        Keys.isSuggestedEvent: "1",
        Keys.eventButtonText: Values.buttonText
      ],
      "Should log an opt-in event with the expected parameters"
    )
  }

  // | processed event | matches optin | matches unconfirmed | dense data |
  // | yes             | no            | yes                 | null       |
  func testPredictingWithProcessedEventMatchingUnconfirmedEventWithoutDenseData() {
    eventProcessor.stubbedProcessedEvents = Values.processedEvent

    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: [Values.processedEvent]
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log unconfirmed events"
    )
    XCTAssertNil(
      requestProvider.capturedGraphPath,
      "Should not create a request if there is no dense data"
    )
  }

  // | processed event | matches optin | matches unconfirmed | dense data |
  // | yes             | no            | yes                 | non-null   |
  func testPredictingWithProcessedEventMatchingUnconfirmedEvent() {
    let denseData: [Float] = [1.0, 2.0, 3.0]
    let pointer = UnsafeMutablePointer<Float>.allocate(capacity: denseData.count)

    TestFeatureExtractor.stub(denseFeatures: pointer)
    eventProcessor.stubbedProcessedEvents = Values.processedEvent

    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: [Values.processedEvent]
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log unconfirmed events"
    )
    XCTAssertEqual(
      requestProvider.capturedGraphPath,
      "\(name)/suggested_events",
      "Should create a request for an unconfirmed event when there is dense data"
    )
  }

  // | has processed event | processed event matches optin event | matches unconfirmed event |
  // | yes                 | yes                                 | yes                       |
  func testPredictingWithProcessedEventMatchingBoth() {
    eventProcessor.stubbedProcessedEvents = Values.processedEvent

    enable(
      optInEvents: [Values.processedEvent],
      unconfirmedEvents: [Values.processedEvent]
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      Values.processedEvent,
      "Should log an opt-in event with the expected event name"
    )
    XCTAssertNil(
      requestProvider.capturedGraphPath,
      """
      Should not create a request when there are matching unconfirmed events if
      there are also matching opt-in events
      """
    )
  }

  // MARK: - View Matching and Handling

  func testMatchingMissingView() {
    indexer.matchSubviews(in: nil)

    XCTAssertTrue(
      TestSwizzler.evidence.isEmpty,
      "Should not swizzle views that don't exist"
    )
  }

  func testMatchingDirectSubviews() {
    let view = TestView()
    tableView.delegate = self
    collectionView.delegate = self
    view.addSubview(tableView)
    view.addSubview(collectionView)
    view.addSubview(button)

    indexer.matchSubviews(in: view)

    assertSwizzlesTableViewDelegate()
    assertSwizzlesCollectionViewDelegate()
    assertAddsTargetToButton()
  }

  func testMatchingNestedSubviews() {
    let view = TestView()
    tableView.delegate = self
    collectionView.delegate = self
    let secondLayerView = TestView()
    let thirdLayerView = TestView()
    let thirdLayerView2 = TestView()
    view.addSubview(secondLayerView)
    secondLayerView.addSubview(button)
    secondLayerView.addSubview(thirdLayerView)
    secondLayerView.addSubview(thirdLayerView2)
    thirdLayerView.addSubview(tableView)
    thirdLayerView2.addSubview(collectionView)

    indexer.matchSubviews(in: view)

    assertSwizzlesTableViewDelegate()
    assertSwizzlesCollectionViewDelegate()
    assertAddsTargetToButton()
  }

  func testMatchingSubviewsNestedInControls() {
    let view = TestView()
    tableView.delegate = self
    collectionView.delegate = self
    let control = UIControl()
    view.addSubview(control)
    control.addSubview(button)
    control.addSubview(tableView)
    control.addSubview(collectionView)

    TestSwizzler.reset()

    indexer.matchSubviews(in: view)

    XCTAssertEqual(
      TestSwizzler.evidence,
      [],
      "Should not match views nested in controls"
    )
    XCTAssertTrue(
      button.allTargets.isEmpty,
      "Should not match views nested in controls"
    )
  }

  func testHandlingTableViewWithMissingDelegate() {
    indexer.handle(tableView, withDelegate: nil)

    XCTAssertTrue(
      TestSwizzler.evidence.isEmpty,
      "Should not swizzle a table view delegate method if no delegate is provided"
    )
  }

  func testHandlingTableViewWithDelegate() {
    indexer.handle(tableView, withDelegate: self)

    assertSwizzlesTableViewDelegate()
  }

  func testHandlingCollectionViewWithMissingDelegate() {
    indexer.handle(collectionView, withDelegate: nil)

    XCTAssertTrue(
      TestSwizzler.evidence.isEmpty,
      "Should not swizzle a collection view delegate method if no delegate is provided"
    )
  }

  func testHandlingCollectionViewWithDelegate() {
    indexer.handle(collectionView, withDelegate: self)

    assertSwizzlesCollectionViewDelegate()
  }

  // MARK: - Helpers

  /// Calls enable and invokes the captured server configuration completion with the
  /// provided opt-in / unconfirmed events and error
  func enable(
    optInEvents: [String]? = nil,
    unconfirmedEvents: [String]? = nil,
    error: Error? = nil
  ) {
    let setting = indexerSetting(
      optInEvents: optInEvents,
      unconfirmedEvents: unconfirmedEvents
    )
    indexer.enable()
    TestServerConfigurationProvider.capturedCompletionBlock?(
      ServerConfigurationFixtures.config(withDictionary: setting),
      error
    )
  }

  func indexerSetting(
    optInEvents: [String]?,
    unconfirmedEvents: [String]?
  ) -> [String: Any] {
    var events = [String: Any]()

    if let productionEvents = optInEvents {
      events[Keys.productionEvents] = productionEvents
    }
    if let predictionEvents = unconfirmedEvents {
      events[Keys.predictionEvents] = predictionEvents
    }

    return events.isEmpty ? [:] : [Keys.setting: events]
  }

  func assertSwizzlesTableViewDelegate(
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let expected = SwizzleEvidence(
      selector: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:)),
      class: SuggestedEventsIndexerTests.self
    )
    XCTAssertTrue(
      TestSwizzler.evidence.contains(expected),
      "Should swizzle the expected table view delegate method",
      file: file,
      line: line
    )
  }

  func assertSwizzlesCollectionViewDelegate(
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let expected = SwizzleEvidence(
      selector: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)),
      class: SuggestedEventsIndexerTests.self
    )
    XCTAssertTrue(
      TestSwizzler.evidence.contains(expected),
      "Should swizzle the expected collection view delegate method",
      file: file,
      line: line
    )
  }

  func assertAddsTargetToButton(
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertEqual(
      button.allTargets.first as? SuggestedEventsIndexer,
      indexer,
      "Indexer should add itself as a target of the button",
      file: file,
      line: line
    )
  }
} // swiftlint:disable:this file_length
