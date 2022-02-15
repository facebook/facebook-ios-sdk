/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit
import TestTools
import XCTest

final class LoginRecoveryAttempterTests: XCTestCase {

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

  func testAttemptingRecoveryWithoutPermissions() {
    var capturedSuccess = true
    attempter.attemptRecovery(fromError: SampleError()) { success in
      capturedSuccess = success
    }

    XCTAssertNil(
      loginManager.capturedCompletion,
      "Should not attempt to log in if there are no permissions to refresh"
    )

    XCTAssertFalse(
      capturedSuccess,
      "Should complete with false if there are no permissions to refresh"
    )
  }

  func testAttemptingRecoveryFromErrorFails() throws {
    accessTokenWallet.currentAccessToken = SampleAccessTokens.create(withPermissions: ["foo"])

    let resultErrorPairs: [(result: LoginManagerLoginResult, error: Error?)] = [
      (
        result: createLoginManagerResult(isCancelled: true, declinedPermissions: []),
        error: SampleError()
      ),
      (
        result: createLoginManagerResult(isCancelled: true, declinedPermissions: ["email"]),
        error: SampleError()
      ),
      (
        result: createLoginManagerResult(isCancelled: false, declinedPermissions: []),
        error: SampleError()
      ),
      (
        result: createLoginManagerResult(isCancelled: false, declinedPermissions: ["email"]),
        error: SampleError()
      ),
      (
        result: createLoginManagerResult(isCancelled: true, declinedPermissions: []),
        error: nil
      ),
      (
        result: createLoginManagerResult(isCancelled: true, declinedPermissions: ["email"]),
        error: nil
      ),
      (
        result: createLoginManagerResult(isCancelled: false, declinedPermissions: ["email"]),
        error: nil
      ),
    ]

    try resultErrorPairs.forEach { pair in
      var capturedSuccess = true
      attempter.attemptRecovery(fromError: SampleError()) { success in
        capturedSuccess = success
      }

      let completion = try XCTUnwrap(loginManager.capturedCompletion)
      completion(pair.result, pair.error)

      let success = try XCTUnwrap(capturedSuccess)
      XCTAssertFalse(success)
    }
  }

  func testAttemptingRecoveryFromErrorSucceeds() throws {
    accessTokenWallet.currentAccessToken = SampleAccessTokens.create(withPermissions: ["foo"])

    var capturedSuccess = false
    attempter.attemptRecovery(fromError: SampleError()) { success in
      capturedSuccess = success
    }

    let completion = try XCTUnwrap(loginManager.capturedCompletion)
    completion(createLoginManagerResult(isCancelled: false, declinedPermissions: []), nil)

    let success = try XCTUnwrap(capturedSuccess)
    XCTAssertTrue(success)
  }

  func createLoginManagerResult(isCancelled: Bool, declinedPermissions: [String]) -> LoginManagerLoginResult {
    LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: SampleAuthenticationToken.validToken,
      isCancelled: isCancelled,
      grantedPermissions: [],
      declinedPermissions: Set(declinedPermissions)
    )
  }
}
