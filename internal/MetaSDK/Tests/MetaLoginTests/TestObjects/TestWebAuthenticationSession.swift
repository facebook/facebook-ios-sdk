/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import AuthenticationServices
import Foundation

final class TestWebAuthenticationSession: WebAuthenticationSession {
  var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

  init(stubbedPresentationContextProvider: TestWebAuthenticationSessionPresentationContextProvider) {
    presentationContextProvider = stubbedPresentationContextProvider
  }

  var startWasCalled = false

  func start() -> Bool {
    startWasCalled = true
    return true
  }
}
