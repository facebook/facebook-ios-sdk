/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin

import AuthenticationServices

final class TestASWebAuthenticationSessionFactory: ASWebAuthenticationSessionFactory {
  var shouldSessionStartSucceed = true
  var autocompleteArguments: (URL?, Error?)?

  var createdSession: ASWebAuthenticationSession?

  func makeSession(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
  ) -> ASWebAuthenticationSession {
    let session = TestASWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackURLScheme,
      completionHandler: completionHandler
    )

    session.shouldStartSucceed = shouldSessionStartSucceed
    session.autocompleteArguments = autocompleteArguments
    createdSession = session
    return session
  }
}
