/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import TestTools
import XCTest

final class LoginRecoveryAttempterTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var attempter: _LoginRecoveryAttempter!
  var loginProvider: TestLoginProvider!
  var accessTokenWallet: TestAccessTokenWallet.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    loginProvider = TestLoginProvider()
    accessTokenWallet = TestAccessTokenWallet.self
    attempter = _LoginRecoveryAttempter()
    _LoginRecoveryAttempter.setDependencies(
      .init(
        loginProvider: loginProvider,
        accessTokenProvider: accessTokenWallet
      )
    )
  }

  override func tearDown() {
    accessTokenWallet.reset()
    loginProvider = nil
    attempter = nil
    _LoginRecoveryAttempter.resetDependencies()
    super.tearDown()
  }

  func testCreatingWithDefaultDependencies() throws {
    _LoginRecoveryAttempter.resetDependencies()

    let dependencies = try _LoginRecoveryAttempter.getDependencies()

    XCTAssertTrue(
      dependencies.accessTokenProvider is AccessToken.Type,
      .defaultDependency("AccessToken", for: "access token wallet")
    )

    XCTAssertTrue(
      dependencies.loginProvider is LoginManager,
      .defaultDependency("LoginManager", for: "login provider")
    )
  }

  func testCreatingWithCustomDependencies() throws {

    let dependencies = try _LoginRecoveryAttempter.getDependencies()

    XCTAssertIdentical(
      dependencies.accessTokenProvider,
      accessTokenWallet,
      .customDependency(for: "access token provider")
    )

    XCTAssertIdentical(
      dependencies.loginProvider,
      loginProvider,
      .customDependency(for: "login provider")
    )
  }

  func testAttemptingRecoveryWithoutPermissions() {
    var capturedSuccess = true
    attempter.attemptRecovery(fromError: SampleError()) { success in
      capturedSuccess = success
    }

    XCTAssertNil(
      loginProvider.capturedCompletion,
      "Should not attempt to log in if there are no permissions to refresh"
    )

    XCTAssertFalse(
      capturedSuccess,
      "Should complete with false if there are no permissions to refresh"
    )
  }

  func testAttemptingRecoveryFromErrorFails() throws {
    accessTokenWallet.current = SampleAccessTokens.create(withPermissions: ["foo"])

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

      let completion = try XCTUnwrap(loginProvider.capturedCompletion)
      completion(pair.result, pair.error)

      let success = try XCTUnwrap(capturedSuccess)
      XCTAssertFalse(success)
    }
  }

  func testAttemptingRecoveryFromErrorSucceeds() throws {
    accessTokenWallet.current = SampleAccessTokens.create(withPermissions: ["foo"])

    var capturedSuccess = false
    attempter.attemptRecovery(fromError: SampleError()) { success in
      capturedSuccess = success
    }

    let completion = try XCTUnwrap(loginProvider.capturedCompletion)
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

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The _LoginRecoveryAttempter type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The _LoginRecoveryAttempter type uses a custom \(type) dependency when provided"
  }
}
