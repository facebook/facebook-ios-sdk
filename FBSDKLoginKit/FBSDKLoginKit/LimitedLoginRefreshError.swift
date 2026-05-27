/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Errors emitted by `LoginManager.refreshLimitedLogin(...)`.
///
/// Each case names the *specific* condition the SDK detected, so a developer
/// can decide what to do without inspecting log output. The textual messages
/// returned by `errorDescription` describe the condition in actionable terms.
@objc(FBSDKLimitedLoginRefreshError)
public enum LimitedLoginRefreshError: Int, Error, Sendable {

  /// `AuthenticationToken.current` is `nil`. There is no Limited Login session to
  /// refresh — the user has either never logged in on this device or has logged out.
  case noCurrentToken = 0

  /// `Profile.current` exists but is not a Limited Login profile (`isLimited == false`).
  /// `refreshLimitedLogin` only operates on Limited Login sessions; full Login sessions
  /// use a different refresh mechanism.
  case notLimitedLogin

  /// The Facebook session backing this token has expired (or never existed for this
  /// browser session). The user must complete a full login flow to obtain a new token.
  /// Maps to OIDC error code `login_required`.
  case loginRequired

  /// The user has revoked one or more permissions, or new permissions are being
  /// requested that were not previously granted. The user must complete a full login
  /// flow to grant the missing consent. Maps to OIDC error code `consent_required`.
  case consentRequired

  /// SECURITY: the refreshed token's `sub` claim does not match the previously
  /// authenticated user's ID. The SDK refused to swap in the new token to prevent
  /// session hijacking. Treat this as a state inconsistency: log the user out and
  /// require a fresh login.
  case userMismatch

  /// A transport-level network error occurred (DNS failure, connection reset,
  /// TLS handshake failure, etc.). Safe to retry once connectivity is restored.
  case networkError

  /// The refresh request did not complete within the SDK's timeout (30 seconds).
  /// Safe to retry. Repeated timeouts may indicate a backend or network issue.
  case timeout

  /// The client-side rate limiter is throttling refresh attempts. Inspect
  /// `RefreshRateLimiter.shared.timeUntilNextAllowedAttempt()` to know how long
  /// to wait before retrying.
  case rateLimited

  /// The server returned a 2xx response, but its body could not be parsed as the
  /// expected refresh response (missing `id_token` field, malformed JSON, or claims
  /// that fail OIDC structural validation such as missing `iss`/`aud`/`nonce`/`sub`).
  /// Indicates a server-side issue or a protocol drift; not retryable client-side.
  case invalidResponse

  /// The user cancelled an explicit (UI-presenting) login dialog. Only emitted by
  /// `.explicitOnly` and the explicit fallback in `.automatic`.
  case cancelled

  /// The Limited Login Refresh feature is disabled by the
  /// `FBSDKFeatureLimitedLoginRefresh` server-side feature flag. The SDK is
  /// behaving as a kill switch — no refresh path will run while the flag is off.
  /// Not retryable; recovery requires the flag to be flipped on server-side.
  case featureDisabled

  /// The current device is running an iOS version older than 13.0. The DPoP
  /// (`.directOnly`) and silent (`.silentOnly`) refresh paths require iOS 13+ APIs.
  case unsupportedPlatform

  /// The current `AuthenticationToken` has no `cnf.jkt` claim, so the `.directOnly`
  /// refresh path cannot use it (DPoP needs the server to have bound a public-key
  /// thumbprint to the token at issuance time). Typical causes:
  /// (a) the token was issued before the SDK supported DPoP key binding;
  /// (b) the device's DPoP keypair was wiped (e.g. app reinstall) and no longer
  ///     matches the token's `cnf.jkt`;
  /// (c) the keychain was unavailable when the token was minted, so `dpop_jkt`
  ///     was silently omitted from the login request (see `.dpopKeyGenerationFailed`);
  ///     or
  /// (d) the server-side feature flag was off when the token was issued.
  /// Recovery: complete a fresh Limited Login (e.g. via `.explicitOnly` or
  /// `.automatic`) to mint a newly-bound token. Under `.automatic`, this case
  /// falls through to silent refresh, which sends `dpop_jkt` to mint a freshly
  /// bound token; if silent then requires user interaction it falls back to
  /// explicit.
  case notDPoPBound

  /// The SDK could not generate or load the DPoP private key from the keychain.
  /// The most common cause is the host app lacking a `keychain-access-groups`
  /// entitlement (e.g. an unsigned simulator build, or a development build with
  /// no `DEVELOPMENT_TEAM`/`CODE_SIGN_ENTITLEMENTS` configured). Other causes:
  /// device locked before first unlock, Secure Enclave access denied, keychain
  /// corruption.
  ///
  /// When this happens at login time, `dpop_jkt` is silently omitted and the
  /// resulting token has no `cnf.jkt` — subsequent `.directOnly` refreshes will
  /// return `.notDPoPBound`. When it happens at refresh time, the SDK surfaces
  /// this case directly. Inspect device console logs filtered to
  /// `com.facebook.sdk` for the underlying `OSStatus` / `CFError` from
  /// `SecKeyCreateRandomKey` / `SecAccessControlCreateWithFlags`.
  case dpopKeyGenerationFailed

