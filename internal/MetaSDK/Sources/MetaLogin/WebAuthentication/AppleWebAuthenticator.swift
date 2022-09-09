/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

actor AppleWebAuthenticator: WebAuthenticating {
  private var isAuthenticating = false

  var configuredDependencies: InstanceDependencies?

  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    sessionFactory: DefaultASWebAuthenticationSessionFactory(),
    presentationContextProvider: DefaultASWebAuthenticationSessionPresentationContextProvider()
  )

  func authenticate(parameters: WebAuthenticationParameters) async throws -> URL {
    guard !isAuthenticating else { throw LoginFailure.inProgress }

    isAuthenticating = true

    let dependencies = try await getDependencies()

    return try await withCheckedThrowingContinuation { continuation in
      let session = dependencies.sessionFactory.makeSession(
        url: parameters.url,
        callbackURLScheme: parameters.callbackScheme
      ) { [self] url, error in
        isAuthenticating = false

        guard let url = url else {
          return continuation.resume(with: .failure(loginFailure(from: error)))
        }

        return continuation.resume(with: .success(url))
      }

      session.presentationContextProvider = dependencies.presentationContextProvider

      if !session.start() {
        isAuthenticating = false
        return continuation.resume(with: .failure(LoginFailure.sessionStart))
      }
    }
  }

  private func loginFailure(from error: Error?) -> LoginFailure {
    switch error {
    case let error as ASWebAuthenticationSessionError:
      return loginFailure(from: error)
    default:
      return .unknown
    }
  }

  private func loginFailure(from sessionError: ASWebAuthenticationSessionError) -> LoginFailure {
    switch sessionError.code {
    case .canceledLogin:
      return .isCanceled
    case .presentationContextNotProvided,
         .presentationContextInvalid:
      return .internal(sessionError)
    @unknown default:
      return .unknown
    }
  }
}

extension AppleWebAuthenticator: DependentAsActorInstance {
  struct InstanceDependencies {
    var sessionFactory: ASWebAuthenticationSessionFactory
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding
  }

  func setDependencies(_ dependencies: InstanceDependencies) async {
    configuredDependencies = dependencies
  }

  func getDependencies() async throws -> InstanceDependencies {
    guard let dependencies = configuredDependencies ?? defaultDependencies else {
      throw MissingDependenciesError(for: Self.self)
    }

    return dependencies
  }
}
