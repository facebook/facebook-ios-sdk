/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class AppEventsStateTests: XCTestCase {

  let appEventsStateMaxEvents = 1000
  let appId = "appid"
  let eventsProcessor = TestAppEventsParameterProcessor()
  let blocklistEventsManager = TestBlocklistEventsManager()
  let redactedEventsManager = TestRedactedEventsManager()
  lazy var state = _AppEventsState(token: self.name, appID: appId)
  lazy var partiallyFullState = _AppEventsState(
    token: self.name,
    appID: appId
  )
  lazy var fullState = _AppEventsState(token: self.name, appID: appId)

  override func setUp() {
    super.setUp()

    setUpFixtures()
    _AppEventsState.eventProcessors = [eventsProcessor, blocklistEventsManager, redactedEventsManager]
  }

  func setUpFixtures(
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    XCTAssertEqual(
      0,
      state.events.count,
      "sanity check",
      file: file,
      line: line
    )
    partiallyFullState.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: nil)
    XCTAssertEqual(
      1,
      partiallyFullState.events.count,
      "sanity check",
      file: file,
      line: line
    )
    for _ in 0 ..< appEventsStateMaxEvents {
      fullState.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: nil)
    }

    XCTAssertEqual(
      appEventsStateMaxEvents,
      fullState.events.count,
      "sanity check",
      file: file,
      line: line
    )
  }

  func testDefaults() {
    XCTAssertEqual(
      0,
      state.events.count,
      "Should have no events by default"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Should have no skipped events by default"
    )
    XCTAssertTrue(
      state.areAllEventsImplicit,
      "Should consider all events to be implicit when there are no events"
    )
  }

  func testCreatingWithNilTokenNilAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: nil, appID: nil),
      "Should not create app events state with missing token and app id but you can"
    )
  }

  func testCreatingWithNilTokenInvalidAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: nil, appID: ""),
      "Should not create app events state with missing token and empty app id but you can"
    )
    XCTAssertNotNil(
      _AppEventsState(token: nil, appID: "  "),
      "Should not create app events state with missing token and whitespace only app id but you can"
    )
  }

  func testCreatingWithNilTokenValidAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: nil, appID: appId),
      "Should not create app events state with missing token and valid app id but you can"
    )
  }

  func testCreatingWithInvalidTokenNilAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: "", appID: nil),
      "Should not create app events state with empty token and missing app id but you can"
    )
    XCTAssertNotNil(
      _AppEventsState(token: "  ", appID: nil),
      "Should not create app events state with whitespace only token and missing app id but you can"
    )
  }

  func testCreatingWithInvalidTokenInvalidAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: "", appID: ""),
      "Should not create app events state with invalid token and invalid app id but you can"
    )
  }

  func testCreatingWithInvalidTokenValidAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: "", appID: appId),
      "Should not create app events state with empty token and valid app id but you can"
    )
    XCTAssertNotNil(
      _AppEventsState(token: "   ", appID: appId),
      "Should not create app events state with whitespace only token and valid app id but you can"
    )
  }

  func testCreatingWithValidTokenNilAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: name, appID: nil),
      "Should not create app events state with valid token and missing app id but you can"
    )
  }

  func testCreatingWithValidTokenInvalidAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: name, appID: ""),
      "Should not create app events state with valid token and empty app id but you can"
    )
    XCTAssertNotNil(
      _AppEventsState(token: name, appID: "   "),
      "Should not create app events state with valid token and whitespace only app id but you can"
    )
  }

  func testCreatingWithValidTokenValidAppID() {
    XCTAssertNotNil(
      _AppEventsState(token: name, appID: appId),
      "Should be able to create app events state with valid token and app id"
    )
  }

  // MARK: - Adding Events

  func testAddingDuplicateEvents() {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)

    XCTAssertEqual(
      2,
      state.events.count,
      "Should be able to add duplicate events"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Should not skip valid events"
    )
  }

  func testAddingSingleImplicitEvent() {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    XCTAssertEqual(
      1,
      state.events.count,
      "Should be able to add a valid event"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Should not skip valid events"
    )
    XCTAssertTrue(
      state.areAllEventsImplicit,
      "Should consider all events to be implicit when all events were added as implicit"
    )
  }

  func testAddingMultipleImplicitEvents() {
    state.addEvent(
      SampleAppEvents.validEvent,
      isImplicit: true,
      withOperationalParameters: nil
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: true,
      withOperationalParameters: nil
    )

    XCTAssertEqual(2, state.events.count, "Should be able to add a valid event")
    XCTAssertEqual(0, state.numSkipped, "Should not skip valid events")
    XCTAssertTrue(
      state.areAllEventsImplicit,
      "Should not consider all events to be implicit when no events were added as implicit"
    )
  }

  func testAddingSingleNonImplicitEvents() {
    state.addEvent(
      SampleAppEvents.validEvent,
      isImplicit: false,
      withOperationalParameters: nil
    )

    XCTAssertEqual(1, state.events.count, "Should be able to add a valid event")
    XCTAssertEqual(0, state.numSkipped, "Should not skip valid events")
    XCTAssertFalse(
      state.areAllEventsImplicit,
      "Should not consider all events to be implicit when no events were added as implicit"
    )
  }

  func testAddingMultipleNonImplicitEvents() {
    state.addEvent(
      SampleAppEvents.validEvent,
      isImplicit: false,
      withOperationalParameters: nil
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: false,
      withOperationalParameters: nil
    )
    XCTAssertEqual(2, state.events.count, "Should be able to add a valid event")
    XCTAssertEqual(0, state.numSkipped, "Should not skip valid events")
    XCTAssertFalse(
      state.areAllEventsImplicit,
      "Should not consider all events to be implicit when no events were added as implicit"
    )
  }

  func testAddingMixtureOfImplicitNonImplicitEvents() {
    state.addEvent(
      SampleAppEvents.validEvent,
      isImplicit: true,
      withOperationalParameters: nil
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: false,
      withOperationalParameters: nil
    )
    XCTAssertEqual(2, state.events.count, "Should be able to add a valid event")
    XCTAssertEqual(0, state.numSkipped, "Should not skip valid events")
    XCTAssertFalse(
      state.areAllEventsImplicit,
      "Should not consider all events to be implicit when no events were added as implicit"
    )
  }

  func testAddingEventsWithOperationalParameters() {
    let operationalParametersOne: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.transactionID.rawValue: "1",
      ],
    ]
    let operationalParametersTwo: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.productTitle.rawValue: "Product",
      ],
    ]
    state.addEvent(
      SampleAppEvents.validEvent,
      isImplicit: true,
      withOperationalParameters: operationalParametersOne
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: false,
      withOperationalParameters: operationalParametersTwo
    )
    XCTAssertEqual(2, state.events.count, "Should be able to add a valid event with operational parameters")
    guard let eventOneOperationalParameters =
      state.events.first?["operationalParameters"] as? [AppOperationalDataType: [String: Any]] else {
      XCTFail("Should have operational parameters")
      return
    }
    guard let eventTwoOperationalParameters =
      state.events.last?["operationalParameters"] as? [AppOperationalDataType: [String: Any]] else {
      XCTFail("Should have operational parameters")
      return
    }
    XCTAssertTrue(NSDictionary(dictionary: operationalParametersOne).isEqual(to: eventOneOperationalParameters))
    XCTAssertTrue(NSDictionary(dictionary: operationalParametersTwo).isEqual(to: eventTwoOperationalParameters))
  }

  func testAddingEventAtMaxCapacity() {
    fullState.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: nil)
    fullState.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: nil)
    XCTAssertEqual(
      2,
      fullState.numSkipped,
      "Should skip any events added after the max size is reached"
    )
  }

  // MARK: - Events from AppEventState

  func testAddingEventsToStateWithOperationalParameters() {
    let testState = _AppEventsState(token: name, appID: appId)
    let operationalParameters: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.transactionID.rawValue: "1",
      ],
    ]
    testState.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: operationalParameters)
    partiallyFullState.addEvents(fromAppEventState: testState)
    XCTAssertEqual(
      2,
      partiallyFullState.events.count,
      "Should succesfully add events from another state"
    )
    guard let operationalParametersFromTestState =
      partiallyFullState.events.last?["operationalParameters"] as? [AppOperationalDataType: [String: Any]] else {
      XCTFail("Should have operational parameters")
      return
    }
    XCTAssertTrue(NSDictionary(dictionary: operationalParametersFromTestState).isEqual(to: operationalParameters))
  }

  func testAddingEventsToDuplicateEvents() {
    partiallyFullState.addEvents(fromAppEventState: partiallyFullState)
    XCTAssertEqual(
      2,
      partiallyFullState.events.count,
      "Duplicate event states should not be addable but they are"
    )
    XCTAssertEqual(
      0,
      partiallyFullState.numSkipped,
      "Duplicate event states should not be addable but they are"
    )
  }

  func testAddingEventsFromEmptyStateToEmptyState() {
    let state2 = _AppEventsState(token: name, appID: appId)
    state.addEvents(fromAppEventState: state2)
    XCTAssertEqual(
      0,
      state.events.count,
      "Duplicate event states should not be addable but they are"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Duplicate event states should not be addable but they are"
    )
  }

  func testAddEventsFromFullStateToEmptyState() {
    state.addEvents(fromAppEventState: fullState)
    XCTAssertEqual(
      appEventsStateMaxEvents,
      state.events.count,
      "Should add all the events from the other state"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Should not skip events when there is room in the state to hold them"
    )
  }

  func testAddEventsFromEmptyStateToPartiallyFilledState() {
    let emptyState = _AppEventsState(token: name, appID: appId)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    state.addEvents(fromAppEventState: emptyState)

    XCTAssertEqual(
      1,
      state.events.count,
      "Adding an empty state to a partially filled state should have no effect"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Adding an empty state to a partially filled state should have no effect"
    )
  }

  func testAddEventsFromPartiallyFilledStateToEmptyState() {
    state.addEvents(fromAppEventState: partiallyFullState)
    XCTAssertEqual(
      1,
      state.events.count,
      "Should add all the events in the partially filled state to the empty state"
    )
    XCTAssertEqual(
      0,
      state.numSkipped,
      "Adding a partially filled state to an empty state should have no effect"
    )
  }

  func testAddEventsFromPartiallyFilledStateToFullState() {
    fullState.addEvents(fromAppEventState: partiallyFullState)
    XCTAssertEqual(
      appEventsStateMaxEvents,
      fullState.events.count,
      "Adding to a full state should have no effect on the event count"
    )
    XCTAssertEqual(
      1,
      fullState.numSkipped,
      "Should skip events in excess of a state's capacity"
    )
  }

  func testAddEventsFromFullStateToPartiallyFilledState() {
    partiallyFullState.addEvents(fromAppEventState: fullState)
    XCTAssertEqual(
      appEventsStateMaxEvents,
      partiallyFullState.events.count,
      "Adding a full state to a partially filled state should add as many events as possible"
    )
    XCTAssertEqual(
      1,
      partiallyFullState.numSkipped,
      "Should skip events in excess of a state's capacity"
    )
  }

  func testAddEventsFromFullStateToFullState() {
    let otherFullState = _AppEventsState(token: name, appID: appId)

    for _ in 0 ..< (appEventsStateMaxEvents * 2) {
      otherFullState.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: nil)
    }

    fullState.addEvents(fromAppEventState: otherFullState)

    XCTAssertEqual(
      appEventsStateMaxEvents,
      fullState.events.count,
      "Should not add additional events to a full state"
    )
    XCTAssertEqual(
      appEventsStateMaxEvents,
      fullState.events.count,
      "Adding to a full state should have no effect on the event count"
    )
  }

  func testAddEventsToPreviouslyOverflownState() {
    // Fills
    state.addEvents(fromAppEventState: fullState)
    // Overflows
    state.addEvents(fromAppEventState: fullState)
    // Double overflows
    state.addEvents(fromAppEventState: fullState)

    XCTAssertEqual(
      2000, // appEventsStateMaxEvents * 2
      state.numSkipped,
      "Should keep a running count of skipped states"
    )
    XCTAssertEqual(
      appEventsStateMaxEvents,
      state.events.count,
      "Should not add additional events to a full state"
    )
  }

  func testCompatibilityWithMatchingTokenMatchingAppID() {
    let state2 = _AppEventsState(token: name, appID: appId)
    XCTAssertTrue(
      state.is(compatibleWith: state2),
      "States with matching tokens and matching app ids should be compatible"
    )
  }

  func testMatchingTokenNonMatchingAppID() {
    let state2 = _AppEventsState(token: name, appID: name)
    XCTAssertFalse(
      state.is(compatibleWith: state2),
      "States with matching tokens and non-matching app ids should not be compatible"
    )
  }

  func testNonMatchingTokenMatchingAppID() {
    let state2 = _AppEventsState(token: appId, appID: appId)
    XCTAssertFalse(
      state.is(compatibleWith: state2),
      "States with matching non-matching tokens and matching app ids should not be compatible"
    )
  }

  func testNonMatchingTokenNonMatchingAppID() {
    let state2 = _AppEventsState(token: appId, appID: name)
    XCTAssertFalse(
      state.is(compatibleWith: state2),
      "States with matching non-matching tokens and non matching app ids should not be compatible"
    )
  }

  func testNilTokensMatchingAppID() {
    let state1 = _AppEventsState(token: nil, appID: name)
    let state2 = _AppEventsState(token: nil, appID: name)
    XCTAssertTrue(
      state1.is(compatibleWith: state2),
      "States with nil tokens and matching app ids should be compatible"
    )
  }

  func testNilTokensNonMatchingAppID() {
    let state1 = _AppEventsState(token: nil, appID: appId)
    let state2 = _AppEventsState(token: nil, appID: name)
    XCTAssertFalse(
      state1.is(compatibleWith: state2),
      "States with nil tokens and matching app ids should be compatible"
    )
  }

  // MARK: - Extract Receipt Data

  func testExtractReceiptData() {
    state.addEvent(["receipt_data": "some_data"], isImplicit: false, withOperationalParameters: nil)
    let extracted = state.extractReceiptData()
    XCTAssertTrue(extracted == "receipt_1::some_data;;;")
  }

  // MARK: - JSONString For Events

  func testJSONStringForEventsWithNoEvents() throws {
    let json = state.jsonStringForEventsAndOperationalParameters(includingImplicitEvents: true)
    let eventsJson = json["custom_events"]
    let operationalParametersJson = json["operational_parameters"]
    let expected = try BasicUtility.jsonString(for: [], invalidObjectHandler: nil)
    XCTAssertEqual(
      eventsJson,
      expected,
      "Should represent events as empty json array when there are no events"
    )
    XCTAssertEqual(
      operationalParametersJson,
      expected,
      "Should represent operational params as empty json array when there are no events"
    )
  }

  func testJSONStringForEventsIncludingImplicitEvents() throws {
    let operationalParameters: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.transactionID.rawValue: "1",
      ],
    ]
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: operationalParameters)
    let json = state.jsonStringForEventsAndOperationalParameters(includingImplicitEvents: true)
    let eventsJson = json["custom_events"]
    let operationalParametersJson = json["operational_parameters"]
    let expectedEventsJson = try BasicUtility.jsonString(
      for: [SampleAppEvents.validEvent, SampleAppEvents.validEvent],
      invalidObjectHandler: nil
    )
    let expectedOperationalParametersJson = try BasicUtility.jsonString(
      for: [[:], operationalParameters],
      invalidObjectHandler: nil
    )
    XCTAssertEqual(
      eventsJson,
      expectedEventsJson,
      "Should represent events correctly"
    )
    XCTAssertEqual(
      operationalParametersJson,
      expectedOperationalParametersJson,
      "Should represent operational parameters correctly"
    )
  }

  func testJSONStringForEventsExcludingImplicitEvents() throws {
    let operationalParameters: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.transactionID.rawValue: "1",
      ],
    ]
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: operationalParameters)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: false, withOperationalParameters: operationalParameters)
    let json = state.jsonStringForEventsAndOperationalParameters(includingImplicitEvents: false)
    let eventsJson = json["custom_events"]
    let operationalParametersJson = json["operational_parameters"]
    let expectedEventsJson = try BasicUtility.jsonString(
      for: [SampleAppEvents.validEvent],
      invalidObjectHandler: nil
    )
    let expectedOperationalParametersJson = try BasicUtility.jsonString(
      for: [operationalParameters],
      invalidObjectHandler: nil
    )
    XCTAssertEqual(
      eventsJson,
      expectedEventsJson,
      "Should represent events correctly"
    )
    XCTAssertEqual(
      operationalParametersJson,
      expectedOperationalParametersJson,
      "Should represent operational parameters correctly"
    )
  }

  func testJSONStringForEventsIncludingImplicitEventsWithOperationalParameters() throws {
    let operationalParametersOne: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.productTitle.rawValue: "Product Title",
      ],
    ]
    let operationalParametersTwo: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.transactionID.rawValue: "1",
      ],
    ]
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: operationalParametersOne)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: operationalParametersTwo)
    let json = state.jsonStringForEventsAndOperationalParameters(includingImplicitEvents: true)
    let eventsJson = json["custom_events"]
    let operationalParametersJson = json["operational_parameters"]
    let expectedEventsJson = try BasicUtility.jsonString(
      for: [SampleAppEvents.validEvent, SampleAppEvents.validEvent],
      invalidObjectHandler: nil
    )
    let expectedOperationalParametersJson = try BasicUtility.jsonString(
      for: [operationalParametersOne, operationalParametersTwo],
      invalidObjectHandler: nil
    )
    XCTAssertEqual(
      eventsJson,
      expectedEventsJson,
      "Should represent events correctly"
    )
    XCTAssertEqual(
      operationalParametersJson,
      expectedOperationalParametersJson,
      "Should represent operational parameters correctly"
    )
  }

  func testJSONStringForEventsIncludingImplicitEventsWithNoOperationalParameters() throws {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    let json = state.jsonStringForEventsAndOperationalParameters(includingImplicitEvents: true)
    let eventsJson = json["custom_events"]
    let operationalParametersJson = json["operational_parameters"]
    let expectedEventsJson = try BasicUtility.jsonString(
      for: [SampleAppEvents.validEvent, SampleAppEvents.validEvent],
      invalidObjectHandler: nil
    )
    let expectedOperationalParametersJson = try BasicUtility.jsonString(
      for: [[:], [:]],
      invalidObjectHandler: nil
    )
    XCTAssertEqual(
      eventsJson,
      expectedEventsJson,
      "Should represent events correctly"
    )
    XCTAssertEqual(
      operationalParametersJson,
      expectedOperationalParametersJson,
      "Should represent operational parameters correctly"
    )
  }

  func testJSONStringForEventsSubmitEventsToProcessors() {
    fullState.jsonStringForEventsAndOperationalParameters(includingImplicitEvents: true)
    XCTAssertEqual(
      fullState.events.count,
      eventsProcessor.capturedEvents?.count,
      "Should submit events to event processors"
    )
    XCTAssertTrue(
      blocklistEventsManager.processEventsWasCalled,
      "Blocklist events manager should process events"
    )
    XCTAssertTrue(
      redactedEventsManager.processEventsWasCalled,
      "Redacted events manager should process events"
    )
  }
}
