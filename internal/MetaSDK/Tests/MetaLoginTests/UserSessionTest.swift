// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

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

extension UserSession : Equatable {
    
    public static func == (
      lhs: UserSession,
      rhs: UserSession
    ) -> Bool {
        lhs.accessToken == rhs.accessToken &&
        lhs.userId == rhs.userId &&
        lhs.graphDomain == rhs.graphDomain &&
        lhs.requestedPermissions == rhs.requestedPermissions &&
        lhs.declinedPermissions == rhs.declinedPermissions
    }
}

class UserSessionTest: XCTestCase {
    var userSession: UserSession!
    
    override func setUp() {
        super.setUp()
        
        let userId = UInt(111)
        let tokenString = "testToken"
        let graphDomain = GraphDomain.meta
        let token = AccessToken(
            tokenString: tokenString,
            expirationDate: Date().addingTimeInterval(100),
            dataAccessExpirationDate: Date().addingTimeInterval(100)
        )!
        userSession = UserSession(
            userId: userId,
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
