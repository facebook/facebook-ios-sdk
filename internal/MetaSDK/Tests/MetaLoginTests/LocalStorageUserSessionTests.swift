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
  var userSessionStore: TestKeyedValueMap!
  var userSession: UserSession!
  var keychainStorage: TestKeychainStorage!

  override func setUp() {
    super.setUp()

    localStorage = LocalStorage()
    userSessionStore = TestKeyedValueMap()
    keychainStorage = TestKeychainStorage()
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
        userSessionStore: userSessionStore,
        keychainStorage: keychainStorage
      )
    )
  }

  override func tearDown() {
    localStorage = nil
    userSessionStore = nil
    keychainStorage = nil
    userSession = nil

    super.tearDown()
  }

  func testCustomDependencies() throws {
    let dependencies = try localStorage.getDependencies()
    XCTAssertIdentical(
      dependencies.userSessionStore as AnyObject,
      userSessionStore,
      "Dependency should be set to custom data storage."
    )
  }

  func testReadUserSessionSuccessfully() throws {
    userSessionStore.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStorage.stubbedUserSessionData = try JSONEncoder().encode(userSession)
    keychainStorage.stubbedReadOSStatus = noErr
    let result = try localStorage.getUserSession()
    XCTAssertEqual(
      result,
      userSession,
      "Read userSession successfully"
    )
    XCTAssertTrue(
      keychainStorage.isReadCalled,
      "keychainStorage.read() should be called"
    )
  }

  func testReadUserSessionNotFound() throws {
    // Data does not exist in keychain
    userSessionStore.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStorage.stubbedReadOSStatus = errSecItemNotFound
    XCTAssertThrowsError(
      try localStorage.getUserSession(),
      "An itemNotFound error should be thrown when item is not found in keychain"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.itemNotFound)
    }
    XCTAssertTrue(
      keychainStorage.isReadCalled,
      "keychainStorage.read() should be called"
    )
  }

  func testReadUserSessionWithDecodingError() throws {
    // Failure in Decoding
    userSessionStore.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStorage.stubbedReadOSStatus = noErr
    keychainStorage.stubbedUserSessionData = Data()
    XCTAssertThrowsError(
      try localStorage.getUserSession()
    ) { error in
      guard case LocalStorageError.decodingError = error else {
        return XCTFail("A decodingError should been thrown due to failed decoding")
      }
    }
    XCTAssertTrue(
      keychainStorage.isReadCalled,
      "keychainStorage.read() should be called"
    )
  }

  func testReadUserSessionWithKeychainError() throws {
    // Failure in keychain read operation
    userSessionStore.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStorage.stubbedReadOSStatus = errSecBadReq
    XCTAssertThrowsError(
      try localStorage.getUserSession(),
      "An unhandled error should been thrown when error occurs in keychain API"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.unhandledError(status: errSecBadReq))
    }
  }

  func testReadUserSessionWithEmptyUserDefaults() throws {
    keychainStorage.stubbedUserSessionData = try JSONEncoder().encode(userSession)
    keychainStorage.stubbedReadOSStatus = noErr
    XCTAssertThrowsError(
      try localStorage.getUserSession(),
      "An itemNotFound error should been thrown when userDefault is empty"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.itemNotFound)
    }
    XCTAssertFalse(
      keychainStorage.isReadCalled,
      "keychainStorage.read() should not be called"
    )
  }

  func testSaveUserSessionWithSuccess() throws {
    let encodedUserSession = try JSONEncoder().encode(userSession)
    keychainStorage.stubbedSaveOSStatus = noErr
    try localStorage.saveUserSession(userSession: userSession)
    XCTAssertEqual(
      encodedUserSession,
      keychainStorage.capturedDataInAdd,
      "UserSession should be encoded and passed to keychainHelper.add()"
    )
    XCTAssertTrue(
      keychainStorage.isSaveCalled,
      "keychainStorage.save() should be called"
    )
    XCTAssertEqual(
      userSessionStore.capturedSetIntegerForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionStore.set should be called with defaultKey"
    )
  }

  func testSaveUserSessionWithKeychainError() throws {
    // Failure in keychain add operation
    userSessionStore.stubbedIntegerForKey = LocalStorage.userSessionSavedFlag
    keychainStorage.stubbedSaveOSStatus = errSecBadReq
    XCTAssertThrowsError(
      try localStorage.saveUserSession(userSession: userSession),
      "An unhandledError error should been thrown when failed to add value in keychain"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.unhandledError(status: errSecBadReq))
    }
    XCTAssertTrue(
      keychainStorage.isSaveCalled,
      "keychainStorage.save() should be called"
    )
  }

  func testDeleteUserSessionWithSuccess() throws {
    // Successful deletion
    keychainStorage.stubbedDeleteOSStatus = noErr
    try localStorage.deleteUserSession()
    XCTAssertEqual(
      userSessionStore.capturedRemoveStringForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionStore.remove() should be called with defaultKey"
    )
    XCTAssertTrue(
      keychainStorage.isDeleteCalled,
      "keychainStorage.delete() should be called"
    )
  }

  func testDeleteUserSessionWithKeychainError() throws {
    // Failed deletion due to bad keychain request
    keychainStorage.stubbedDeleteOSStatus = errSecBadReq
    XCTAssertThrowsError(
      try localStorage.deleteUserSession(),
      "An unhandledError error should been thrown when it fails to delete value in keychain"
    ) { error in
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.unhandledError(status: errSecBadReq))
    }
    XCTAssertEqual(
      userSessionStore.capturedRemoveStringForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionStore.remove() should be called with defaultKey"
    )
  }

  func testDeleteNonexistentItem() throws {
    // Delete nonexistent item
    keychainStorage.stubbedDeleteOSStatus = errSecItemNotFound
    try localStorage.deleteUserSession()
    XCTAssertEqual(
      userSessionStore.capturedRemoveStringForKeyName,
      LocalStorage.userSessionSavedFlagKey,
      "userSessionStore.remove() should be called with defaultKey"
    )
    XCTAssertTrue(
      keychainStorage.isDeleteCalled,
      "keychainStorage.delete() should be called"
    )
  }
}
