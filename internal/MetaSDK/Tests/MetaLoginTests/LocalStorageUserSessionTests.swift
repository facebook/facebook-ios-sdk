/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

extension LocalStorageError: Equatable {
  public static func == (lhs: LocalStorageError, rhs: LocalStorageError) -> Bool {
    return lhs.localizedDescription == rhs.localizedDescription
  }
}

final class LocalStorageUserSessionTests: XCTestCase {
  var localStorage: LocalStorage!
  var userSessionMap: TestKeyedValueMap!
  var userSession: UserSession!
  var keychainStore: TestDataStore!

  override func setUp() {
    super.setUp()

    localStorage = LocalStorage()
    userSessionMap = TestKeyedValueMap()
    keychainStore = TestDataStore()
    let sampleAccessToken = AccessToken(
      tokenString: "testToken",
      expirationDate: Date().addingTimeInterval(100),
      dataAccessExpirationDate: Date().addingTimeInterval(100)
    )!
    userSession = UserSession(
      userID: UInt(111),
      graphDomain: GraphDomain.meta,
      accessToken: sampleAccessToken,
      requestedPermissions: [],
      declinedPermissions: []
    )
    localStorage.setDependencies(
      .init(
        userSessionMap: userSessionMap,
        userSessionStore: keychainStore
      )
    )
  }

  override func tearDown() {
    localStorage = nil
    userSessionMap = nil
    keychainStore = nil
    userSession = nil

    super.tearDown()
  }

  func testCustomDependencies() throws {
    let dependencies = try localStorage.getDependencies()
    XCTAssertIdentical(
      dependencies.userSessionMap as AnyObject,
      userSessionMap,
      "Dependency should be set to custom data storage."
    )
  }

  func testReadUserSessionSuccessfully() throws {
    userSessionMap.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStore.stubbedUserSessionData = try JSONEncoder().encode(userSession)
    let result = try localStorage.getUserSession()
    XCTAssertEqual(
      result,
      userSession,
      "Read userSession successfully"
    )
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionNotFound() throws {
    // Data does not exist in keychain
    userSessionMap.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStore.stubbedError = LocalStorageError.itemNotFound
    XCTAssertThrowsError(
      try localStorage.getUserSession(),
      "An itemNotFound error should be thrown when item is not found in keychain"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.itemNotFound)
    }
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionWithDecodingError() throws {
    // Failure in Decoding
    userSessionMap.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStore.stubbedUserSessionData = Data()
    XCTAssertThrowsError(
      try localStorage.getUserSession()
    ) { error in
      guard case DecodingError.dataCorrupted = error else {
        return XCTFail("A decodingError should been thrown due to failed decoding")
      }
    }
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionWithUnhandlledError() throws {
    // Failure in keychain read operation
    userSessionMap.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    XCTAssertThrowsError(
      try localStorage.getUserSession(),
      "An unhandled error should been thrown when error occurs in keychain API"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, keychainStore.stubbedError)
    }
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionWithEmptyUserDefaults() throws {
    keychainStore.stubbedUserSessionData = try JSONEncoder().encode(userSession)
    XCTAssertThrowsError(
      try localStorage.getUserSession(),
      "An itemNotFound error should been thrown when userDefault is empty"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.itemNotFound)
    }
    XCTAssertFalse(
      keychainStore.isReadCalled,
      "keychainStore.read() should not be called"
    )
  }

  func testSaveUserSessionWithSuccess() throws {
    let encodedUserSession = try JSONEncoder().encode(userSession)
    try localStorage.saveUserSession(userSession: userSession)
    XCTAssertEqual(
      encodedUserSession,
      keychainStore.capturedDataInAdd,
      "UserSession should be encoded and passed to keychainHelper.add()"
    )
    XCTAssertTrue(
      keychainStore.isSaveCalled,
      "keychainStore.save() should be called"
    )
    XCTAssertEqual(
      userSessionMap.capturedSetIntegerForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionMap.set should be called with defaultKey"
    )
  }

  func testSaveUserSessionWithKeychainError() throws {
    // Failure in keychain add operation
    userSessionMap.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    XCTAssertThrowsError(
      try localStorage.saveUserSession(userSession: userSession),
      "An unhandledError error should been thrown when failed to add value in keychain"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, keychainStore.stubbedError)
    }
    XCTAssertTrue(
      keychainStore.isSaveCalled,
      "keychainStore.save() should be called"
    )
  }

  func testDeleteUserSessionWithSuccess() throws {
    // Successful deletion
    try localStorage.deleteUserSession()
    XCTAssertEqual(
      userSessionMap.capturedRemoveStringForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionMap.removeObject should be called with defaultKey"
    )
    XCTAssertTrue(
      keychainStore.isDeleteCalled,
      "keychainStore.delete() should be called"
    )
  }

  func testDeleteUserSessionWithKeychainError() throws {
    // Failed deletion due to bad keychain request
    keychainStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    XCTAssertThrowsError(
      try localStorage.deleteUserSession(),
      "An unhandledError error should been thrown when it fails to delete value in keychain"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, keychainStore.stubbedError)
    }
    XCTAssertEqual(
      userSessionMap.capturedRemoveStringForKeyName,
      nil,
      "should not remove userSessionSavedFlagKey in userDefaults"
    )
  }

  func testDeleteNonexistentItem() throws {
    // Delete nonexistent item
    try localStorage.deleteUserSession()
    XCTAssertEqual(
      userSessionMap.capturedRemoveStringForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionMap.removeObject should be called with defaultKey"
    )
    XCTAssertTrue(
      keychainStore.isDeleteCalled,
      "keychainStorage.delete() should be called"
    )
  }
}
