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
    authenticationSessionStateStore: AuthenticationSessionStateStore()
  )

  func presentAuthenticationDialog(
    url: URL,
    callbackURLScheme: String,
    completion: @escaping CompletionHandler
  ) {
    guard let dependencies = try? getDependencies() else { return }

    let wrappedCompletion: CompletionHandler = { result in
      switch result {
      case .success:
        break
      case .failure:
        // TODO: replace completion handler to async method
        Task {
          await dependencies.authenticationSessionStateStore.setAuthenticationSessionState(.canceled)
        }
      case .cancel:
        Task {
          await dependencies.authenticationSessionStateStore.setAuthenticationSessionState(.canceled)
        }
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
      Task {
        await dependencies.authenticationSessionStateStore.setAuthenticationSessionState(.performingLogin)
      }
    }
  }
}

extension AuthenticationDialogPresenter: DependentAsInstance {
  struct InstanceDependencies {
    var webAuthenticationSessionFactory: WebAuthenticationSessionCreating
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding
    var authenticationSessionStateStore: AuthenticationSessionStatePersisting
  }
}
