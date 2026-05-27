/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import UIKit

// MARK: - Result Type

/// Which refresh subroutine produced a `LimitedLoginRefreshResult`. Always
/// matches the requested `fallbackPolicy` for `.directOnly` / `.silentOnly` /
/// `.explicitOnly`; for `.automatic` it identifies whichever tier of the
/// cascade succeeded.
public enum RefreshPath: String {
  case direct
  case silent
  case explicit
}

/// The result of a successful Limited Login refresh.
public struct LimitedLoginRefreshResult {
  /// The refreshed user profile.
  public let profile: Profile
  /// The refreshed authentication token.
  public let authenticationToken: AuthenticationToken
  /// Which subroutine produced this result. For `.automatic`, identifies the
  /// tier of the cascade that succeeded.
  public let path: RefreshPath
}

// MARK: - Swift API

extension LoginManager {

  /// Refreshes a Limited Login session by obtaining an updated profile and authentication token.
  ///
  /// This method attempts to refresh the current Limited Login session. The behavior depends
  /// on the `fallbackPolicy`:
  /// - `.directOnly`: A truly silent DPoP-bound HTTPS POST. No user-visible UI. Requires the
  ///   current token to carry a `cnf.jkt` claim; otherwise returns `.notDPoPBound`.
  /// - `.silentOnly`: A `prompt=none` OIDC flow via `ASWebAuthenticationSession`. Shows the
  ///   Apple system permission modal but no Facebook UI.
  /// - `.explicitOnly`: A standard Limited Login dialog. The user re-authenticates through
  ///   the normal login flow.
  /// - `.automatic`: Cascades through the three above. Tries direct first; on any failure
  ///   other than `.featureDisabled`, falls back to silent (which sends `dpop_jkt` to mint
  ///   a fresh bound token, so it can recover from `.notDPoPBound` as well as transient
  ///   direct failures); if silent returns `.loginRequired` or `.consentRequired`, falls
  ///   back to explicit. `.featureDisabled` is never recovered from — the kill switch is
  ///   respected.
  ///
  /// - Parameters:
  ///   - viewController: The view controller from which to present login UI if needed.
  ///     If `nil`, the topmost view controller will be used. Default: `nil`.
  ///   - fallbackPolicy: The refresh strategy. Default: `.automatic`.
  ///   - completion: A closure called with a `Result` containing either a
  ///     `LimitedLoginRefreshResult` on success or a `LimitedLoginRefreshError` on failure.
  @nonobjc
  public func refreshLimitedLogin(
    from viewController: UIViewController? = nil,
    fallbackPolicy: RefreshFallbackPolicy = .automatic,
    completion: @escaping (Result<LimitedLoginRefreshResult, LimitedLoginRefreshError>) -> Void
  ) {
    performRefresh(from: viewController, fallbackPolicy: fallbackPolicy) { profile, path, error in
      if let error = error as? LimitedLoginRefreshError {
        completion(.failure(error))
      } else if error != nil {
        completion(.failure(.networkError))
      } else if let profile = profile,
                let authenticationToken = AuthenticationToken.current,
                let path = path {
        completion(.success(LimitedLoginRefreshResult(
          profile: profile,
          authenticationToken: authenticationToken,
          path: path
        )))
      } else {
        completion(.failure(.unknown))
      }
    }
  }
}

// MARK: - ObjC API

extension LoginManager {

  /// Refreshes a Limited Login session by obtaining an updated profile and authentication token.
  ///
  /// This is the Objective-C compatible version of `refreshLimitedLogin(from:fallbackPolicy:completion:)`.
  ///
  /// @param viewController The view controller from which to present login UI if needed.
  ///   If nil, the topmost view controller will be used.
  /// @param fallbackPolicy The policy for handling silent refresh failures.
  /// @param completion A closure called with the refreshed `Profile` on success, or an error on failure.
  @available(swift, obsoleted: 0.1)
  @objc(refreshLimitedLoginFromViewController:fallbackPolicy:completion:)
  public func refreshLimitedLogin(
    from viewController: UIViewController?,
    fallbackPolicy: RefreshFallbackPolicy,
    completion: @escaping (Profile?, Error?) -> Void
  ) {
    // ObjC consumers don't get path attribution — drop the middle arg.
    performRefresh(from: viewController, fallbackPolicy: fallbackPolicy) { profile, _, error in
      completion(profile, error)
    }
  }
}

// MARK: - Shared Implementation

extension LoginManager {

  /// Test seam for the direct refresh network call. Production routes to
  /// `DirectRefreshSession.refresh`; tests replace this with a closure that
  /// returns a canned `Result`. Reset in tearDown.
  typealias DirectRefreshPerformer = (
    _ idTokenHint: String,
    _ appID: String,
    _ completion: @escaping (Result<String, LimitedLoginRefreshError>) -> Void
  ) -> Void

