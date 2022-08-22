/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

final class TestUserSessionStore: UserSessionPersisting {
  var stubbedUserSession: UserSession
  var capturedUserSessionInSave: UserSession?
  var isDeleteUserSessionCalled = false
  var isGetUserSessionCalled = false
  var stubbedError: LocalStorageError?

  init() {
    let sampleToken = AccessToken(
      tokenString: "testToken",
      expirationDate: Date().addingTimeInterval(100),
      dataAccessExpirationDate: Date().addingTimeInterval(100)
    )!
    stubbedUserSession = UserSession(
      userID: UInt(111),
      graphDomain: .facebook,
      accessToken: sampleToken,
      requestedPermissions: [],
      declinedPermissions: []
    )
  }

  func saveUserSession(_ userSession: UserSession) async throws {
    capturedUserSessionInSave = userSession
  }

  func deleteUserSession() async {
    isDeleteUserSessionCalled = true
  }

  func getUserSession() async throws -> UserSession {
    isGetUserSessionCalled = true
    if let error = stubbedError {
      throw error
    }
    return stubbedUserSession
  }
}
