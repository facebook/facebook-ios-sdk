/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

actor TestWebAuthenticator: WebAuthenticating {
  var parameters: WebAuthenticationParameters?
  private var responseURL: URL?
  private var error: Error?

  func setResponseURL(_ url: URL) {
    responseURL = url
  }

  func setError(_ error: Error) {
    self.error = error
  }

  func authenticate(parameters: WebAuthenticationParameters) async throws -> URL {
    self.parameters = parameters

    guard let authenticatedURL = responseURL else {
      struct TestError: Error {}
      throw error ?? TestError()
    }

    return authenticatedURL
  }
}
