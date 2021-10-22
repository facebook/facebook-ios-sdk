/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
class AuthenticationSessionSpy: NSObject, AuthenticationSessionHandling {

  var capturedUrl: URL
  var capturedCallbackUrlScheme: String?
  var capturedCompletionHandler: FBSDKAuthenticationCompletionHandler?
  var startCallCount = 0
  var cancelCallCount = 0

  static var makeDefaultSpy: AuthenticationSessionSpy {
    guard let url = URL(string: "http://example.com") else { fatalError("Url creation failed") }

    return AuthenticationSessionSpy(url: url, callbackURLScheme: nil) { _, _ in }
  }

  required init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping FBSDKAuthenticationCompletionHandler
  ) {
    capturedUrl = url
    capturedCallbackUrlScheme = callbackURLScheme
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
