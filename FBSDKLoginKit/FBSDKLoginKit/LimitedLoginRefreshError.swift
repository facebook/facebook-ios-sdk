/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Errors that can occur during Limited Login profile refresh operations.
///
/// These errors cover all failure scenarios from the silent OIDC authentication flow,
/// including session expiration, user mismatch, network issues, and rate limiting.
@objc(FBSDKLimitedLoginRefreshError)
public enum LimitedLoginRefreshError: Int, Error, Sendable {

  /// No current AuthenticationToken exists to refresh.
  /// The user must perform a full Limited Login first.
  case noCurrentToken = 0

  /// The current profile is not a Limited Login profile.
  /// This refresh API is only applicable to Limited Login sessions.
  case notLimitedLogin

  /// The Facebook session has expired or is not available.
  /// The user must re-authenticate with a full login flow.
  /// Maps to OIDC error: `login_required`
  case loginRequired

  /// The user has revoked consent or additional consent is needed.
  /// The user must re-authorize with a full login flow.
  /// Maps to OIDC error: `consent_required`
  case consentRequired

  /// The refreshed token belongs to a different user than the current session.
  /// This is a security check to prevent session hijacking.
  /// The app should handle this by logging out the current user and prompting re-authentication.
  case userMismatch

  /// A network error occurred during the refresh request.
  /// The app may retry the operation.
  case networkError

  /// The refresh request timed out.
  /// The default timeout is 30 seconds.
  case timeout

  /// The refresh attempt was rate-limited.
  /// The app should wait before retrying. Use `RefreshRateLimiter.timeUntilNextAllowedAttempt()`
  /// to determine how long to wait.
  case rateLimited

  /// The server returned an invalid or malformed response.
  case invalidResponse

  /// The user cancelled the authentication flow.
  case cancelled

  /// Silent refresh is disabled via server-side GateKeeper.
  /// The feature may be temporarily disabled for rollout or rollback purposes.
  case featureDisabled

  /// Silent refresh requires iOS 13.0 or later.
  /// The `prefersEphemeralWebBrowserSession` API used for silent auth is only available on iOS 13+.
  case unsupportedPlatform

  /// An unknown error occurred.
  case unknown
}

// MARK: - LocalizedError Conformance

extension LimitedLoginRefreshError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .noCurrentToken:
      return "No current authentication token exists. Please log in first."
    case .notLimitedLogin:
      return "The current session is not a Limited Login session."
    case .loginRequired:
      return "Your Facebook session has expired. Please log in again."
    case .consentRequired:
      return "Additional consent is required. Please log in again."
    case .userMismatch:
      return "The refreshed profile belongs to a different user."
    case .networkError:
      return "A network error occurred. Please check your connection and try again."
    case .timeout:
      return "The request timed out. Please try again."
    case .rateLimited:
      return "Too many refresh attempts. Please wait before trying again."
    case .invalidResponse:
      return "Received an invalid response from the server."
    case .cancelled:
      return "The operation was cancelled."
    case .featureDisabled:
      return "Profile refresh is temporarily unavailable."
    case .unsupportedPlatform:
      return "Profile refresh requires iOS 13.0 or later."
    case .unknown:
      return "An unknown error occurred."
    }
  }
}

// MARK: - CustomNSError Conformance

extension LimitedLoginRefreshError: CustomNSError {

  public static var errorDomain: String {
    "com.facebook.sdk.login.refresh"
  }

  public var errorCode: Int {
    rawValue
  }

  public var errorUserInfo: [String: Any] {
    var userInfo: [String: Any] = [:]
    if let description = errorDescription {
      userInfo[NSLocalizedDescriptionKey] = description
    }
    return userInfo
  }
}

// MARK: - Refresh Fallback Policy

/// Policy for handling silent refresh failures in Limited Login.
///
/// When silent authentication fails (e.g., due to expired Facebook session),
/// this policy determines what action the SDK should take.
@objc(FBSDKRefreshFallbackPolicy)
public enum RefreshFallbackPolicy: Int, Sendable {

  /// Automatically fall back to explicit refresh if silent fails.
  /// The user may see a brief authentication UI if their Facebook session is still valid.
  case automatic = 0

  /// Only attempt silent refresh; return error if it fails.
  /// Use this when you want to avoid any user-visible UI.
  case silentOnly

  /// Skip silent refresh; always use explicit flow.
  /// Use this when you always want user confirmation.
  case explicitOnly
}
