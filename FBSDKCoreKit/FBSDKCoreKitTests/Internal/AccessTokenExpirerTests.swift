/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class AccessTokenExpirerTests: XCTestCase {

  let center = TestNotificationCenter()
  lazy var expirer = _AccessTokenExpirer(notificationCenter: center)

  override class func setUp() {
    super.setUp()

    AccessToken.current = nil
  }

  override func setUp() {
    super.setUp()

    AccessToken.current = nil
    expirer = _AccessTokenExpirer(notificationCenter: center)
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
          selector: #selector(expirer.checkAccessTokenExpirationDate),
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
          selector: #selector(expirer.checkAccessTokenExpirationDate),
          object: nil
        )
      ),
      "Should check the access token when the application becomes active"
    )
  }

  func testTimerFiresForValidToken() {
    let expectation = expectation(description: "Expiration notification posted")

    let realCenter = NotificationCenter()
    AccessToken.current = makeToken(expirationDate: Date(timeIntervalSinceNow: 0.1))

    let observer = realCenter.fb_addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: .main
    ) { notification in
      if notification.userInfo?[AccessTokenDidExpireKey] as? Bool == true {
        expectation.fulfill()
      }
    }

    let testExpirer = _AccessTokenExpirer(notificationCenter: realCenter)
    _ = testExpirer

    waitForExpectations(timeout: 2)
    realCenter.fb_removeObserver(observer)
  }

  func testTimerDoesNotFireForExpiredToken() {
    let notFiredExpectation = expectation(description: "Should not fire")
    notFiredExpectation.isInverted = true

    let realCenter = NotificationCenter()
    AccessToken.current = makeToken(expirationDate: .distantPast)

    let observer = realCenter.fb_addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: .main
    ) { notification in
      if notification.userInfo?[AccessTokenDidExpireKey] as? Bool == true {
        notFiredExpectation.fulfill()
      }
    }

    let testExpirer = _AccessTokenExpirer(notificationCenter: realCenter)
    _ = testExpirer

    waitForExpectations(timeout: 0.5)
    realCenter.fb_removeObserver(observer)
  }

  func testTimerDoesNotFireForNilToken() {
    let notFiredExpectation = expectation(description: "Should not fire")
    notFiredExpectation.isInverted = true

    let realCenter = NotificationCenter()
    AccessToken.current = nil

    let observer = realCenter.fb_addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: .main
    ) { notification in
      if notification.userInfo?[AccessTokenDidExpireKey] as? Bool == true {
        notFiredExpectation.fulfill()
      }
    }

    let testExpirer = _AccessTokenExpirer(notificationCenter: realCenter)
    _ = testExpirer

    waitForExpectations(timeout: 0.5)
    realCenter.fb_removeObserver(observer)
  }

  func testTimerResetWhenTokenChanges() {
    let firstFired = expectation(description: "First timer should not fire")
    firstFired.isInverted = true

    let realCenter = NotificationCenter()
    AccessToken.current = makeToken(expirationDate: Date(timeIntervalSinceNow: 0.3))

    let testExpirer = _AccessTokenExpirer(notificationCenter: realCenter)

    let observer = realCenter.fb_addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: .main
    ) { notification in
      if notification.userInfo?[AccessTokenDidExpireKey] as? Bool == true {
        firstFired.fulfill()
      }
    }

    // Clear token — should invalidate the pending timer
    AccessToken.current = nil
    testExpirer.checkAccessTokenExpirationDate()

    // Wait past when the original timer would have fired
    waitForExpectations(timeout: 0.6)
    realCenter.fb_removeObserver(observer)
  }

  // MARK: - Helpers

  private func makeToken(expirationDate: Date? = Date(timeIntervalSinceNow: 100)) -> AccessToken {
    AccessToken(
      tokenString: "token",
      permissions: [],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: "appID",
      userID: "userID",
      expirationDate: expirationDate,
      refreshDate: nil,
      dataAccessExpirationDate: nil
    )
  }

  func testTimerFiring() throws {
    AccessToken.current = SampleAccessTokens.validToken

    expirer.timerDidFire()

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
