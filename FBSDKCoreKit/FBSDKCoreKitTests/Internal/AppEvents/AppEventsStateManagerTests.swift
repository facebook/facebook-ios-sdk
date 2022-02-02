/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class AppEventsStateManagerTests: XCTestCase {
  private let token = "token"
  private let appID = "1234"
  private var manager = AppEventsStateManager()
  private lazy var state = AppEventsState(token: token, appID: appID)

  override func tearDown() {
    super.tearDown()
    manager.clearPersistedAppEventsStates()
  }

  func testPersistingValidState() throws {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
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

  func testClearStates() {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
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
