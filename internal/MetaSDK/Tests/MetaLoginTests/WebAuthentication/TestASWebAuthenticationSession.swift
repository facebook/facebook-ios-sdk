/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin

import AuthenticationServices

final class TestASWebAuthenticationSession: ASWebAuthenticationSession {

  static let defaultURL = URL(string: "https://facebook.com/auth")!
  static let defaultCallbackURLScheme = "auth"

  // MARK: Initialization

  var url: URL?
  var callbackURLScheme: String?
  var completionHandler: ASWebAuthenticationSession.CompletionHandler?

  convenience init() {
    self.init(
      url: Self.defaultURL,
      callbackURLScheme: Self.defaultCallbackURLScheme
    ) { _, _ in }
  }

  override init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
  ) {
    self.url = url
    self.callbackURLScheme = callbackURLScheme
    self.completionHandler = completionHandler
    super.init(url: url, callbackURLScheme: callbackURLScheme) { _, _ in }
  }

  // MARK: Starting

  var wasStartCalled = false
  var shouldStartSucceed = true
  var autocompleteArguments: (URL?, Error?)?

  @discardableResult
  override func start() -> Bool {
    wasStartCalled = true

    if shouldStartSucceed {
      completeAuthenticationIfNeeded()
    }

    return shouldStartSucceed
  }

  func completeAuthenticationIfNeeded() {
    guard
      let arguments = autocompleteArguments,
      let handler = completionHandler
    else { return }

    autocompleteArguments = nil
    completionHandler = nil

    Task {
      try await Task.sleep(nanoseconds: 10_000)
      handler(arguments.0, arguments.1)
    }
  }
}
