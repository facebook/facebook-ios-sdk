/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import CryptoKit
import Foundation
import Security

/// Builds DPoP proof JWTs (RFC 9449) signed with the device's P-256 key.
///
/// A DPoP proof is a JWS whose header carries the public key as a JWK and whose
/// payload binds the proof to a specific HTTP method, target URL, and access token
/// (via the `ath` claim). The server uses the proof to verify the caller possesses
/// the private key matching the `cnf.jkt` claim in the bound id_token.
@available(iOS 13.0, *)
enum DPoPProofBuilder {

  /// Builds a DPoP proof JWT signed by `privateKey`.
  ///
  /// - Parameters:
  ///   - privateKey: The device's private key (P-256, ES256).
  ///   - publicKeyJWK: The matching public key as a JWK (must be the same key pair).
  ///   - httpMethod: Uppercased HTTP method, e.g. `"POST"`.
  ///   - httpURL: Fully-qualified target URL, no query/fragment.
  ///   - idTokenHint: The bound id_token. Hashed into the `ath` claim per RFC 9449 §4.1.
  /// - Returns: The signed proof JWT, or nil on encoding/signing failure.
  static func buildProof(
    privateKey: SecKey,
    publicKeyJWK: [String: String],
    httpMethod: String,
    httpURL: String,
    idTokenHint: String
  ) -> String? {
    let header: [String: Any] = [
      "typ": "dpop+jwt",
      "alg": "ES256",
      "jwk": publicKeyJWK,
    ]

    let ath = SHA256.hash(data: Data(idTokenHint.utf8))
    let payload: [String: Any] = [
      "htm": httpMethod,
      "htu": httpURL,
      "iat": Int(Date().timeIntervalSince1970),
      "jti": UUID().uuidString,
      "ath": Data(ath).base64URLEncodedString(),
    ]

    guard let headerData = try? JSONSerialization.data(withJSONObject: header),
          let payloadData = try? JSONSerialization.data(withJSONObject: payload)
    else { return nil }

    let headerB64 = headerData.base64URLEncodedString()
    let payloadB64 = payloadData.base64URLEncodedString()
    let signingInput = "\(headerB64).\(payloadB64)"

    guard let signature = sign(data: Data(signingInput.utf8), with: privateKey) else {
      return nil
    }

    return "\(signingInput).\(signature.base64URLEncodedString())"
  }

  // MARK: - Signing

  static func sign(data: Data, with privateKey: SecKey) -> Data? {
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
      privateKey,
      .ecdsaSignatureMessageX962SHA256,
      data as CFData,
      &error
    ) as Data? else {
      return nil
    }

    return derToRaw(signature)
  }

  /// Converts a DER-encoded ECDSA signature (X9.62) to the raw r||s format (64 bytes)
  /// required by JWS/JWT (RFC 7515; RFC 7518 §3.4).
  ///
  /// DER format: `0x30 <total_len> 0x02 <r_len> <r_bytes> 0x02 <s_len> <s_bytes>`
  /// Raw format: `r (32 bytes, zero-padded left) || s (32 bytes, zero-padded left)`
  ///
  /// Edge cases:
  /// - `r` or `s` with a leading 0x00 byte (DER adds this when the high bit is set,
  ///   to mark the integer as positive).
  /// - `r` or `s` shorter than 32 bytes (rare but valid — left-pad with zeros).
  /// - Multiple leading zeros (theoretically possible with non-canonical encoders).
  static func derToRaw(_ der: Data) -> Data? {
    // Minimum valid DER signature: 0x30 len 0x02 0x01 r 0x02 0x01 s = 8 bytes.
    guard der.count >= 8 else { return nil }

    var index = 0

    // SEQUENCE tag
    guard der[index] == 0x30 else { return nil }

    index += 1
    // Outer length. For P-256 the total length is always < 128 so we expect a
    // single-byte length encoding.
    let outerLength = Int(der[index])
    index += 1
    guard index + outerLength <= der.count else { return nil }

    guard let (rRaw, afterR) = readDERInteger(der, at: index),
          let (sRaw, _) = readDERInteger(der, at: afterR),
          let rBytes = normalizeIntegerBytes(rRaw),
          let sBytes = normalizeIntegerBytes(sRaw)
    else { return nil }

    return rBytes + sBytes
  }

  /// Reads a DER INTEGER `0x02 <len> <bytes>` starting at `offset`.
  /// Returns the raw bytes and the next read offset, or nil on malformed input.
  private static func readDERInteger(_ data: Data, at offset: Int) -> (bytes: Data, next: Int)? {
    guard offset < data.count, data[offset] == 0x02 else { return nil }

    let lenIndex = offset + 1
    guard lenIndex < data.count else { return nil }

    let length = Int(data[lenIndex])
    let bytesStart = lenIndex + 1
    let bytesEnd = bytesStart + length
    guard bytesEnd <= data.count else { return nil }

    return (Data(data[bytesStart ..< bytesEnd]), bytesEnd)
  }

  /// Strips DER sign-padding (leading 0x00s) and left-pads to exactly 32 bytes.
  /// Returns nil if the value is too large for a P-256 coordinate.
  private static func normalizeIntegerBytes(_ data: Data) -> Data? {
    var bytes = data
    while bytes.count > 32, bytes.first == 0 { bytes = Data(bytes.dropFirst()) }
    guard bytes.count <= 32 else { return nil }

    while bytes.count < 32 { bytes.insert(0, at: 0) }
    return bytes
  }
}
