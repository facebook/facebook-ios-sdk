/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation
import Security

/// Performs the direct (silent, headless) refresh of a Limited Login id_token by POSTing
/// to `/limited_login/refresh` with a DPoP proof header.
///
/// Unlike `SilentAuthenticationSession`, this path never opens
/// `ASWebAuthenticationSession` and never shows the Apple consent modal — the server
/// authenticates the caller via the DPoP-bound `cnf.jkt` claim in the existing id_token.
@available(iOS 13.0, *)
final class DirectRefreshSession {

  typealias CompletionHandler = (Result<String, LimitedLoginRefreshError>) -> Void

  private static let timeout: TimeInterval = 30

  /// (privateKey, publicKeyJWK) source. Production reads from `DPoPKeyManager.shared`;
  /// tests inject a closure that returns a transient in-memory key.
  typealias KeyMaterialProvider = () -> (privateKey: SecKey, publicKeyJWK: [String: String])?

  /// Builds the refresh endpoint URL for a given host prefix + path. Production
  /// routes through `Utility.unversionedFacebookURL`, which reads
  /// `Settings.shared.facebookDomainPart` so OD/sandbox builds hit the right
  /// host. Tests inject a closure that returns a stub URL so they don't have
  /// to initialize the SDK (touching `Settings.shared` outside of an
  /// initialized SDK is a fatal error).
  typealias URLBuilder = (_ hostPrefix: String, _ path: String) -> URL?

  private let session: URLSession
  private let settings: SettingsProtocol
  private let keyMaterialProvider: KeyMaterialProvider
  private let urlBuilder: URLBuilder

  /// - Parameter session: Injectable for tests. Production passes `.shared`.
  /// - Parameter settings: Injectable for tests. Production passes `Settings.shared`.
  /// - Parameter keyMaterialProvider: Injectable for tests so they don't need the keychain.
  /// - Parameter urlBuilder: Injectable for tests so they don't need an initialized SDK.
  init(
    session: URLSession = .shared,
    settings: SettingsProtocol = Settings.shared,
    keyMaterialProvider: @escaping KeyMaterialProvider = DirectRefreshSession.defaultKeyMaterialProvider,
    urlBuilder: @escaping URLBuilder = DirectRefreshSession.defaultURLBuilder
  ) {
    self.session = session
    self.settings = settings
    self.keyMaterialProvider = keyMaterialProvider
    self.urlBuilder = urlBuilder
  }

  static let defaultKeyMaterialProvider: KeyMaterialProvider = {
    let manager = DPoPKeyManager.shared
    guard let privateKey = manager.getPrivateKey(),
          let jwk = manager.getPublicKeyJWK()
    else { return nil }

    return (privateKey, jwk)
  }

  /// Default URL builder. Calls `Utility.unversionedFacebookURL` to construct
  /// the refresh endpoint — same pattern as `AuthenticationTokenFactory` uses
  /// for the OIDC certs endpoint. The server mounts `/limited_login/refresh/`
  /// directly, with no Graph API version prefix; the default `facebookURL(...)`
  /// builder would prepend `/v<N>.<M>/` and yield a 404.
  static let defaultURLBuilder: URLBuilder = { hostPrefix, path in
    var error: NSError?
    let url = Utility.unversionedFacebookURL(
      withHostPrefix: hostPrefix,
      path: path,
      queryParameters: [:],
      error: &error
    )
    return error == nil ? url : nil
  }

  /// Posts the refresh request with a DPoP proof. Calls `completion` exactly once.
  func refresh(
    idTokenHint: String,
    appID: String,
    completion: @escaping CompletionHandler
  ) {
    guard let material = keyMaterialProvider() else {
      completion(.failure(.loginRequired))
      return
    }

    let privateKey = material.privateKey
    let publicKeyJWK = material.publicKeyJWK

    guard let url = urlBuilder(LoginEndpoints.limitedHostPrefix, "/limited_login/refresh/") else {
      completion(.failure(.invalidResponse))
      return
    }
    let urlString = url.absoluteString

    guard let dpopProof = DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: urlString,
      idTokenHint: idTokenHint
    ) else {
      completion(.failure(.unknown))
      return
    }

    var request = URLRequest(url: url, timeoutInterval: Self.timeout)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.setValue(dpopProof, forHTTPHeaderField: "DPoP")

    // OAuth token endpoints (RFC 6749 §3.2) take params as form-encoded bytes,
    // and Meta's XController param accessors read from $_POST — sending JSON
    // means the controller would not see id_token_hint/app_id at all.
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: "id_token_hint", value: idTokenHint),
      URLQueryItem(name: "app_id", value: appID),
    ]
    request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

    // URLSession data-task callbacks fire on the session's delegate queue (a
    // background queue by default). The completion eventually drives UI in
    // app code, so deliver it on the main queue to keep the public API safe.
    let task = session.dataTask(with: request) { data, _, error in
      DispatchQueue.main.async {
        Self.handleResponse(data: data, error: error, completion: completion)
      }
    }
    task.resume()
  }

  // MARK: - Response handling

  private static func handleResponse(
    data: Data?,
    error: Error?,
    completion: @escaping CompletionHandler
  ) {
    if error != nil {
      completion(.failure(.networkError))
      return
    }

    guard let data = data,
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      completion(.failure(.invalidResponse))
      return
    }

    if let idToken = json["id_token"] as? String, !idToken.isEmpty {
      completion(.success(idToken))
      return
    }

    if let errorCode = json["error"] as? String {
      completion(.failure(mapServerError(errorCode)))
      return
    }

    completion(.failure(.invalidResponse))
  }

  /// Decodes the JWT payload of a DPoP proof and returns just the freshness
  /// claims (`jti`, `iat`) for diagnostic logging. Returns nil on any decode
  /// failure — diagnostics are best-effort and must not affect the request.
  private static func summarizeDPoPProof(_ jwt: String) -> String? {
    let parts = jwt.split(separator: ".")
    guard parts.count >= 2 else { return nil }

    var encoded = String(parts[1])
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    while encoded.count % 4 != 0 { encoded.append("=") }
    guard let data = Data(base64Encoded: encoded),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    let jti = json["jti"] as? String ?? "<missing>"
    let iat = json["iat"] as? Int ?? -1
    return "jti=\(jti), iat=\(iat)"
  }

  /// Maps server error codes to the SDK's `LimitedLoginRefreshError`.
  /// `invalid_dpop_proof` is treated as `loginRequired` because a key mismatch
  /// means the user must re-authenticate to bind a new key.
  private static func mapServerError(_ code: String) -> LimitedLoginRefreshError {
    switch code {
    case "login_required": return .loginRequired
    case "consent_required": return .consentRequired
    case "invalid_dpop_proof": return .loginRequired
    default: return .unknown
    }
  }
}
