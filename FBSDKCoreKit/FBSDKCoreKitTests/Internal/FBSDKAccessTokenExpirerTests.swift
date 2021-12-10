/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
