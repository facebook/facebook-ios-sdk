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

final class UserSessionStoreTests: XCTestCase {
  var userSessionStore: UserSessionStore!
  var userSessionMap: TestKeyedValueMap!
  var userSession: UserSession!
  var keychainStore: TestDataStore!

  override func setUp() async throws {
    try await super.setUp()

    userSessionStore = UserSessionStore()
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
      requestedPermissions: []
    )
    await userSessionStore.setDependencies(
      .init(
        userSessionMap: userSessionMap,
        userSessionStorage: keychainStore
      )
    )
  }

  override func tearDown() {
    userSessionStore = nil
    userSessionMap = nil
    keychainStore = nil
    userSession = nil

    super.tearDown()
  }

  func testCustomDependencies() async throws {
    let dependencies = try await userSessionStore.getDependencies()
    XCTAssertIdentical(
      dependencies.userSessionMap as AnyObject,
      userSessionMap,
      "Dependency should be set to custom data storage."
    )
  }

  func testReadUserSessionSuccessfully() async throws {
    userSessionMap.stubbedIntegerForKey = UserSessionStore.userSessionSavedFlag
    keychainStore.stubbedUserSessionData = try JSONEncoder().encode(userSession)
    let result = try await userSessionStore.getUserSession()
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

  func testReadUserSessionNotFound() async throws {
    // Data does not exist in keychain
    userSessionMap.stubbedIntegerForKey = UserSessionStore.userSessionSavedFlag
    keychainStore.stubbedError = LocalStorageError.itemNotFound
    do {
      _ = try await userSessionStore.getUserSession()
      XCTFail("An itemNotFound error should be thrown when item is not found in keychain")
    } catch {
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.itemNotFound)
    }
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionWithDecodingError() async throws {
    // Failure in Decoding
    userSessionMap.stubbedIntegerForKey = UserSessionStore.userSessionSavedFlag
    keychainStore.stubbedUserSessionData = Data()
    do {
      _ = try await userSessionStore.getUserSession()
      XCTFail("A decodingError should been thrown due to failed decoding")
    } catch {
      guard case DecodingError.dataCorrupted = error else {
        return XCTFail("A decodingError should been thrown due to failed decoding")
      }
    }
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionWithUnhandlledError() async throws {
    // Failure in keychain read operation
    userSessionMap.stubbedIntegerForKey = UserSessionStore.userSessionSavedFlag
    keychainStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    do {
      _ = try await userSessionStore.getUserSession()
      XCTFail("An unhandled error should been thrown when error occurs in keychain API")
    } catch {
      XCTAssertEqual(error as? LocalStorageError, keychainStore.stubbedError)
    }
    XCTAssertTrue(
      keychainStore.isReadCalled,
      "keychainStore.read() should be called"
    )
  }

  func testReadUserSessionWithEmptyUserDefaults() async throws {
    keychainStore.stubbedUserSessionData = try JSONEncoder().encode(userSession)
    do {
      _ = try await userSessionStore.getUserSession()
      XCTFail("An itemNotFound error should been thrown when userDefault is empty")
    } catch {
      XCTAssertEqual(error as? LocalStorageError, LocalStorageError.itemNotFound)
    }
    XCTAssertFalse(
      keychainStore.isReadCalled,
      "keychainStore.read() should not be called"
    )
  }

  func testSaveUserSessionWithSuccess() async throws {
    let encodedUserSession = try JSONEncoder().encode(userSession)
    try await userSessionStore.saveUserSession(userSession)
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
      UserSessionStore.userSessionSavedFlagKey,
      "userSessionMap.set should be called with defaultKey"
    )
  }

  func testSaveUserSessionWithKeychainError() async throws {
    // Failure in keychain add operation
    userSessionMap.stubbedIntegerForKey = UserSessionStore.userSessionSavedFlag
    keychainStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    do {
      _ = try await userSessionStore.saveUserSession(userSession)
      XCTFail("An unhandledError error should been thrown when failed to add value in keychain")
    } catch {
      XCTAssertEqual(error as? LocalStorageError, keychainStore.stubbedError)
    }
    XCTAssertTrue(
      keychainStore.isSaveCalled,
      "keychainStore.save() should be called"
    )
  }

  func testDeleteUserSessionWithSuccess() async throws {
    // Successful deletion
    try await userSessionStore.deleteUserSession()
    XCTAssertEqual(
      userSessionMap.capturedRemoveStringForKeyName,
      UserSessionStore.userSessionSavedFlagKey,
      "userSessionMap.removeObject should be called with defaultKey"
    )
    XCTAssertTrue(
      keychainStore.isDeleteCalled,
      "keychainStore.delete() should be called"
    )
  }

  func testDeleteUserSessionWithKeychainError() async throws {
    // Failed deletion due to bad keychain request
    keychainStore.stubbedError = LocalStorageError.unhandledError(
      status: SecCopyErrorMessageString(errSecBadReq, nil) as? String)
    do {
      _ = try await userSessionStore.deleteUserSession()
      XCTFail("An unhandledError error should been thrown when it fails to delete value in keychain")
    } catch {
      XCTAssertEqual(error as? LocalStorageError, keychainStore.stubbedError)
    }
    XCTAssertEqual(
      userSessionMap.capturedRemoveStringForKeyName,
      nil,
      "should not remove userSessionSavedFlagKey in userDefaults"
    )
  }

  func testDeleteNonexistentItem() async throws {
    // Delete nonexistent item
    try await userSessionStore.deleteUserSession()
    XCTAssertEqual(
      userSessionMap.capturedRemoveStringForKeyName,
      UserSessionStore.userSessionSavedFlagKey,
      "userSessionMap.removeObject should be called with defaultKey"
    )
    XCTAssertTrue(
      keychainStore.isDeleteCalled,
      "keychainStorage.delete() should be called"
    )
  }
}
