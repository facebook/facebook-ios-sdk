/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation
import XCTest

final class TestAuthenticationSessionStateStore: AuthenticationSessionStatePersisting {
  var stubbedAuthenticationSessionState: AuthenticationSessionState?
  var expectationForSetter: XCTestExpectation?

  func getAuthenticationSessionState() async -> AuthenticationSessionState? {
    return stubbedAuthenticationSessionState
  }

  func setAuthenticationSessionState(_ authenticationSessionState: AuthenticationSessionState?) async {
    stubbedAuthenticationSessionState = authenticationSessionState
    expectationForSetter?.fulfill()
  }
}
