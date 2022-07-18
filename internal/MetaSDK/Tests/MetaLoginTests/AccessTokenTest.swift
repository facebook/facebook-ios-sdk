// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import XCTest
@testable import MetaLogin

class AccessTokenTest: XCTestCase {
    var expiredAccessToken: AccessToken!
    var newAccessToken: AccessToken!
    var accessTokenWithoutExpirationDate: AccessToken!
    var accessTokenWithInvalidTokenStr: AccessToken!
    var accessTokenWithInvalidExpirationDate: AccessToken!
    var accessTokenWithInvalidDataAccessExpirationDate: AccessToken!
    
    override func setUp() {
        super.setUp()
        
        let emptyTokenString = ""
        let tokenString = "testToken"
        let expiredDate = Date().advanced(by: -100)
        let pastDate = Date().advanced(by: -10)
        let futureDate = Date().advanced(by: 100)
        accessTokenWithInvalidExpirationDate = AccessToken(
            tokenString: tokenString,
            expirationDate: expiredDate,
            dataAccessExpirationDate: futureDate
        )
        accessTokenWithInvalidDataAccessExpirationDate = AccessToken(
            tokenString: tokenString,
            expirationDate: futureDate,
            dataAccessExpirationDate: expiredDate
        )
        expiredAccessToken = AccessToken(
            tokenString: tokenString,
            expirationDate: pastDate,
            dataAccessExpirationDate: pastDate,
            creationDate: expiredDate
        )
        newAccessToken = AccessToken(
            tokenString: tokenString,
            expirationDate: futureDate,
            dataAccessExpirationDate: futureDate
        )
        accessTokenWithoutExpirationDate = AccessToken(tokenString: tokenString)
        accessTokenWithInvalidTokenStr = AccessToken(
            tokenString: emptyTokenString,
            expirationDate: futureDate,
            dataAccessExpirationDate: futureDate
        )
    }
    
    override func tearDown() {
        expiredAccessToken = nil
        newAccessToken = nil
        accessTokenWithoutExpirationDate = nil
        accessTokenWithInvalidTokenStr = nil
        accessTokenWithInvalidExpirationDate = nil
        accessTokenWithInvalidDataAccessExpirationDate = nil
        super.tearDown()
    }

    func testAccessTokenExpiration() {
        XCTAssertTrue(
            expiredAccessToken.isExpired,
            "Old token should be expired"
        )
        XCTAssertTrue(
            expiredAccessToken.isDataAccessExpired,
            "Data access permission of old token should be expired"
        )
        XCTAssertFalse(
            newAccessToken.isExpired,
            "New token should not be expired"
        )
        XCTAssertFalse(
            newAccessToken.isDataAccessExpired,
            "Data access permission of new token should not be expired"
        )
        XCTAssertFalse(
            accessTokenWithoutExpirationDate.isExpired,
            "Undefined expirationDate means an infinite expiration"
        )
        XCTAssertFalse(
            accessTokenWithoutExpirationDate.isDataAccessExpired,
            "Undefined dataAccessExpirationDate means an infinite expiration"

        )
    }
    
    func testInvalidTokenParameters() {
        XCTAssertNil(
            accessTokenWithInvalidTokenStr,
            "Invalid tokenString causes failed token initialization"
        )
        XCTAssertNil(
            accessTokenWithInvalidExpirationDate,
            "Invalid expirationDate causes failed token initialization"
        )
        XCTAssertNil(
            accessTokenWithInvalidDataAccessExpirationDate,
            "Invalid data access expirationDate causes failed token initialization"
        )
    }
}
