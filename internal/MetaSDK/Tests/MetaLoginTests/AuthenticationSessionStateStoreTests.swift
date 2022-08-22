/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class AuthenticationSessionStateStoreTests: XCTestCase {
  var authenticationStateMap: TestKeyedValueMap!
  var authenticationSessionStateStore: AuthenticationSessionStateStore!
  override func setUp() {
    super.setUp()

    authenticationSessionStateStore = AuthenticationSessionStateStore()
    authenticationStateMap = TestKeyedValueMap()
    authenticationSessionStateStore.setDependencies(
      .init(
        authenticationSessionStateMap: authenticationStateMap
      )
    )
  }

  override func tearDown() {
    authenticationStateMap = nil
    authenticationSessionStateStore = nil

    super.tearDown()
  }

  func testCustomDependencies() throws {
    let dependencies = try authenticationSessionStateStore.getDependencies()

    XCTAssertIdentical(
      dependencies.authenticationSessionStateMap as AnyObject,
      authenticationStateMap,
      "Should be set to custom data storage."
    )
  }

  func testSettingAuthenticationSessionState() throws {
    authenticationSessionStateStore.authenticationSessionState = .performingLogin
    XCTAssertEqual(
      authenticationStateMap.capturedSetIntegerForKeyName,
      AuthenticationSessionStateStore.authenticationStateKey,
      "The persistence key should be passed to data storage"
    )
    XCTAssertEqual(
      authenticationStateMap.capturedSetIntValue,
      AuthenticationSessionState.performingLogin.rawValue,
      "The session state should be set to the assigned value"
    )
  }

  func testGettingAuthenticationSessionState() throws {
    let sessionState = authenticationSessionStateStore.authenticationSessionState
    XCTAssertEqual(authenticationStateMap.capturedIntegerKey, AuthenticationSessionStateStore.authenticationStateKey)
    XCTAssertNil(sessionState, "Session state should be none when no session state is stored")
  }

  func testGettingAuthenticationSessionStateWithStoredValue() throws {
    authenticationStateMap.stubbedIntegerForKey = 1
    let sessionState = authenticationSessionStateStore.authenticationSessionState
    XCTAssertEqual(
      sessionState,
      .performingLogin,
      "Session state should be active when there exists a session to retrieve"
    )
  }

  func testGettingAuthenticationSessionStateWithInvalidValue() throws {
    authenticationStateMap.stubbedIntegerForKey = 3
    let sessionState = authenticationSessionStateStore.authenticationSessionState
    XCTAssertNil(
      sessionState,
      "Session state should be none for a value that doesn't match a session state"
    )
  }
}
