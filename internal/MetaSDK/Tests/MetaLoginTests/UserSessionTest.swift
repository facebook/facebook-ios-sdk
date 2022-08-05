/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest
@testable import MetaLogin

extension AccessToken: Equatable {

    public static func == (
      lhs: AccessToken,
      rhs: AccessToken
    ) -> Bool {
        lhs.tokenString == rhs.tokenString &&
        lhs.expirationDate == rhs.expirationDate
    }
}

extension UserSession: Equatable {

    public static func == (
      lhs: UserSession,
      rhs: UserSession
    ) -> Bool {
        lhs.accessToken == rhs.accessToken &&
        lhs.userID == rhs.userID &&
        lhs.graphDomain == rhs.graphDomain &&
        lhs.requestedPermissions == rhs.requestedPermissions &&
        lhs.declinedPermissions == rhs.declinedPermissions
    }
}

final class UserSessionTest: XCTestCase {
    var userSession: UserSession!

    override func setUp() {
        super.setUp()

        let userID = UInt(111)
        let tokenString = "testToken"
        let graphDomain = GraphDomain.meta
        let token = AccessToken(
            tokenString: tokenString,
            expirationDate: Date().addingTimeInterval(100),
            dataAccessExpirationDate: Date().addingTimeInterval(100)
        )!
        userSession = UserSession(
            userID: userID,
            graphDomain: graphDomain,
            accessToken: token,
            requestedPermissions: [],
            declinedPermissions: []
        )
    }

    override func tearDown() {
        userSession = nil
        super.tearDown()
    }

    func testUserSessionEncoderAndDecoder() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let encoded = try encoder.encode(userSession)
        let decoded = try decoder.decode(UserSession.self, from: encoded)
        XCTAssertEqual(
            userSession,
            decoded,
            "The decoded userSession data should be the same with original data"
        )
    }
}
