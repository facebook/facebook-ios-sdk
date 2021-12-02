/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit
import TestTools
import XCTest

class LoginRecoveryAttempterTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var attempter: LoginRecoveryAttempter!
  var loginManager: TestLoginProvider!
  var accessTokenWallet: TestAccessTokenWallet.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    loginManager = TestLoginProvider()
    accessTokenWallet = TestAccessTokenWallet.self
    attempter = LoginRecoveryAttempter(
      loginManager: loginManager,
      accessTokenProvider: accessTokenWallet
    )
  }

  override func tearDown() {
    accessTokenWallet.reset()
    loginManager = nil
    attempter = nil

    super.tearDown()
  }

  func testCreatingWithDefaultDependencies() {
    attempter = LoginRecoveryAttempter()

    XCTAssertTrue(
      attempter.loginManager is LoginManager,
      "Should be created with the expected default login manager"
    )
    XCTAssertTrue(
      attempter.accessTokenProvider is AccessToken.Type,
      "Should be created with the expected default access token provider"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertTrue(
      attempter.loginManager === loginManager,
      "Should be created with the provided login manager"
    )
    XCTAssertTrue(
      attempter.accessTokenProvider === accessTokenWallet,
      "Should be created with the provided access token provider"
    )
  }
}
