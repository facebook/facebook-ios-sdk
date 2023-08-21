/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices

@testable import FBSDKCoreKit

@available(iOS 13.0, *)
@objcMembers
final class AuthenticationSessionSpy: NSObject, AuthenticationSessionProtocol {

  var capturedURL: URL
  var capturedCallbackURLScheme: String?
  var capturedCompletionHandler: AuthenticationCompletionHandler?
  var startCallCount = 0
  var cancelCallCount = 0
  var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?

  static func makeDefaultSpy() -> AuthenticationSessionSpy {
    guard let url = URL(string: "http://example.com") else { fatalError("Url creation failed") }

    return AuthenticationSessionSpy(url: url, callbackURLScheme: nil) { _, _ in }
  }

  init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping (URL?, Error?) -> Void
  ) {
    capturedURL = url
    capturedCallbackURLScheme = callbackURLScheme
    capturedCompletionHandler = completionHandler
  }

  func start() -> Bool {
    startCallCount += 1
    return true
  }

  func cancel() {
    cancelCallCount += 1
  }
}
