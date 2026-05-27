/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import FBSDKCoreKit
import Foundation

/// Protocol abstracting `AuthenticationToken.claims()` for testability.
protocol AuthenticationTokenClaimsProviding {
  func claims(for token: AuthenticationToken) -> AuthenticationTokenClaims?
}

struct DefaultAuthenticationTokenClaimsProvider: AuthenticationTokenClaimsProviding {
  func claims(for token: AuthenticationToken) -> AuthenticationTokenClaims? {
    token.claims()
  }
}

// MARK: - Core Class

final class LimitedLoginRefresher {

  /// Retained during the async authentication session.
  @available(iOS 13.0, *)
  private var silentAuthSession: SilentAuthenticationSession? {
    get { _silentAuthSession as? SilentAuthenticationSession }
    set { _silentAuthSession = newValue }
  }

  private var _silentAuthSession: Any?

  func generateRefreshNonce() -> String {
    UUID().uuidString
  }

  func buildRefreshURL(
    existingToken: AuthenticationToken,
    nonce: String,
    scopes: [String]
  ) -> URL? {
    guard let dependencies = try? Self.getDependencies() else {
      return nil
    }

    guard let redirectURL = try? dependencies.internalUtility.appURL(
      withHost: LoginEndpoints.redirectHost,
      path: "",
      queryParameters: [:]
    ) else {
      return nil
    }

    var scopeSet = Set(scopes)
    scopeSet.insert(LoginEndpoints.openIDScope)
    let scopeString = scopeSet.joined(separator: ",")

    var parameters: [String: String] = [
      "client_id": dependencies.settings.appID ?? "",
      "redirect_uri": redirectURL.absoluteString,
      "display": LoginEndpoints.displayValueTouch,
      "sdk": LoginEndpoints.sdkValueIOS,
      "sdk_version": FBSDK_VERSION_STRING,
      "return_scopes": "true",
      "response_type": LoginEndpoints.responseTypeLimitedLogin,
      "tp": LoginEndpoints.trackingValueDoNotTrack,
      "scope": scopeString,
      "nonce": nonce,
      "prompt": "none",
      "id_token_hint": existingToken.tokenString,
      "state": UUID().uuidString,
    ]

    // Include the current device's DPoP key thumbprint so the server can re-bind
    // the refreshed id_token to it via the cnf.jkt carry-forward override. This
    // self-heals the device-key-loss case (app reinstall, keychain reset): the
    // existing id_token_hint's cnf.jkt points at the OLD key, and without this
    // re-bind silent refresh would carry forward the stale thumbprint, leaving
    // the user permanently unable to use .directOnly. Gated by the same feature
    // flag as the rest of the Limited Login Refresh feature.
    if let thumbprint = Self.dpopJktProvider() {
      parameters[LoginEndpoints.dpopJktParam] = thumbprint
    }

    return try? dependencies.internalUtility.facebookURL(
      hostPrefix: LoginEndpoints.limitedHostPrefix,
      path: LoginEndpoints.oAuthPath,
      queryParameters: parameters
    )
  }

  /// Test seam for `dpop_jkt` emission on silent refresh. Production reads from
  /// `DPoPKeyManager.shared`, gated behind `FBSDKFeatureLimitedLoginRefresh` so
  /// the kill switch stops *all* DPoP emission, not just at-login emission.
  /// Tests can swap this to inject a deterministic value (or nil to simulate
  /// "no DPoP available"). Reset in tearDown.
  static var dpopJktProvider: () -> String? = defaultDPoPJktProvider

  static let defaultDPoPJktProvider: () -> String? = {
    guard #available(iOS 13.0, *) else { return nil }

    guard RefreshGateKeeperCheck.isSilentRefreshEnabled() else { return nil }

    let manager = DPoPKeyManager.shared
    do {
      _ = try manager.generateKeyPairIfNeeded()
    } catch {
      // Silent refresh still proceeds without `dpop_jkt` — the resulting
      // token will not be DPoP-bound and subsequent `.directOnly` refreshes
      // will fail with `.notDPoPBound`. Same root cause and remediation as
      // the login-time provider in `LoginManager.defaultDPoPJktProvider`.
      _Logger.singleShotLogEntry(
        .developerErrors,
        logEntry: "FBSDKLoginKit: DPoP key generation failed during silent "
          + "refresh — `dpop_jkt` will be omitted. Underlying error: \(error). "
          + "See LimitedLoginRefreshError.dpopKeyGenerationFailed for diagnosis."
      )
      return nil
    }

    return manager.getJWKThumbprint()
  }

