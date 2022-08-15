/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class LocalStorageAuthenticationStateTests: XCTestCase {
  var localStorage: LocalStorage!
  var authenticationStateMap: TestKeyedValueMap!
  var userSession: UserSession!
  var keychainStore: TestDataStore!

  override func setUp() {
    super.setUp()

    localStorage = LocalStorage()
    authenticationStateMap = TestKeyedValueMap()
    keychainStore = TestDataStore()
    let token = AccessToken(
      tokenString: "testToken",
      expirationDate: Date().addingTimeInterval(100),
      dataAccessExpirationDate: Date().addingTimeInterval(100)
    )!
    userSession = UserSession(
      userID: UInt(111),
      graphDomain: GraphDomain.meta,
      accessToken: token,
      requestedPermissions: [],
      declinedPermissions: []
    )
    localStorage.setDependencies(
      .init(
        userSessionMap: authenticationStateMap,
        userSessionStore: keychainStore
      )
    )
  }

  override func tearDown() {
    localStorage = nil
    authenticationStateMap = nil
    keychainStore = nil
    userSession = nil

    super.tearDown()
  }

  func testCustomDependencies() throws {
    let dependencies = try localStorage.getDependencies()

    XCTAssertIdentical(
      dependencies.userSessionMap as AnyObject,
      authenticationStateMap,
      "Should be set to custom data storage."
    )
  }

  func testSettingAuthenticationSessionState() throws {
    localStorage.authenticationSessionState = .performingLogin
    XCTAssertEqual(
      authenticationStateMap.capturedSetIntegerForKeyName,
      LocalStorage.authenticationStateKey,
      "The persistence key should be passed to data storage"
    )
    XCTAssertEqual(
      authenticationStateMap.capturedSetIntValue,
      AuthenticationSessionState.performingLogin.rawValue,
      "The session state should be set to the assigned value"
    )
  }

  func testGettingAuthenticationSessionState() throws {
    let sessionState = localStorage.authenticationSessionState
    XCTAssertEqual(authenticationStateMap.capturedIntegerKey, LocalStorage.authenticationStateKey)
    XCTAssertEqual(sessionState, .none, "Session state should be none when no session state is stored")
  }

  func testGettingAuthenticationSessionStateWithStoredValue() throws {
    authenticationStateMap.stubbedIntegerForKey = 1
    let sessionState = localStorage.authenticationSessionState
    XCTAssertEqual(
      sessionState,
      .performingLogin,
      "Session state should be active when there exists a session to retrieve"
    )
  }

  func testGettingAuthenticationSessionStateWithInvalidValue() throws {
    authenticationStateMap.stubbedIntegerForKey = 3
    let sessionState = localStorage.authenticationSessionState
    XCTAssertEqual(
      sessionState,
      .none,
      "Session state should be none for a value that doesn't match a session state"
    )
  }
}
