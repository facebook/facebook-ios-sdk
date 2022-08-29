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

  override func setUp() async throws {
    try await super.setUp()

    authenticationSessionStateStore = AuthenticationSessionStateStore()
    authenticationStateMap = TestKeyedValueMap()
    await authenticationSessionStateStore.setDependencies(
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

  func testCustomDependencies() async throws {
    let dependencies = try await authenticationSessionStateStore.getDependencies()

    XCTAssertIdentical(
      dependencies.authenticationSessionStateMap as AnyObject,
      authenticationStateMap,
      "Should be set to custom data storage."
    )
  }

  func testSettingAuthenticationSessionState() async throws {
    await authenticationSessionStateStore.setAuthenticationSessionState(.performingLogin)
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

  func testGettingAuthenticationSessionState() async throws {
    let sessionState = await authenticationSessionStateStore.getAuthenticationSessionState()
    XCTAssertEqual(authenticationStateMap.capturedIntegerKey, AuthenticationSessionStateStore.authenticationStateKey)
    XCTAssertNil(sessionState, "Session state should be none when no session state is stored")
  }

  func testGettingAuthenticationSessionStateWithStoredValue() async throws {
    authenticationStateMap.stubbedIntegerForKey = 1
    let sessionState = await authenticationSessionStateStore.getAuthenticationSessionState()
    XCTAssertEqual(
      sessionState,
      .performingLogin,
      "Session state should be active when there exists a session to retrieve"
    )
  }

  func testGettingAuthenticationSessionStateWithInvalidValue() async throws {
    authenticationStateMap.stubbedIntegerForKey = 3
    let sessionState = await authenticationSessionStateStore.getAuthenticationSessionState()
    XCTAssertNil(
      sessionState,
      "Session state should be none for a value that doesn't match a session state"
    )
  }
}
