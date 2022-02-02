/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices
import FBSDKCoreKit
import TestTools
import XCTest

class AccessTokenProviderTests: XCTestCase {

  class TestTokenCache: NSObject, TokenCaching {
    var accessToken: AccessToken?
    var authenticationToken: AuthenticationToken?
  }

  lazy var token = SampleAccessTokens.create(withPermissions: [name])
  let cache = TestTokenCache()

  override class func setUp() {
    super.setUp()

    AccessToken.current = nil
    AccessToken.tokenCache = nil
  }

  override func tearDown() {
    AccessToken.current = nil
    AccessToken.tokenCache = nil

    super.tearDown()
  }

  func testCurrentToken() {
    AccessToken.current = token

    XCTAssertTrue(
      AccessTokenProvider.currentAccessToken === token,
      "The current access token should match that on the AccessToken singleton"
    )
  }

  func testGettingTokenCache() {
    AccessToken.tokenCache = cache

    XCTAssertTrue(
      AccessTokenProvider.tokenCache === cache,
      "The current token cache should match that on the AccessToken singleton"
    )
  }

  func testSettingTokenCache() {
    AccessTokenProvider.tokenCache = cache

    XCTAssertTrue(
      AccessToken.tokenCache === cache,
      "Should set the provided token cache on the underlying access token type"
    )
  }
}
