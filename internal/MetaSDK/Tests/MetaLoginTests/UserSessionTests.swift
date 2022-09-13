/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class UserSessionTests: XCTestCase {
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
      requestedPermissions: []
    )
  }

  override func tearDown() {
    userSession = nil
    super.tearDown()
  }

  func testUserSessionCodability() throws {
    let encoded = try JSONEncoder().encode(userSession)
    let decoded = try JSONDecoder().decode(UserSession.self, from: encoded)

    XCTAssertEqual(
      userSession.userID,
      decoded.userID,
      "User sessions are codable"
    )
    XCTAssertEqual(
      userSession.graphDomain,
      decoded.graphDomain,
      "User sessions are codable"
    )
    XCTAssertEqual(
      userSession.requestedPermissions,
      decoded.requestedPermissions,
      "User sessions are codable"
    )
  }
}
