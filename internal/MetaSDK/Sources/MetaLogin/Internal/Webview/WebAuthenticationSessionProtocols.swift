/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

protocol WebAuthenticationSessionCreating {
  func createWebAuthenticationSession(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping AuthWebViewCompletion
  ) -> WebAuthenticationSession
}

protocol WebAuthenticationSession {
  var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? { get set }

  @discardableResult
  func start() -> Bool
}

protocol AuthenticationSessionStatePersisting {
  var authenticationSessionState: AuthenticationSessionState { get set }
}

protocol AuthenticationSessionWebView {
  func openURL(url: URL, callbackURLScheme: String, completion: @escaping AuthWebViewCompletion)
}

extension ASWebAuthenticationSession: WebAuthenticationSession {}
