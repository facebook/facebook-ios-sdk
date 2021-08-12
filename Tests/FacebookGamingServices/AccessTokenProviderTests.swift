// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
