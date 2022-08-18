/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

final class TestWebAuthenticationSessionFactory: WebAuthenticationSessionCreating {
  let stubbedSession: TestWebAuthenticationSession

  init(stubbedSession: TestWebAuthenticationSession) {
    self.stubbedSession = stubbedSession
  }

  var capturedURL: URL?
  var capturedCallbackURLScheme: String?
  var capturedCompletionHandler: AuthenticationDialogPresenting.CompletionHandler?

  func createWebAuthenticationSession(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping AuthenticationDialogPresenting.CompletionHandler
  ) -> WebAuthenticationSession {
    capturedURL = url
    capturedCallbackURLScheme = callbackURLScheme
    capturedCompletionHandler = completionHandler
    return stubbedSession
  }
}
