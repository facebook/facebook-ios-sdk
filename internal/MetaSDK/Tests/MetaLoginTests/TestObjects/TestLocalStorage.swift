/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
@testable import MetaLogin

final class TestLocalStorage: AuthenticationSessionStatePersisting, UserSessionPersisting {
    var authenticationSessionState: AuthenticationSessionState
    var stubbedUserSession: UserSession
    var capturedUserSessionInSave: UserSession?
    var isDeleteUserSessionCalled = false
    var isGetUserSessionCalled = false
    var stubbedError: LocalStorageError?

    init() {
        authenticationSessionState = .none
        let sampleToken = AccessToken(
            tokenString: "testToken",
            expirationDate: Date().addingTimeInterval(100),
            dataAccessExpirationDate: Date().addingTimeInterval(100)
        )!
        stubbedUserSession = UserSession(
            userId: UInt(111),
            graphDomain: GraphDomain.faceBook,
            accessToken: sampleToken,
            requestedPermissions: [],
            declinedPermissions: []
        )
    }

    func saveUserSession(userSession: UserSession) throws {
        capturedUserSessionInSave = userSession
    }

    func deleteUserSession() throws {
        isDeleteUserSessionCalled = true
    }

    func getUserSession() throws -> UserSession {
        isGetUserSessionCalled = true
        if let error = stubbedError {
            throw error
        }
        return stubbedUserSession
    }
}
