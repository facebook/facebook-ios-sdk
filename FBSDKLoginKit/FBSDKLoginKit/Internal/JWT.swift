/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Lightweight, validation-free JWT payload reader.
///
/// `AuthenticationTokenClaims.init?(encodedClaims:nonce:)` enforces the full
/// OIDC validation contract on a token (issuer, audience, nonce match, `iat`
/// within the last 10 minutes, etc.). That's the right behavior when accepting
/// a freshly issued token, but it's the wrong tool when you only need to read
/// a structural claim (e.g. `cnf.jkt`) from a possibly-stale token — the 10-min
/// window will reject any token older than that, regardless of whether the
/// claim you care about has anything to do with freshness.
///
/// `JWT.payload(from:)` decodes the second segment of a JWT (`header.payload.signature`)
/// from base64url to a `[String: Any]` dictionary. It performs no signature
/// verification and no semantic validation — callers are responsible for any
/// validation appropriate to their use case.
enum JWT {

  /// Returns the JWT payload as a dictionary, or nil if the input is not a
  /// well-formed three-segment JWT with a valid base64url-encoded JSON payload.
  static func payload(from jwtString: String) -> [String: Any]? {
    let segments = jwtString.split(separator: ".")
    guard segments.count == 3 else { return nil }

    var encoded = String(segments[1])
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    while encoded.count % 4 != 0 { encoded.append("=") }

    guard let data = Data(base64Encoded: encoded),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }

    return object
  }
}
