/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools

final class AuthenticationTokenTests: XCTestCase {
  private var token: AuthenticationToken?

  override func setUp() {
    super.setUp()

    AuthenticationToken.resetTokenCache()
  }

  override func tearDown() {
    super.tearDown()

    AuthenticationToken.resetTokenCache()
  }

  // MARK: - Persistence

  func testRetrievingCurrentToken() {
    let cache = TestTokenCache()
    token = SampleAuthenticationToken.validToken
    AuthenticationToken.tokenCache = cache

    AuthenticationToken.current = token
    XCTAssertEqual(
      cache.authenticationToken,
      token,
      "Setting the global authentication token should invoke the cache"
    )
  }

  func testEncodingAndDecoding() throws {
    let expectedTokenString = "expectedTokenString"
    let expectedNonce = "expectedNonce"
    let expectedGraphDomain = "expectedGraphDomain"

    let token = AuthenticationToken(
      tokenString: expectedTokenString,
      nonce: expectedNonce,
      graphDomain: expectedGraphDomain
    )

    let decodedObject = try CodabilityTesting.encodeAndDecode(token)

    // Test Objects
    XCTAssertNotEqual(decodedObject, token, .isCodable) // isEqual method not implemented yet
    XCTAssertNotIdentical(decodedObject, token, .isCodable)

    // Test Properties
    XCTAssertEqual(decodedObject.tokenString, token.tokenString, .isCodable)
    XCTAssertEqual(decodedObject.nonce, token.nonce, .isCodable)
    XCTAssertEqual(decodedObject.graphDomain, token.graphDomain, .isCodable)
  }

  func testTokenCacheIsNilByDefault() {
    XCTAssertNil(AuthenticationToken.tokenCache, "Authentication token cache should be nil by default")
  }

  func testTokenCacheCanBeSet() {
    let cache = TestTokenCache()
    AuthenticationToken.tokenCache = cache
    XCTAssertEqual(
      AuthenticationToken.tokenCache as? TestTokenCache,
      cache,
      "Authentication token cache should be settable"
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "AuthenticationToken should be encodable and decodable"
}
