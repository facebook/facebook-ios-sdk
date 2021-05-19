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

class FBSDKAppEventsStateManagerTests: XCTestCase {
  private let token = "token"
  private let appID = "1234"
  private var state: AppEventsState! // swiftlint:disable:this implicitly_unwrapped_optional
  private var manager: AppEventsStateManager!  // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    state = AppEventsState(token: token, appID: appID)
    manager = AppEventsStateManager()
  }

  override func tearDown() {
    super.tearDown()
    manager.clearPersistedAppEventsStates()
  }

  func testPersistingValidState() {
    state.addEvent(SampleAppEvents.validEvent, isImplicit: true)
    manager.persistAppEventsData(state)

    let retrievedStates = manager.retrievePersistedAppEventsStates()
    guard let retrievedState = retrievedStates[0] as? AppEventsState else {
      XCTFail("The retrieved state is not an AppEventState object.")
      return
    }

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