  static var directRefreshPerformer: DirectRefreshPerformer = { idTokenHint, appID, completion in
    if #available(iOS 13.0, *) {
      DirectRefreshSession().refresh(idTokenHint: idTokenHint, appID: appID, completion: completion)
    } else {
      completion(.failure(.unsupportedPlatform))
    }
  }

  /// Test seam: extracts the `cnf.jkt` claim from the bound id_token. Production
  /// reads the JWT payload via `JWT.payload(from:)` rather than
  /// `AuthenticationToken.claims()`, because the latter rejects tokens older than
  /// 10 minutes via temporal validation — and `.directOnly` exists specifically to
  /// refresh stale tokens. Reading `cnf.jkt` is a structural concern, independent
  /// of token freshness. Tests can inject a closure that returns a thumbprint
  /// (or nil) directly.
  static var directRefreshCnfJktExtractor: (AuthenticationToken) -> String? = { token in
    guard let payload = JWT.payload(from: token.tokenString),
          let cnf = payload["cnf"] as? [String: Any],
          let jkt = cnf["jkt"] as? String,
          !jkt.isEmpty
    else { return nil }
    return jkt
  }

  private func performRefresh(
    from viewController: UIViewController?,
    fallbackPolicy: RefreshFallbackPolicy,
    completion: @escaping (Profile?, RefreshPath?, Error?) -> Void
  ) {
    // Ensure BackgroundRefreshManager is initialized so its foreground
    // notification observer is registered for future auto-refreshes.
    _ = BackgroundRefreshManager.shared

    // Precondition: AuthenticationToken.current must exist
    guard let existingToken = AuthenticationToken.current else {
      completion(nil, nil, LimitedLoginRefreshError.noCurrentToken)
      return
    }

    // Precondition: Current profile must be a Limited Login profile.
    guard let currentProfile = Profile.current,
          currentProfile.isLimited else {
      completion(nil, nil, LimitedLoginRefreshError.notLimitedLogin)
      return
    }

    let existingUserID = currentProfile.userID
    let existingPermissions = currentProfile.permissions ?? []

    switch fallbackPolicy {
    case .silentOnly:
      performSilentRefresh(
        existingToken: existingToken,
        existingUserID: existingUserID,
        existingPermissions: existingPermissions,
        completion: tagging(.silent, completion)
      )

    case .explicitOnly:
      performExplicitRefresh(
        from: viewController,
        existingUserID: existingUserID,
        existingPermissions: existingPermissions,
        completion: tagging(.explicit, completion)
      )

    case .directOnly:
      performDirectRefresh(
        existingToken: existingToken,
        existingUserID: existingUserID,
        completion: tagging(.direct, completion)
      )

    case .automatic:
      performAutomaticCascade(
        viewController: viewController,
        existingToken: existingToken,
        existingUserID: existingUserID,
        existingPermissions: existingPermissions,
        completion: completion
      )
    }
  }

  /// Wraps a leaf-method `(Profile?, Error?)` callback so it forwards `path`
  /// only on success, matching the cascade's contract.
  private func tagging(
    _ path: RefreshPath,
    _ completion: @escaping (Profile?, RefreshPath?, Error?) -> Void
  ) -> (Profile?, Error?) -> Void {
    { profile, error in
      completion(profile, error == nil ? path : nil, error)
    }
  }

  /// Three-tier cascade: direct → silent → explicit.
  ///
  /// - Direct succeeds → done.
  /// - Direct returns `.featureDisabled` → surface, do NOT cascade (kill switch).
  /// - Direct returns any other failure (including `.notDPoPBound`) → try silent.
  ///   Silent attaches `dpop_jkt` to mint a freshly bound token, so it can recover
  ///   both from missing-binding and from transient failures on the direct endpoint.
  /// - Silent returns `.loginRequired` or `.consentRequired` → fall back to explicit.
  /// - Silent returns `.featureDisabled` → surface, do NOT cascade.
  /// - Silent succeeds, or fails for any other reason → propagate.
  private func performAutomaticCascade(
    viewController: UIViewController?,
    existingToken: AuthenticationToken,
    existingUserID: String,
    existingPermissions: Set<String>,
    completion: @escaping (Profile?, RefreshPath?, Error?) -> Void
  ) {
    performDirectRefresh(
      existingToken: existingToken,
      existingUserID: existingUserID
    ) { directProfile, directError in
      if directError == nil {
        completion(directProfile, .direct, nil)
        return
      }

      if case .featureDisabled = directError as? LimitedLoginRefreshError {
        // Kill switch is active — do not attempt other paths.
        completion(directProfile, nil, directError)
        return
      }

      self.performSilentRefresh(
        existingToken: existingToken,
        existingUserID: existingUserID,
        existingPermissions: existingPermissions
      ) { silentProfile, silentError in
        switch silentError as? LimitedLoginRefreshError {
        case .loginRequired, .consentRequired:
          self.performExplicitRefresh(
            from: viewController,
            existingUserID: existingUserID,
            existingPermissions: existingPermissions,
            completion: self.tagging(.explicit, completion)
          )
        default:
          completion(silentProfile, silentError == nil ? .silent : nil, silentError)
        }
      }
    }
  }

  private func performSilentRefresh(
    existingToken: AuthenticationToken,
    existingUserID: String,
    existingPermissions: Set<String>,
    completion: @escaping (Profile?, Error?) -> Void
  ) {
    let retryHandler = RefreshRetryHandler()
    retryHandler.executeWithRetry(
      operation: { attemptCompletion in
        let refresher = LimitedLoginRefresher()
        refresher.refresh(
          existingToken: existingToken,
          existingUserID: existingUserID,
          scopes: Array(existingPermissions)
        ) { result in
          attemptCompletion(result)
          _ = refresher // prevent deallocation during async operation
        }
      },
      completion: { result in
        switch result {
        case let .success(profile):
          completion(profile, nil)
        case let .failure(error):
          completion(nil, error)
        }
        _ = retryHandler // prevent deallocation during retry chain
      }
    )
  }

  private func performDirectRefresh(
    existingToken: AuthenticationToken,
    existingUserID: String,
    completion: @escaping (Profile?, Error?) -> Void
  ) {
    guard #available(iOS 13.0, *) else {
      completion(nil, LimitedLoginRefreshError.unsupportedPlatform)
      return
    }

    // Reuse the silent-path GateKeeper so the direct path can be rolled out together.
    guard Self.directRefreshIsEnabled() else {
      completion(nil, LimitedLoginRefreshError.featureDisabled)
      return
    }

    guard RefreshRateLimiter.shared.canAttemptRefresh() else {
      completion(nil, LimitedLoginRefreshError.rateLimited)
      return
    }

    // The direct path requires the existing token to carry a `cnf.jkt` claim.
    // If it doesn't, surface `.notDPoPBound` so callers (notably `.automatic`)
    // can route directly to explicit refresh — silent refresh wouldn't help
    // because it doesn't bind keys; only a fresh login does.
    guard Self.directRefreshCnfJktExtractor(existingToken) != nil else {
      completion(nil, LimitedLoginRefreshError.notDPoPBound)
      return
    }

    guard let dependencies = try? getDependencies(),
          let appID = dependencies.settings.appID,
          !appID.isEmpty
    else {
      completion(nil, LimitedLoginRefreshError.unknown)
      return
    }

    RefreshRateLimiter.shared.recordAttempt()

    Self.directRefreshPerformer(existingToken.tokenString, appID) { result in
      switch result {
      case let .success(newTokenString):
        let refresher = LimitedLoginRefresher()
        refresher.processRefreshedToken(
          newTokenString,
          nonce: existingToken.nonce,
          existingUserID: existingUserID
        ) { processResult in
          switch processResult {
          case let .success(profile):
            RefreshRateLimiter.shared.recordSuccess()
            completion(profile, nil)
          case let .failure(error):
            RefreshRateLimiter.shared.recordFailure()
            completion(nil, error)
          }
          _ = refresher // keep refresher alive across async work
        }
      case let .failure(error):
        RefreshRateLimiter.shared.recordFailure()
        completion(nil, error)
      }
    }
  }

  private func performExplicitRefresh(
    from viewController: UIViewController?,
    existingUserID: String,
    existingPermissions: Set<String>,
    completion: @escaping (Profile?, Error?) -> Void
  ) {
    // Save current state for potential revert
    let savedProfile = Profile.current
    let savedAuthenticationToken = AuthenticationToken.current

    // Build configuration for limited login with same permissions
    let permissionsArray = Array(existingPermissions)
    guard let configuration = LoginConfiguration(
      permissions: permissionsArray,
      tracking: .limited,
      nonce: UUID().uuidString,
      messengerPageId: nil,
      authType: nil
    ) else {
      completion(nil, LimitedLoginRefreshError.unknown)
      return
    }

    // Use the Swift logIn API (LoginResult enum)
    logIn(viewController: viewController, configuration: configuration) { [weak self] loginResult in
      switch loginResult {
      case .cancelled:
        Profile.current = savedProfile
        AuthenticationToken.current = savedAuthenticationToken
        completion(nil, LimitedLoginRefreshError.cancelled)

      case .failed:
        Profile.current = savedProfile
        AuthenticationToken.current = savedAuthenticationToken
        completion(nil, LimitedLoginRefreshError.networkError)

      case .success:
        // Login succeeded — validate user ID.
        // At this point, setGlobalProperties has already set
        // Profile.current and AuthenticationToken.current to the new values.
        guard let newProfile = Profile.current,
              newProfile.userID == existingUserID else {
          // SECURITY: User ID mismatch — revert to saved state
          Profile.current = savedProfile
          AuthenticationToken.current = savedAuthenticationToken
          completion(nil, LimitedLoginRefreshError.userMismatch)
          return
        }

        completion(newProfile, nil)
      }
      _ = self // prevent premature deallocation
    }
  }
}