  /// Orchestrates the full refresh flow: build URL, start silent auth session,
  /// parse response, and process token.
  ///
  /// This is the top-level method called by `LoginManager.performSilentRefresh`.
  ///
  /// - Parameters:
  ///   - existingToken: The current `AuthenticationToken` to refresh.
  ///   - existingUserID: The user ID from `Profile.current.userID`.
  ///     Must come from Profile, NOT from `AuthenticationToken.current.claims()?.sub`,
  ///     because `claims()` returns nil for tokens older than 10 minutes due to
  ///     temporal validation in `AuthenticationTokenClaims.init`.
  ///   - completion: Called with the refreshed `Profile` on success, or an error on failure.
  func refresh(
    existingToken: AuthenticationToken,
    existingUserID: String,
    scopes: [String] = [LoginEndpoints.openIDScope],
    completion: @escaping (Result<Profile, LimitedLoginRefreshError>) -> Void
  ) {
    // GateKeeper check
    guard RefreshGateKeeperCheck.isSilentRefreshEnabled() else {
      completion(.failure(.featureDisabled))
      return
    }

    // Rate limiter check
    guard RefreshRateLimiter.shared.canAttemptRefresh() else {
      completion(.failure(.rateLimited))
      return
    }

    // Platform check
    guard #available(iOS 13.0, *) else {
      completion(.failure(.unsupportedPlatform))
      return
    }

    RefreshRateLimiter.shared.recordAttempt()

    let nonce = generateRefreshNonce()

    guard let url = buildRefreshURL(existingToken: existingToken, nonce: nonce, scopes: scopes) else {
      RefreshRateLimiter.shared.recordFailure()
      completion(.failure(.invalidResponse))
      return
    }

    guard let dependencies = try? Self.getDependencies() else {
      RefreshRateLimiter.shared.recordFailure()
      completion(.failure(.unknown))
      return
    }

    let callbackURLScheme = "fb" + (dependencies.settings.appID ?? "")

    let session = SilentAuthenticationSession()
    silentAuthSession = session

    session.start(url: url, callbackURLScheme: callbackURLScheme) { [weak self] result in
      guard let self = self else { return }
      self.silentAuthSession = nil

      switch result {
      case let .success(callbackURL):
        let parseResult = self.parseRefreshResponse(callbackURL)
        switch parseResult {
        case let .success(tokenString):
          self.processRefreshedToken(tokenString, nonce: nonce, existingUserID: existingUserID) { processResult in
            switch processResult {
            case let .success(profile):
              RefreshRateLimiter.shared.recordSuccess()
              completion(.success(profile))
            case let .failure(error):
              RefreshRateLimiter.shared.recordFailure()
              completion(.failure(error))
            }
          }
        case let .failure(error):
          RefreshRateLimiter.shared.recordFailure()
          completion(.failure(error))
        }

      case let .failure(error):
        RefreshRateLimiter.shared.recordFailure()
        completion(.failure(error))
      }
    }
  }
}

// MARK: - DependentAsType

extension LimitedLoginRefresher: DependentAsType {
  struct TypeDependencies {
    var authenticationTokenCreator: AuthenticationTokenCreating
    var claimsProvider: AuthenticationTokenClaimsProviding
    var internalUtility: URLHosting
    var profileFactory: ProfileCreating
    var settings: SettingsProtocol
  }

  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    authenticationTokenCreator: AuthenticationTokenFactory(),
    claimsProvider: DefaultAuthenticationTokenClaimsProvider(),
    internalUtility: InternalUtility.shared,
    profileFactory: ProfileFactory(),
    settings: Settings.shared
  )
}

// MARK: - Response Parsing

extension LimitedLoginRefresher {

  func parseRefreshResponse(_ url: URL) -> Result<String, LimitedLoginRefreshError> {
    guard let fragment = url.fragment, !fragment.isEmpty else {
      return .failure(.invalidResponse)
    }

    let params = parseFragment(fragment)

    if let idToken = params["id_token"], !idToken.isEmpty {
      return .success(idToken)
    }

    if let error = params["error"] {
      return .failure(mapOIDCError(error))
    }

    return .failure(.invalidResponse)
  }

