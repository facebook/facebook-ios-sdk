/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class SuggestedEventsIndexerTests: XCTestCase, UITableViewDelegate, UICollectionViewDelegate {

  // swiftlint:disable implicitly_unwrapped_optional
  var graphRequestFactory: TestGraphRequestFactory!
  var settings: TestSettings!
  var eventLogger: TestEventLogger!
  var eventProcessor: TestOnDeviceMLModelManager!
  var serverConfigurationProvider: TestServerConfigurationProvider!
  var collectionView: TestCollectionView!
  var tableView: TestTableView!
  var button: UIButton!
  var indexer: SuggestedEventsIndexer!
  // swiftlint:enable implicitly_unwrapped_optional

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
  }

  enum AppEventNames {
    static let processedEvent = AppEvents.Name("purchase")
  }

  override func setUp() {
    super.setUp()

    Self.reset()

    graphRequestFactory = TestGraphRequestFactory()
    settings = TestSettings()
    settings.appID = name
    eventLogger = TestEventLogger()
    eventProcessor = TestOnDeviceMLModelManager()
    serverConfigurationProvider = TestServerConfigurationProvider()
    collectionView = TestCollectionView(
      frame: .zero,
      collectionViewLayout: UICollectionViewFlowLayout()
    )
    tableView = TestTableView()
    button = UIButton()
    indexer = SuggestedEventsIndexer(
      graphRequestFactory: graphRequestFactory,
      serverConfigurationProvider: serverConfigurationProvider,
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

  override func tearDown() {
    graphRequestFactory = nil
    settings = nil
    eventLogger = nil
    eventProcessor = nil
    serverConfigurationProvider = nil
    collectionView = nil
    tableView = nil
    button = nil
    indexer = nil

    super.tearDown()
  }

  static func reset() {
    TestSwizzler.reset()
    TestFeatureExtractor.reset()
    SuggestedEventsIndexer.reset()
  }

  // MARK: - Delegate methods

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {}

  // MARK: - Dependencies

  func testCustomDependencies() {
    XCTAssertTrue(
      indexer.graphRequestFactory is TestGraphRequestFactory,
      "Should be able to create an instance with a custom request provider"
    )
    XCTAssertTrue(
      indexer.serverConfigurationProvider is TestServerConfigurationProvider,
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
      serverConfigurationProvider.loadServerConfigurationWasCalled,
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
      ),
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
      AppEvents.Name(name),
      text: Values.buttonText,
      denseFeature: nil
    )

    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create a request if there is no dense feature"
    )
  }

  func testLoggingEventWithDenseFeature() {
    indexer.logSuggestedEvent(
      AppEvents.Name(name),
      text: Values.buttonText,
      denseFeature: Values.denseFeature
    )

    let expectedMetadata = [Keys.dense: Values.denseFeature, Keys.buttonText: Values.buttonText]
    guard
      let parameter = graphRequestFactory.capturedParameters[Keys.metadata] as? String,
      let data = parameter.data(using: .utf8),
      let decodedMetadata = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
    else {
      return XCTFail("Should capture the metadata in the parameters")
    }

    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      "\(name)/suggested_events",
      "Should use the app identifier from the settings"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedParameters[Keys.eventName] as? String,
      name,
      "Should capture the event name in the parameters"
    )
    XCTAssertEqual(
      decodedMetadata,
      expectedMetadata,
      "Should request the expected metadata"
    )
    XCTAssertNil(
      graphRequestFactory.capturedTokenString,
      "The request should be tokenless"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedHttpMethod,
      .post,
      "Should use the expected http method"
    )
    XCTAssertTrue(
      graphRequestFactory.capturedFlags.isEmpty,
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
      graphRequestFactory.capturedGraphPath,
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
      graphRequestFactory.capturedGraphPath,
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
      graphRequestFactory.capturedGraphPath,
      "Should not create a request if the text is sensitive"
    )
  }

  func testPredictingEventWithProcessedEventOther() {
    eventProcessor.stubbedProcessedEvents = "other"
    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log if the processed event is 'other'"
    )
    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not log a suggested event if the processed event is 'other'"
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
    eventProcessor.stubbedProcessedEvents = AppEventNames.processedEvent.rawValue

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
    eventProcessor.stubbedProcessedEvents = AppEventNames.processedEvent.rawValue

    enable(
      optInEvents: [AppEventNames.processedEvent.rawValue],
      unconfirmedEvents: Values.unconfirmedEvents
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEventNames.processedEvent,
      "Should log an opt-in event with the expected event name"
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [AppEvents.ParameterName: String],
      [
        .init(Keys.isSuggestedEvent): "1",
        .init(Keys.eventButtonText): Values.buttonText,
      ],
      "Should log an opt-in event with the expected parameters"
    )
  }

  // | processed event | matches optin | matches unconfirmed | dense data |
  // | yes             | no            | yes                 | null       |
  func testPredictingWithProcessedEventMatchingUnconfirmedEventWithoutDenseData() {
    eventProcessor.stubbedProcessedEvents = AppEventNames.processedEvent.rawValue

    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: [AppEventNames.processedEvent.rawValue]
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log unconfirmed events"
    )
    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create a request if there is no dense data"
    )
  }

  // | processed event | matches optin | matches unconfirmed | dense data |
  // | yes             | no            | yes                 | non-null   |
  func testPredictingWithProcessedEventMatchingUnconfirmedEvent() {
    let denseData: [Float] = [1.0, 2.0, 3.0]
    let pointer = UnsafeMutablePointer<Float>.allocate(capacity: denseData.count)

    TestFeatureExtractor.stub(denseFeatures: pointer)
    eventProcessor.stubbedProcessedEvents = AppEventNames.processedEvent.rawValue

    enable(
      optInEvents: Values.optInEvents,
      unconfirmedEvents: [AppEventNames.processedEvent.rawValue]
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertNil(
      eventLogger.capturedEventName,
      "Should not log unconfirmed events"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedGraphPath,
      "\(name)/suggested_events",
      "Should create a request for an unconfirmed event when there is dense data"
    )
  }

  // | has processed event | processed event matches optin event | matches unconfirmed event |
  // | yes                 | yes                                 | yes                       |
  func testPredictingWithProcessedEventMatchingBoth() {
    eventProcessor.stubbedProcessedEvents = AppEventNames.processedEvent.rawValue

    enable(
      optInEvents: [AppEventNames.processedEvent.rawValue],
      unconfirmedEvents: [AppEventNames.processedEvent.rawValue]
    )

    indexer.predictEvent(with: UIResponder(), text: Values.buttonText)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEventNames.processedEvent,
      "Should log an opt-in event with the expected event name"
    )
    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
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
    serverConfigurationProvider.capturedCompletionBlock?(
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
      class: Self.self
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
      class: Self.self
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
}
