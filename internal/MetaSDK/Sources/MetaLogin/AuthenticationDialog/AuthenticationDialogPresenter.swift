/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

final class AuthenticationDialogPresenter: AuthenticationDialogPresenting {
  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    webAuthenticationSessionFactory: WebAuthenticationSessionFactory(),
    presentationContextProvider: WebAuthenticationSessionPresentationContextProvider(),
    localStorage: LocalStorage()
  )

  func presentAuthenticationDialog(
    url: URL,
    callbackURLScheme: String,
    completion: @escaping CompletionHandler
  ) {
    guard var dependencies = try? getDependencies() else { return }

    let wrappedCompletion: CompletionHandler = { result in
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

extension AuthenticationDialogPresenter: DependentAsInstance {
  struct InstanceDependencies {
    var webAuthenticationSessionFactory: WebAuthenticationSessionCreating
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding
    var localStorage: AuthenticationSessionStatePersisting
  }
}
