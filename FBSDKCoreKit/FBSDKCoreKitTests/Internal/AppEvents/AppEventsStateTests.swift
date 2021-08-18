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

class AppEventsStateTests: XCTestCase {

  let appEventsStateMaxEvents = 1000
  let appId = "appid"
  let eventsProcessor = TestAppEventsParameterProcessor()
  lazy var state = AppEventsState(token: self.name, appID: appId)! // swiftlint:disable:this force_unwrapping
  lazy var partiallyFullState = AppEventsState(
    token: self.name,
    appID: appId
  )! // swiftlint:disable:this force_unwrapping
  lazy var fullState = AppEventsState(token: self.name, appID: appId)! // swiftlint:disable:this force_unwrapping

  override func setUp() {
    super.setUp()

    setUpFixtures()
    AppEventsState.configure(withEventProcessors: [eventsProcessor])
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
    partiallyFullState.addEvent(SampleAppEvents.validEvent, isImplicit: false)
    XCTAssertEqual(
      1,
      partiallyFullState.events.count,
      "sanity check",
      file: file,
      line: line
    )
    for _ in 0..<appEventsStateMaxEvents {
      fullState.addEvent(SampleAppEvents.validEvent, isImplicit: false)
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
      AppEventsState(token: nil, appID: nil),
      "Should not create app events state with missing token and app id but you can"
    )
  }

  func testCreatingWithNilTokenInvalidAppID() {
    XCTAssertNotNil(
      AppEventsState(token: nil, appID: ""),
      "Should not create app events state with missing token and empty app id but you can"
    )
    XCTAssertNotNil(
      AppEventsState(token: nil, appID: "  "),
      "Should not create app events state with missing token and whitespace only app id but you can"
    )
  }

  func testCreatingWithNilTokenValidAppID() {
    XCTAssertNotNil(
      AppEventsState(token: nil, appID: appId),
      "Should not create app events state with missing token and valid app id but you can"
    )
  }

  func testCreatingWithInvalidTokenNilAppID() {
    XCTAssertNotNil(
      AppEventsState(token: "", appID: nil),
      "Should not create app events state with empty token and missing app id but you can"
    )
    XCTAssertNotNil(
      AppEventsState(token: "  ", appID: nil),
      "Should not create app events state with whitespace only token and missing app id but you can"
    )
  }

  func testCreatingWithInvalidTokenInvalidAppID() {
    XCTAssertNotNil(
      AppEventsState(token: "", appID: ""),
      "Should not create app events state with invalid token and invalid app id but you can"
    )
  }

  func testCreatingWithInvalidTokenValidAppID() {
    XCTAssertNotNil(
      AppEventsState(token: "", appID: appId),
      "Should not create app events state with empty token and valid app id but you can"
    )
    XCTAssertNotNil(
      AppEventsState(token: "   ", appID: appId),
      "Should not create app events state with whitespace only token and valid app id but you can"
    )
  }

  func testCreatingWithValidTokenNilAppID() {
    XCTAssertNotNil(
      AppEventsState(token: self.name, appID: nil),
      "Should not create app events state with valid token and missing app id but you can"
    )
  }

  func testCreatingWithValidTokenInvalidAppID() {
    XCTAssertNotNil(
      AppEventsState(token: self.name, appID: ""),
      "Should not create app events state with valid token and empty app id but you can"
    )
    XCTAssertNotNil(
      AppEventsState(token: self.name, appID: "   "),
      "Should not create app events state with valid token and whitespace only app id but you can"
    )
  }

  func testCreatingWithValidTokenValidAppID() {
    XCTAssertNotNil(
      AppEventsState(token: self.name, appID: appId),
      "Should be able to create app events state with valid token and app id"
    )
  }

  // MARK: - Adding Events

