/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class AccessTokenTests: XCTestCase {
  var expiredAccessToken: AccessToken!
  var newAccessToken: AccessToken!
  var accessTokenWithoutExpirationDate: AccessToken!
  var accessTokenWithInvalidTokenStr: AccessToken!
  var accessTokenWithInvalidExpirationDate: AccessToken!
  // swiftlint:disable:next identifier_name
  var accessTokenWithInvalidDataAccessExpirationDate: AccessToken!

  override func setUp() {
    super.setUp()

    let emptyTokenString = ""
    let tokenString = "testToken"
    let expiredDate = Date().addingTimeInterval(-100)
    let pastDate = Date().addingTimeInterval(-10)
    let futureDate = Date().addingTimeInterval(100)
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
