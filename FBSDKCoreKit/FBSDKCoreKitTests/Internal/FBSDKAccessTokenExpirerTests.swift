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

#if BUCK
import FacebookCore
#endif

import TestTools
import XCTest

class FBSDKAccessTokenExpirerTests: XCTestCase {

  let center = TestNotificationCenter()
  lazy var expirer = AccessTokenExpirer(notificationCenter: center)

  override class func setUp() {
    super.setUp()

    AccessToken.current = nil
  }

  override func setUp() {
    super.setUp()

    expirer = AccessTokenExpirer(notificationCenter: center)
  }

  override func tearDown() {
    super.tearDown()

    AccessToken.current = nil
  }

  func testCreating() {
    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: expirer as Any,
          name: .AccessTokenDidChange,
          selector: #selector(expirer._checkAccessTokenExpirationDate),
          object: nil
        )
      ),
      "Should check the access token expiration date when the shared token changes"
    )
    XCTAssertTrue(
      center.capturedAddObserverInvocations.contains(
        TestNotificationCenter.ObserverEvidence(
          observer: expirer as Any,
          name: .FBSDKApplicationDidBecomeActive,
          selector: #selector(expirer._checkAccessTokenExpirationDate),
          object: nil
        )
      ),
      "Should check the access token when the application becomes active"
    )
  }

  func testTimerFiring() throws {
    AccessToken.current = SampleAccessTokens.validToken

    expirer._timerDidFire()

    let userInfo = try XCTUnwrap(center.capturedPostUserInfos.first)

    XCTAssertEqual(
      center.capturedPostNames.first,
      .AccessTokenDidChange,
      "Should post about the updated access token when it changes"
    )
    XCTAssertEqual(
      userInfo[AccessTokenChangeNewKey] as? AccessToken,
      SampleAccessTokens.validToken,
      "Should include the new access token in the user info"
    )
    XCTAssertEqual(
      userInfo[AccessTokenChangeOldKey] as? AccessToken,
      SampleAccessTokens.validToken,
      "It will include the current token under the 'old' token key. This is probably wrong"
    )
    let didExpire = try XCTUnwrap(userInfo[AccessTokenDidExpireKey] as? Bool)

    XCTAssertTrue(
      didExpire,
      "The user info should include the information that the access token was expired"
    )
  }
}
