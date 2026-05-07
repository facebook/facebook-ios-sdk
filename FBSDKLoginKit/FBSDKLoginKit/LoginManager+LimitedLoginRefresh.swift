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

/// The result of a successful Limited Login refresh.
public struct LimitedLoginRefreshResult {
  /// The refreshed user profile.
  public let profile: Profile
  /// The refreshed authentication token.
  public let authenticationToken: AuthenticationToken
}

// MARK: - Swift API

extension LoginManager {

  /// Refreshes a Limited Login session by obtaining an updated profile and authentication token.
  ///
  /// This method attempts to refresh the current Limited Login session without requiring the user
  /// to re-enter credentials. The behavior depends on the `fallbackPolicy`:
  /// - `.silentOnly`: Only attempts a silent background refresh.
  /// - `.explicitOnly`: Always presents a login UI for user confirmation.
  /// - `.automatic`: Tries silent refresh first, falling back to explicit login on failure.
  ///
  /// - Parameters:
  ///   - viewController: The view controller from which to present login UI if needed.
  ///     If `nil`, the topmost view controller will be used. Default: `nil`.
  ///   - fallbackPolicy: The policy for handling silent refresh failures. Default: `.automatic`.
  ///   - completion: A closure called with a `Result` containing either a
  ///     `LimitedLoginRefreshResult` on success or a `LimitedLoginRefreshError` on failure.
  @nonobjc
  public func refreshLimitedLogin(
    from viewController: UIViewController? = nil,
    fallbackPolicy: RefreshFallbackPolicy = .automatic,
    completion: @escaping (Result<LimitedLoginRefreshResult, LimitedLoginRefreshError>) -> Void
  ) {
    performRefresh(from: viewController, fallbackPolicy: fallbackPolicy) { profile, error in
      if let error = error as? LimitedLoginRefreshError {
        completion(.failure(error))
      } else if error != nil {
        completion(.failure(.networkError))
      } else if let profile = profile,
                let authenticationToken = AuthenticationToken.current {
        completion(.success(LimitedLoginRefreshResult(profile: profile, authenticationToken: authenticationToken)))
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
    performRefresh(from: viewController, fallbackPolicy: fallbackPolicy, completion: completion)
  }
}

// MARK: - Shared Implementation

extension LoginManager {

  private func performRefresh(
    from viewController: UIViewController?,
    fallbackPolicy: RefreshFallbackPolicy,
    completion: @escaping (Profile?, Error?) -> Void
  ) {
    // Precondition: AuthenticationToken.current must exist
    guard let existingToken = AuthenticationToken.current else {
      completion(nil, LimitedLoginRefreshError.noCurrentToken)
      return
    }

    // Precondition: Current profile must be a Limited Login profile.
    guard let currentProfile = Profile.current,
          currentProfile.isLimited else {
      completion(nil, LimitedLoginRefreshError.notLimitedLogin)
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
        completion: completion
      )

    case .explicitOnly:
      performExplicitRefresh(
        from: viewController,
        existingUserID: existingUserID,
        existingPermissions: existingPermissions,
        completion: completion
      )

    case .automatic:
      performSilentRefresh(
        existingToken: existingToken,
        existingUserID: existingUserID,
        existingPermissions: existingPermissions
      ) { [weak self] profile, error in
        if let error = error as? LimitedLoginRefreshError,
           error == .loginRequired || error == .consentRequired {
          self?.performExplicitRefresh(
            from: viewController,
            existingUserID: existingUserID,
            existingPermissions: existingPermissions,
            completion: completion
          )
        } else {
          completion(profile, error)
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
    let refresher = LimitedLoginRefresher()
    refresher.refresh(
      existingToken: existingToken,
      existingUserID: existingUserID,
      scopes: Array(existingPermissions)
    ) { result in
      switch result {
      case let .success(profile):
        completion(profile, nil)
      case let .failure(error):
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
