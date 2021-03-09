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

import TestTools
import XCTest

class AccessTokenTests: XCTestCase {

  override func tearDown() {
    super.tearDown()

    AccessToken.current = nil
    AccessToken.connectionFactory = nil
    AccessToken.resetTokenCache()
  }

  func testAccessTokenCacheIsNilByDefault() {
    AccessToken.resetTokenCache()
    XCTAssertNil(AccessToken.tokenCache, "Access token cache should be nil by default")
  }

  func testSetTokenCache() {
    let cache = TestTokenCache(accessToken: nil, authenticationToken: nil)
    AccessToken.tokenCache = cache
    XCTAssertTrue(AccessToken.tokenCache === cache, "Access token cache should be settable")
  }

  func testRetrievingCurrentToken() {
    let cache = TestTokenCache(accessToken: nil, authenticationToken: nil)
    let testToken = SampleAccessTokens.validToken

    AccessToken.tokenCache = cache
    AccessToken.current = testToken

    XCTAssertTrue(cache.accessToken === testToken, "Setting the global access token should invoke the cache")
  }

  func testRefreshTokenThroughTestGraphRequestConnection() {
    let testConnection = TestGraphRequestConnection()
    let factory = TestGraphRequestConnectionFactory.create(withStubbedConnection: testConnection)
    AccessToken.connectionFactory = factory

    AccessToken.current = nil
    AccessToken.refreshCurrentAccessToken(nil)
    XCTAssertEqual(testConnection.startCallCount, 0, "Should not start connection if no current access token available")

    AccessToken.current = SampleAccessTokens.validToken
    AccessToken.refreshCurrentAccessToken(nil)
    XCTAssertEqual(testConnection.startCallCount, 1, "Should start one connection for refreshing")
  }
}
