/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

typealias AuthWebViewCompletion = (Result<URL, Error>) -> Void

struct AuthWebView: AuthenticationSessionWebView {
  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    webAuthenticationSessionFactory: WebAuthenticationSessionFactory(),
    presentationContextProvider: WebAuthenticationSessionPresentationContextProvider(),
    localStorage: LocalStorage()
  )

  func openURL(
    url: URL,
    callbackURLScheme: String,
    completion: @escaping AuthWebViewCompletion
  ) {
    guard var dependencies = try? getDependencies() else { return }

    let wrappedCompletion: AuthWebViewCompletion = { result in
      switch result {
      case .success:
        break
      case .failure:
        dependencies.localStorage.authenticationSessionState = .canceled
      }

      completion(result)
    }

    var session = dependencies.webAuthenticationSessionFactory.createWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackURLScheme,
      completionHandler: wrappedCompletion
    )

    session.presentationContextProvider = dependencies.presentationContextProvider

    let sessionStarted = session.start()

    if sessionStarted {
      dependencies.localStorage.authenticationSessionState = .performingLogin
    }
  }
}

extension AuthWebView: DependentAsInstance {
  struct InstanceDependencies {
    var webAuthenticationSessionFactory: WebAuthenticationSessionCreating
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding
    var localStorage: AuthenticationSessionStatePersisting
  }
}
