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

  func testEncoding() {
    let expectedTokenString = "expectedTokenString"
    let expectedNonce = "expectedNonce"
    let expectedGraphDomain = "expectedGraphDomain"

    let coder = TestCoder()
    token = AuthenticationToken(
      tokenString: expectedTokenString,
      nonce: expectedNonce,
      graphDomain: expectedGraphDomain
    )
    token?.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject["FBSDKAuthenticationTokenTokenStringCodingKey"] as? String,
      expectedTokenString,
      "Should encode the expected token string"
    )
    XCTAssertEqual(
      coder.encodedObject["FBSDKAuthenticationTokenNonceCodingKey"] as? String,
      expectedNonce,
      "Should encode the expected nonce string"
    )
    XCTAssertEqual(
      coder.encodedObject["FBSDKAuthenticationTokenGraphDomainCodingKey"] as? String,
      expectedGraphDomain,
      "Should encode the expected graph domain"
    )
  }

  func testDecodingEntryWithMethodName() {
    let coder = TestCoder()
    token = AuthenticationToken(coder: coder)

    XCTAssertTrue(
      coder.decodedObject["FBSDKAuthenticationTokenTokenStringCodingKey"] as? Any.Type == NSString.self,
      "Initializing from a decoder should attempt to decode a String for the token string key"
    )
    XCTAssertTrue(
      coder.decodedObject["FBSDKAuthenticationTokenNonceCodingKey"] as? Any.Type == NSString.self,
      "Initializing from a decoder should attempt to decode a String for the nonce key"
    )
    XCTAssertTrue(
      coder.decodedObject["FBSDKAuthenticationTokenGraphDomainCodingKey"] as? Any.Type == NSString.self,
      "Initializing from a decoder should attempt to decode a String for the graph domain key"
    )
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