  private func parseFragment(_ fragment: String) -> [String: String] {
    var result = [String: String]()
    let pairs = fragment.components(separatedBy: "&")
    for pair in pairs {
      let components = pair.components(separatedBy: "=")
      guard components.count == 2 else { continue }
      let key = components[0].removingPercentEncoding ?? components[0]
      let value = components[1].removingPercentEncoding ?? components[1]
      result[key] = value
    }
    return result
  }

  private func mapOIDCError(_ error: String) -> LimitedLoginRefreshError {
    switch error {
    case "login_required":
      return .loginRequired
    case "consent_required":
      return .consentRequired
    default:
      return .unknown
    }
  }
}

// MARK: - Token Verification & Profile Creation

extension LimitedLoginRefresher {

  /// Verifies the refreshed token and creates an updated profile.
  ///
  /// - Parameters:
  ///   - tokenString: The raw ID token string from the refresh response.
  ///   - nonce: The nonce used when building the refresh URL.
  ///   - existingUserID: The user ID from `Profile.current.userID`.
  ///     Must come from Profile, NOT from `AuthenticationToken.current.claims()?.sub`,
  ///     because `claims()` returns nil for tokens older than 10 minutes due to
  ///     temporal validation in `AuthenticationTokenClaims.init`.
  ///   - completion: Called with the refreshed `Profile` on success, or an error on failure.
  func processRefreshedToken(
    _ tokenString: String,
    nonce: String,
    existingUserID: String,
    completion: @escaping (Result<Profile, LimitedLoginRefreshError>) -> Void
  ) {
    guard let dependencies = try? Self.getDependencies() else {
      completion(.failure(.unknown))
      return
    }

    let graphDomain = AuthenticationToken.current?.graphDomain ?? "facebook"

    dependencies.authenticationTokenCreator.createToken(
      tokenString: tokenString,
      nonce: nonce,
      graphDomain: graphDomain
    ) { token in
      guard let token = token else {
        completion(.failure(.invalidResponse))
        return
      }

      // Claims extraction is safe here because this is a FRESH token
      // (just received from the server), so temporal validation will pass.
      guard let claims = dependencies.claimsProvider.claims(for: token) else {
        completion(.failure(.invalidResponse))
        return
      }

      // ┌─────────────────────────────────────────────────────────────┐
      // │ CRITICAL SECURITY CHECK                                    │
      // │                                                            │
      // │ Verify that the refreshed token belongs to the same user   │
      // │ as the current session. This prevents session hijacking    │
      // │ where a different user's token could replace the current   │
      // │ user's profile.                                            │
      // └─────────────────────────────────────────────────────────────┘
      guard claims.sub == existingUserID else {
        completion(.failure(.userMismatch))
        return
      }

      guard let profile = Self.createProfile(from: claims, using: dependencies.profileFactory) else {
        completion(.failure(.invalidResponse))
        return
      }

      DispatchQueue.main.async {
        AuthenticationToken.current = token
        Profile.current = profile
        completion(.success(profile))
      }
    }
  }

  private static func createProfile(
    from claims: AuthenticationTokenClaims,
    using profileFactory: ProfileCreating
  ) -> Profile? {
    guard !claims.sub.isEmpty else {
      return nil
    }

    var imageURL: URL?
    if let picture = claims.picture {
      imageURL = URL(string: picture)
    }

    var birthday: Date?
    if let userBirthday = claims.userBirthday {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MM/dd/yyyy"
      birthday = dateFormatter.date(from: userBirthday)
    }

    return profileFactory.createProfile(
      userID: claims.sub,
      firstName: claims.givenName,
      middleName: claims.middleName,
      lastName: claims.familyName,
      name: claims.name,
      linkURL: URL(string: claims.userLink ?? ""),
      refreshDate: Date(),
      imageURL: imageURL,
      email: claims.email,
      friendIDs: claims.userFriends,
      birthday: birthday,
      ageRange: UserAgeRange(from: claims.userAgeRange ?? [:]),
      hometown: Location(from: claims.userHometown ?? [:]),
      location: Location(from: claims.userLocation ?? [:]),
      gender: claims.userGender,
      permissions: nil,
      isLimited: true
    )
  }
}
