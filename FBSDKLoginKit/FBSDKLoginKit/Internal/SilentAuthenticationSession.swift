/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

/// Configuration for silent authentication timeouts.
enum SilentAuthTimeout {
  /// Maximum time to wait for the silent authentication session to complete.
  static let requestTimeout: TimeInterval = 30.0
}

/// Completion handler for authentication session callbacks.
typealias SilentAuthCompletionHandler = (URL?, Error?) -> Void

/// Protocol abstracting `ASWebAuthenticationSession` for testability.
@available(iOS 13.0, *)
protocol SilentAuthSessionProviding {
  init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping SilentAuthCompletionHandler
  )

  func start() -> Bool
  func cancel()

  var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? { get set }
}

@available(iOS 13.0, *)
extension ASWebAuthenticationSession: SilentAuthSessionProviding {}

/// Manages a silent `ASWebAuthenticationSession` for OIDC token refresh with `prompt=none`.
///
/// This class wraps `ASWebAuthenticationSession` to perform a background authentication
/// request that leverages existing Facebook session cookies. The session is configured
/// with `prefersEphemeralWebBrowserSession = false` so that shared cookies are available.
///
/// ## Testability
/// Accepts a `sessionProvider` factory closure so tests can inject a mock
/// `SilentAuthSessionProviding` instead of a real `ASWebAuthenticationSession`.
@available(iOS 13.0, *)
final class SilentAuthenticationSession: NSObject, ASWebAuthenticationPresentationContextProviding {

  typealias CompletionHandler = (Result<URL, LimitedLoginRefreshError>) -> Void
  typealias SessionProvider = (
    URL, String?, @escaping SilentAuthCompletionHandler
  ) -> SilentAuthSessionProviding

  private var authSession: SilentAuthSessionProviding?
  private var completion: CompletionHandler?
  private var timeoutWorkItem: DispatchWorkItem?
  private let sessionProvider: SessionProvider

  /// Creates a new silent authentication session.
  ///
  /// - Parameter sessionProvider: Factory that creates a `SilentAuthSessionProviding`.
  ///   Defaults to creating a real `ASWebAuthenticationSession`.
  init(sessionProvider: @escaping SessionProvider = { url, scheme, handler in
    ASWebAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
  }) {
    self.sessionProvider = sessionProvider
  }

  /// Starts the silent authentication session.
  ///
  /// - Parameters:
  ///   - url: The OIDC authorization URL (must include `prompt=none`).
  ///   - callbackURLScheme: The custom URL scheme registered for the callback.
  ///   - completion: Called with `.success(url)` on success or a typed error on failure.
  func start(
    url: URL,
    callbackURLScheme: String,
    completion: @escaping CompletionHandler
  ) {
    self.completion = completion
    startTimeoutTimer()

    var session = sessionProvider(url, callbackURLScheme) { [weak self] callbackURL, error in
      self?.handleCallback(url: callbackURL, error: error)
    }

    // CRITICAL: Must be false to use existing Facebook session cookies.
    // Only set on actual ASWebAuthenticationSession (protocol does not expose this property).
    if let webSession = session as? ASWebAuthenticationSession {
      webSession.prefersEphemeralWebBrowserSession = false
    }

    session.presentationContextProvider = self
    authSession = session

    if !session.start() {
      cancelTimeoutTimer()
      self.completion?(.failure(.networkError))
      self.completion = nil
    }
  }

  /// Cancels the in-progress authentication session, if any.
  func cancel() {
    cancelTimeoutTimer()
    authSession?.cancel()
    authSession = nil
    completion?(.failure(.cancelled))
    completion = nil
  }

  // MARK: - ASWebAuthenticationPresentationContextProviding

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    if #available(iOS 15.0, *) {
      let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
      if let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first {
        return window
      }
    }
    // Fallback for iOS 13–14
    return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
  }

  // MARK: - Private

  private func handleCallback(url: URL?, error: Error?) {
    cancelTimeoutTimer()

    if let error = error {
      let nsError = error as NSError
      if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
         nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
        complete(with: .failure(.cancelled))
      } else {
        complete(with: .failure(.networkError))
      }
      return
    }

    guard let url = url else {
      complete(with: .failure(.invalidResponse))
      return
    }

    complete(with: .success(url))
  }

  private func complete(with result: Result<URL, LimitedLoginRefreshError>) {
    authSession = nil
    completion?(result)
    completion = nil
  }

  private func startTimeoutTimer() {
    let workItem = DispatchWorkItem { [weak self] in
      self?.handleTimeout()
    }
    timeoutWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + SilentAuthTimeout.requestTimeout, execute: workItem)
  }

  private func cancelTimeoutTimer() {
    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil
  }

  private func handleTimeout() {
    authSession?.cancel()
    authSession = nil
    completion?(.failure(.timeout))
    completion = nil
  }
}
