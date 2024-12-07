/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class AppEventsStateManagerTests: XCTestCase {
  private let token = "token"
  private let appID = "1234"
  private var manager = _AppEventsStateManager()
  private lazy var state = _AppEventsState(token: token, appID: appID)

  override func tearDown() {
    super.tearDown()
    manager.clearPersistedAppEventsStates()
  }

  func testPersistingValidStateWithNoOperationalParameters() throws {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    manager.persistAppEventsData(state)

    let retrievedStates = manager.retrievePersistedAppEventsStates()
    let retrievedState = try XCTUnwrap(retrievedStates.first, "No state has been retrieved")

    XCTAssertEqual(
      retrievedState.tokenString,
      token,
      "The retrieved state should have the token same as the state that is persisted before."
    )
    XCTAssertEqual(
      retrievedState.appID,
      appID,
      "The retrieved state should have the app id same as the state that is persisted before."
    )
    XCTAssertEqual(
      retrievedState.events.count,
      1,
      "The retrieved state should contain one event like the state that is persisted before."
    )
  }

  func testPersistingValidStateWithOperationalParameters() throws {
    let validOperationalParameters: [AppOperationalDataType: [String: Any]] = [
      .iapParameters: [
        AppEvents.ParameterName.transactionID.rawValue: "1",
      ],
    ]
    let validEvent = SampleAppEvents.validEvent
    state.addEvent(validEvent, isImplicit: true, withOperationalParameters: validOperationalParameters)
    manager.persistAppEventsData(state)

    let retrievedStates = manager.retrievePersistedAppEventsStates()
    let retrievedState = try XCTUnwrap(retrievedStates.first, "No state has been retrieved")

    XCTAssertEqual(
      retrievedState.tokenString,
      token,
      "The retrieved state should have the token same as the state that is persisted before."
    )
    XCTAssertEqual(
      retrievedState.appID,
      appID,
      "The retrieved state should have the app id same as the state that is persisted before."
    )
    XCTAssertEqual(
      retrievedState.events.count,
      1,
      "The retrieved state should contain one event like the state that is persisted before."
    )
    guard let event = retrievedState.events.first?["event"] as? [String: Any] else {
      XCTFail("Should have an event")
      return
    }
    guard let operationalParameters =
      retrievedState.events.first?["operationalParameters"] as? [AppOperationalDataType: [String: Any]] else {
      XCTFail("Should have operational parameters")
      return
    }
    let eventName = event["_eventName"] as? String
    XCTAssertEqual(eventName, validEvent["_eventName"])
    XCTAssertTrue(NSDictionary(dictionary: operationalParameters).isEqual(to: validOperationalParameters))
  }

  func testClearStates() {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true, withOperationalParameters: nil)
    manager.persistAppEventsData(state)
    manager.clearPersistedAppEventsStates()
    let retrievedStatesAgain = manager.retrievePersistedAppEventsStates()
    XCTAssertEqual(
      retrievedStatesAgain.count,
      0,
      "The retrieved state list should be empty after clearing."
    )
  }

  func testPersistingInvalidState() {
    manager.persistAppEventsData(state)

    let retrievedStates = manager.retrievePersistedAppEventsStates()
    XCTAssertEqual(
      retrievedStates.count,
      0,
      "The retrieved state list should be empty when only one invalid state is persisted."
    )
  }
}