  /// An error the SDK could not classify into one of the cases above.
  case unknown
}

// MARK: - LocalizedError Conformance

extension LimitedLoginRefreshError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .noCurrentToken:
      return "No current Limited Login session — call LoginManager.logIn(...) first."
    case .notLimitedLogin:
      return "The current session is a full Login session, not a Limited Login session. "
        + "refreshLimitedLogin only refreshes Limited Login sessions."
    case .loginRequired:
      return "The Facebook session backing this token has expired. The user must log in again."
    case .consentRequired:
      return "Additional consent is required for this token. The user must log in again "
        + "to re-grant the missing permissions."
    case .userMismatch:
      return "Refused to swap in the refreshed token: its `sub` claim does not match the "
        + "currently authenticated user's ID. Log the user out and require a fresh login."
    case .networkError:
      return "A network error occurred while contacting the refresh endpoint. Retry when "
        + "connectivity is restored."
    case .timeout:
      return "The refresh request timed out after 30 seconds. Retry."
    case .rateLimited:
      return "Refresh attempts are being throttled by the client-side rate limiter. "
        + "Inspect RefreshRateLimiter.shared.timeUntilNextAllowedAttempt() before retrying."
    case .invalidResponse:
      return "The server's refresh response could not be parsed (missing id_token, "
        + "malformed JSON, or claims failing OIDC validation)."
    case .cancelled:
      return "The user cancelled the login dialog."
    case .featureDisabled:
      return "Limited Login Refresh is disabled by the FBSDKFeatureLimitedLoginRefresh "
        + "feature flag for this app. The kill switch is active."
    case .unsupportedPlatform:
      return "Limited Login Refresh requires iOS 13.0 or later."
    case .notDPoPBound:
      return "The current Limited Login token has no DPoP key binding (no `cnf.jkt` claim), "
        + "so the .directOnly path cannot use it. Typical causes: token issued before DPoP "
        + "binding rolled out, device key wiped (e.g. app reinstall), keychain unavailable "
        + "at login (see .dpopKeyGenerationFailed), or feature flag was off at issuance. "
        + "Recovery: complete a fresh Limited Login via .explicitOnly or .automatic to "
        + "mint a newly-bound token."
    case .dpopKeyGenerationFailed:
      return "Failed to generate or load the DPoP private key from the keychain. The most "
        + "likely cause is a missing `keychain-access-groups` entitlement on the host app — "
        + "ensure the app has a valid `DEVELOPMENT_TEAM` and a `CODE_SIGN_ENTITLEMENTS` plist "
        + "with a `keychain-access-groups` entry (e.g. `$(AppIdentifierPrefix)*`). Check "
        + "device console logs filtered to `com.facebook.sdk` for the underlying OSStatus."
    case .unknown:
      return "An unknown error occurred during Limited Login refresh."
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

/// Strategy for `LoginManager.refreshLimitedLogin(...)`.
///
/// The SDK provides three concrete refresh mechanisms (`.silentOnly`, `.directOnly`,
/// `.explicitOnly`) and one orchestrator (`.automatic`) that cascades through them.
@objc(FBSDKRefreshFallbackPolicy)
public enum RefreshFallbackPolicy: Int, Sendable {

  /// Cascade through the available refresh mechanisms, falling back to higher-friction
  /// options when lower-friction ones cannot recover. Order:
  ///
  /// 1. `.directOnly` (truly silent, DPoP-bound HTTPS POST).
  /// 2. If `.directOnly` returned `.notDPoPBound` (the precondition isn't met), skip
  ///    `.silentOnly` (it can't fix this) and go straight to `.explicitOnly`.
  /// 3. If `.directOnly` returned any other failure, try `.silentOnly`
  ///    (`prompt=none` via ASWebAuthenticationSession).
  /// 4. If `.silentOnly` returned `.loginRequired` or `.consentRequired`, fall back
  ///    to `.explicitOnly`. Otherwise propagate the result.
  ///
  /// `.featureDisabled` is *never* recovered — the kill switch is respected.
  case automatic = 0

  /// Run only the `prompt=none` silent OIDC flow via `ASWebAuthenticationSession`.
  /// Returns the result with no fallback. The user sees an Apple system consent
  /// modal but no Facebook UI.
  case silentOnly

  /// Run only an explicit Limited Login flow (presents the standard Facebook login
  /// dialog). Use when the caller wants to be sure the user re-authenticates.
  case explicitOnly

  /// Run only the truly-silent direct refresh (DPoP-bound HTTPS POST to the refresh
  /// endpoint). Returns `.notDPoPBound` when the current token has no `cnf.jkt`
  /// claim, or `.loginRequired` when the server rejects the proof (e.g. the device
  /// key no longer matches `cnf.jkt`). Use when no user-visible UI is acceptable.
  case directOnly
}