  func testAddingDuplicateEvents() {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)

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
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
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
      isImplicit: true
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: true
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
      isImplicit: false
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
      isImplicit: false
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: false
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
      isImplicit: true
    )
    state.addEvent(
      SampleAppEvents.validEvent(withName: "event2"),
      isImplicit: false
    )
    XCTAssertEqual(2, state.events.count, "Should be able to add a valid event")
    XCTAssertEqual(0, state.numSkipped, "Should not skip valid events")
    XCTAssertFalse(
      state.areAllEventsImplicit,
      "Should not consider all events to be implicit when no events were added as implicit"
    )
  }

  func testAddingEventAtMaxCapacity() {
    fullState.addEvent(SampleAppEvents.validEvent, isImplicit: false)
    fullState.addEvent(SampleAppEvents.validEvent, isImplicit: false)
    XCTAssertEqual(
      2,
      fullState.numSkipped,
      "Should skip any events added after the max size is reached"
    )
  }

  // MARK: - Events from AppEventState

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
    let state2 = AppEventsState(token: self.name, appID: appId)
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
    let emptyState = AppEventsState(token: self.name, appID: appId)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
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
    let otherFullState = AppEventsState(token: name, appID: appId)

    for _ in 0..<(appEventsStateMaxEvents * 2) {
      otherFullState?.addEvent(SampleAppEvents.validEvent, isImplicit: false)
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
    let state2 = AppEventsState(token: self.name, appID: appId)
    XCTAssertTrue(
      state.is(compatibleWith: state2),
      "States with matching tokens and matching app ids should be compatible"
    )
  }

  func testMatchingTokenNonMatchingAppID() {
    let state2 = AppEventsState(token: self.name, appID: self.name)
    XCTAssertFalse(
      state.is(compatibleWith: state2),
      "States with matching tokens and non-matching app ids should not be compatible"
    )
  }

  func testNonMatchingTokenMatchingAppID() {
    let state2 = AppEventsState(token: appId, appID: appId)
    XCTAssertFalse(
      state.is(compatibleWith: state2),
      "States with matching non-matching tokens and matching app ids should not be compatible"
    )
  }

  func testNonMatchingTokenNonMatchingAppID() {
    let state2 = AppEventsState(token: appId, appID: self.name)
    XCTAssertFalse(
      state.is(compatibleWith: state2),
      "States with matching non-matching tokens and non matching app ids should not be compatible"
    )
  }

  func testNilTokensMatchingAppID() {
    let state1 = AppEventsState(token: nil, appID: self.name)! // swiftlint:disable:this force_unwrapping
    let state2 = AppEventsState(token: nil, appID: self.name)
    XCTAssertTrue(
      state1.is(compatibleWith: state2),
      "States with nil tokens and matching app ids should be compatible"
    )
  }

  func testNilTokensNonMatchingAppID() {
    let state1 = AppEventsState(token: nil, appID: appId)! // swiftlint:disable:this force_unwrapping
    let state2 = AppEventsState(token: nil, appID: self.name)
    XCTAssertFalse(
      state1.is(compatibleWith: state2),
      "States with nil tokens and matching app ids should be compatible"
    )
  }

  // MARK: - Extract Receipt Data

  func testExtractReceiptData() {
    state.addEvent(["receipt_data": "some_data"], isImplicit: false)
    let extracted = state.extractReceiptData()
    XCTAssertTrue(extracted == "receipt_1::some_data;;;")
  }

  // MARK: - JSONString For Events

  func testJSONStringForEventsWithNoEvents() throws {
    let json = state.jsonStringForEvents(includingImplicitEvents: true)
    let expected = try BasicUtility.jsonString(for: [], invalidObjectHandler: nil)
    XCTAssertEqual(
      json,
      expected,
      "Should represent events as empty json array when there are no events"
    )
  }

  func testJSONStringForEventsIncludingImplicitEvents() throws {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
    let json = state.jsonStringForEvents(includingImplicitEvents: true)
    let expected = try BasicUtility.jsonString(
      for: [SampleAppEvents.validEvent, SampleAppEvents.validEvent],
      invalidObjectHandler: nil
    )
    XCTAssertEqual(
      json,
      expected,
      "Should represent events as empty json array when there are events"
    )
  }

  func testJSONStringForEventsExcludingImplicitEvents() throws {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
    state.addEvent(SampleAppEvents.validEvent, isImplicit: false)
    let json = state.jsonStringForEvents(includingImplicitEvents: false)
    let expected = try BasicUtility.jsonString(
      for: [SampleAppEvents.validEvent],
      invalidObjectHandler: nil
    )
    XCTAssertEqual(
      json,
      expected,
      "Should represent events as empty json array when there are events"
    )
  }

  func testJSONStringForEventsSubmitEventsToProcessors() {
    fullState.jsonStringForEvents(includingImplicitEvents: true)
    XCTAssertEqual(
      fullState.events.count,
      eventsProcessor.capturedEvents?.count,
      "Should submit events to event processors"
    )
  }
} // swiftlint:disable:this file_length
