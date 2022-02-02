/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

final class AccessTokenTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var tokenCache: TestTokenCache!
  var connection: TestGraphRequestConnection!
  var graphRequestConnectionFactory: TestGraphRequestConnectionFactory!
  var graphRequestPiggybackManager: TestGraphRequestPiggybackManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AccessToken.resetClassDependencies()

    tokenCache = TestTokenCache()
    connection = TestGraphRequestConnection()
    graphRequestConnectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    graphRequestPiggybackManager = TestGraphRequestPiggybackManager()

    AccessToken.configure(
      withTokenCache: tokenCache,
      graphRequestConnectionFactory: graphRequestConnectionFactory,
      graphRequestPiggybackManager: graphRequestPiggybackManager,
      errorFactory: TestErrorFactory()
    )
  }

  override func tearDown() {
    super.tearDown()

    AccessToken.current = nil
    AccessToken.resetClassDependencies()
  }

  func testDefaultClassDependencies() {
    AccessToken.resetClassDependencies()

    XCTAssertNil(
      AccessToken.tokenCache,
      "Should not have a token cache by default"
    )
    XCTAssertNil(
      AccessToken.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      AccessToken.graphRequestPiggybackManager,
      "Should not have a graph request piggyback manager by default"
    )
  }

  func testSettingTokenCache() {
    let cache = TestTokenCache(accessToken: nil, authenticationToken: nil)
    AccessToken.tokenCache = cache
    XCTAssertTrue(AccessToken.tokenCache === cache, "Access token cache should be settable")
  }

  func testRetrievingCurrentToken() {
    AccessToken.current = SampleAccessTokens.validToken

    XCTAssertTrue(
      tokenCache.accessToken === SampleAccessTokens.validToken,
      "Setting the global access token should invoke the cache"
    )
  }

  func testRefreshCurrentAccessTokenWithNilToken() {
    AccessToken.current = nil
    AccessToken.refreshCurrentAccessToken(completion: nil)
    XCTAssertEqual(connection.startCallCount, 0, "Should not start connection if no current access token available")
  }

  func testRefreshingNilTokenError() throws {
    AccessToken.current = nil

    var connection: GraphRequestConnecting?
    var data: Any?
    var error: Error?
    AccessToken.refreshCurrentAccessToken { potentialConnection, potentialData, potentialError in
      connection = potentialConnection
      data = potentialData
      error = potentialError
    }
    XCTAssertNil(
      connection,
      "Shouldn't create a connection is there is no token to refresh"
    )
    XCTAssertNil(
      data,
      "Should not call back with data if there is no token to refresh"
    )

    let sdkError = try XCTUnwrap(
      error as? TestSDKError,
      "Should error when attempting to refresh a nil access token"
    )
    XCTAssertEqual(
      sdkError.code,
      CoreError.errorAccessTokenRequired.rawValue,
      "Should return an error with an access token required code"
    )
    XCTAssertEqual(
      sdkError.message,
      "No current access token to refresh",
      "Should return an error with an appropriate message"
    )
  }

  func testRefreshCurrentAccessTokenWithNonNilToken() {
    AccessToken.current = SampleAccessTokens.validToken
    AccessToken.refreshCurrentAccessToken(completion: nil)
    XCTAssertEqual(connection.startCallCount, 1, "Should start one connection for refreshing")

    XCTAssertTrue(
      graphRequestPiggybackManager.addRefreshPiggybackWasCalled,
      "Refreshing an access token should add a refresh piggyback"
    )
  }

  func testIsDataAccessExpired() {
    var token = SampleAccessTokens.create(dataAccessExpirationDate: .distantPast)
    XCTAssertTrue(
      token.isDataAccessExpired,
      "A token should have a convenience method for determining if data access is expired"
    )
    token = SampleAccessTokens.create(dataAccessExpirationDate: .distantFuture)
    XCTAssertFalse(
      token.isDataAccessExpired,
      "A token should have a convenience method for determining if data access is unexpired"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      AccessToken.supportsSecureCoding,
      "Access tokens should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    let token = SampleAccessTokens.validToken
    token.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject["tokenString"] as? String,
      SampleAccessTokens.validToken.tokenString,
      "Should encode the expected tokenString with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["permissions"] as? Set<Permission>,
      SampleAccessTokens.validToken.permissions,
      "Should encode the expected permissions with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["declinedPermissions"] as? Set<Permission>,
      SampleAccessTokens.validToken.declinedPermissions,
      "Should encode the expected declinedPermissions with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["expiredPermissions"] as? Set<Permission>,
      SampleAccessTokens.validToken.expiredPermissions,
      "Should encode the expected expiredPermissions with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["appID"] as? String,
      SampleAccessTokens.validToken.appID,
      "Should encode the expected appID with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject["userID"] as? String,
      SampleAccessTokens.validToken.userID,
      "Should encode the expected userID with the correct key"
    )
    XCTAssertEqual(
      (coder.encodedObject["refreshDate"] as? Date)?.timeIntervalSince1970,
      token.refreshDate.timeIntervalSince1970,
      "Should encode the expected refreshDate with the correct key"
    )
    XCTAssertEqual(
      (coder.encodedObject["expirationDate"] as? Date)?.timeIntervalSince1970,
      SampleAccessTokens.validToken.expirationDate.timeIntervalSince1970,
      "Should encode the expected expirationDate with the correct key"
    )
    XCTAssertEqual(
      (coder.encodedObject["dataAccessExpirationDate"] as? Date)?.timeIntervalSince1970,
      SampleAccessTokens.validToken.dataAccessExpirationDate.timeIntervalSince1970,
      "Should encode the expected dataAccessExpirationDate with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AccessToken(coder: decoder)

    XCTAssertTrue(
      decoder.decodedObject["tokenString"] is NSString.Type,
      "Should decode the expected type for the tokenString key"
    )
    XCTAssertTrue(
      decoder.decodedObject["permissions"] is NSSet.Type,
      "Should decode the expected type for the permissions key"
    )
    XCTAssertTrue(
      decoder.decodedObject["declinedPermissions"] is NSSet.Type,
      "Should decode the expected type for the declinedPermissions key"
    )
    XCTAssertTrue(
      decoder.decodedObject["expiredPermissions"] is NSSet.Type,
      "Should decode the expected type for the expiredPermissions key"
    )
    XCTAssertTrue(
      decoder.decodedObject["appID"] is NSString.Type,
      "Should decode the expected type for the appID key"
    )
    XCTAssertTrue(
      decoder.decodedObject["userID"] is NSString.Type,
      "Should decode the expected type for the userID key"
    )
    XCTAssertTrue(
      decoder.decodedObject["refreshDate"] is NSDate.Type,
      "Should decode the expected type for the refreshDate key"
    )
    XCTAssertTrue(
      decoder.decodedObject["expirationDate"] is NSDate.Type,
      "Should decode the expected type for the expirationDate key"
    )
    XCTAssertTrue(
      decoder.decodedObject["dataAccessExpirationDate"] is NSDate.Type,
      "Should decode the expected type for the dataAccessExpirationDate key"
    )
  }

  func testEquatability() {
    let token1 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    let token2 = SampleAccessTokens.create(withRefreshDate: .distantFuture)
    XCTAssertNotEqual(
      token1,
      token2,
      "Tokens with different values should not be considered equal"
    )
    let token3 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    let token4 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    XCTAssertEqual(
      token3,
      token4,
      "Tokens with the same values should be considered equal"
    )
  }

  func testHashability() {
    let token = SampleAccessTokens.create(withRefreshDate: .distantPast)
    let token2 = SampleAccessTokens.create(withRefreshDate: .distantPast)
    XCTAssertEqual(
      token.hash,
      token2.hash,
      "Token hash values should be predictable and based on the token's properties"
    )
    let token3 = SampleAccessTokens.create(withRefreshDate: .distantFuture)
    XCTAssertNotEqual(
      token.hash,
      token3.hash,
      "Token hash values should be predictable and based on the token's properties"
    )
  }

  func testGrantedPermissions() {
    let token = SampleAccessTokens.create(withPermissions: [name])
    XCTAssertTrue(token.hasGranted(Permission(stringLiteral: name)))
  }
}
