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

class AuthenticationTokenTests: XCTestCase {
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
