/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import CryptoKit
import Security
import XCTest

@available(iOS 13.0, *)
final class DPoPProofBuilderTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  private var privateKey: SecKey!
  private var publicKeyJWK: [String: String]!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: false] as [String: Any],
    ]
    var error: Unmanaged<CFError>?
    // swiftlint:disable:next force_unwrapping
    privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)!
    publicKeyJWK = DPoPKeyManager.publicKeyJWK(for: privateKey)
  }

  override func tearDown() {
    privateKey = nil
    publicKeyJWK = nil
    super.tearDown()
  }

  // MARK: - JWT structure

  func testBuildProofReturnsValidJWT() throws {
    let proof = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://limited.facebook.com/v22.0/limited_login/refresh",
      idTokenHint: "id_token_xyz"
    ))
    let segments = proof.split(separator: ".")
    XCTAssertEqual(segments.count, 3)
  }

  func testHeaderContainsTypAlgJwk() throws {
    let proof = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://example.com",
      idTokenHint: "tok"
    ))
    let header = try decodeJWTSegment(proof, index: 0)
    XCTAssertEqual(header["typ"] as? String, "dpop+jwt")
    XCTAssertEqual(header["alg"] as? String, "ES256")
    let jwk = try XCTUnwrap(header["jwk"] as? [String: String])
    XCTAssertEqual(jwk["kty"], "EC")
    XCTAssertEqual(jwk["crv"], "P-256")
    XCTAssertNotNil(jwk["x"])
    XCTAssertNotNil(jwk["y"])
  }

  func testPayloadContainsAllRequiredClaims() throws {
    let proof = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://example.com/refresh",
      idTokenHint: "tok"
    ))
    let payload = try decodeJWTSegment(proof, index: 1)
    XCTAssertEqual(payload["htm"] as? String, "POST")
    XCTAssertEqual(payload["htu"] as? String, "https://example.com/refresh")
    XCTAssertNotNil(payload["iat"] as? Int)
    XCTAssertNotNil(payload["jti"] as? String)
    XCTAssertNotNil(payload["ath"] as? String)
  }

  func testAthIsHashOfIdTokenHint() throws {
    let token = "id_token_to_hash"
    let proof = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://example.com",
      idTokenHint: token
    ))
    let payload = try decodeJWTSegment(proof, index: 1)
    let ath = try XCTUnwrap(payload["ath"] as? String)
    let expected = Data(SHA256.hash(data: Data(token.utf8))).base64URLEncodedString()
    XCTAssertEqual(ath, expected)
  }

  func testJtiIsUniquePerInvocation() throws {
    let proof1 = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://example.com",
      idTokenHint: "t"
    ))
    let proof2 = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://example.com",
      idTokenHint: "t"
    ))
    let jti1 = try decodeJWTSegment(proof1, index: 1)["jti"] as? String
    let jti2 = try decodeJWTSegment(proof2, index: 1)["jti"] as? String
    XCTAssertNotEqual(jti1, jti2)
  }

  // MARK: - Signature verification

  func testSignatureVerifiesWithPublicKey() throws {
    let proof = try XCTUnwrap(DPoPProofBuilder.buildProof(
      privateKey: privateKey,
      publicKeyJWK: publicKeyJWK,
      httpMethod: "POST",
      httpURL: "https://example.com",
      idTokenHint: "tok"
    ))
    let segments = proof.split(separator: ".").map(String.init)
    XCTAssertEqual(segments.count, 3)
    let signingInput = "\(segments[0]).\(segments[1])"
    let rawSignature = try XCTUnwrap(base64URLDecode(segments[2]))

    // Reconstruct the public key and verify the signature.
    let publicKey = try XCTUnwrap(SecKeyCopyPublicKey(privateKey))
    let derSignature = try XCTUnwrap(rawToDER(rawSignature))
    var error: Unmanaged<CFError>?
    let isValid = SecKeyVerifySignature(
      publicKey,
      .ecdsaSignatureMessageX962SHA256,
      Data(signingInput.utf8) as CFData,
      derSignature as CFData,
      &error
    )
    XCTAssertTrue(isValid, "DPoP proof signature must verify against the matching public key")
  }

  // MARK: - DER -> raw conversion edge cases

  func testDerToRawHandlesLeadingZeroInR() throws {
    // r and s are 32 bytes; r has high bit set so DER prefixes 0x00 making rLen=33.
    let rWithLeadingZero = Data([0x00] + Array(repeating: UInt8(0xFF), count: 32))
    let sBytes = Data(repeating: 0x01, count: 32)
    let der = encodeDER(rBytes: rWithLeadingZero, sBytes: sBytes)
    let raw = try XCTUnwrap(DPoPProofBuilder.derToRaw(der))
    XCTAssertEqual(raw.count, 64)
    // r should drop the 0x00 byte; the first 32 bytes are 0xFF
    XCTAssertEqual(raw.subdata(in: 0 ..< 32), Data(repeating: 0xFF, count: 32))
    XCTAssertEqual(raw.subdata(in: 32 ..< 64), Data(repeating: 0x01, count: 32))
  }

  func testDerToRawHandlesShortR() throws {
    // r shorter than 32 bytes — should be left-padded with zeros.
    let shortR = Data([0x01, 0x02, 0x03])
    let sBytes = Data(repeating: 0x04, count: 32)
    let der = encodeDER(rBytes: shortR, sBytes: sBytes)
    let raw = try XCTUnwrap(DPoPProofBuilder.derToRaw(der))
    XCTAssertEqual(raw.count, 64)
    var expectedR = Data(repeating: 0, count: 29)
    expectedR.append(contentsOf: [0x01, 0x02, 0x03])
    XCTAssertEqual(raw.subdata(in: 0 ..< 32), expectedR)
  }

  func testDerToRawRejectsInvalidSequenceTag() {
    var bad = Data(repeating: 0, count: 16)
    bad[0] = 0x31 // wrong tag
    XCTAssertNil(DPoPProofBuilder.derToRaw(bad))
  }

  func testDerToRawRejectsTruncatedInput() {
    XCTAssertNil(DPoPProofBuilder.derToRaw(Data([0x30, 0x06, 0x02])))
  }

  func testDerToRawRejectsTooShortInput() {
    XCTAssertNil(DPoPProofBuilder.derToRaw(Data(repeating: 0, count: 4)))
  }

  // MARK: - Helpers

  private func decodeJWTSegment(_ jwt: String, index: Int) throws -> [String: Any] {
    let segments = jwt.split(separator: ".")
    XCTAssertGreaterThan(segments.count, index)
    let data = try XCTUnwrap(base64URLDecode(String(segments[index])))
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private func base64URLDecode(_ encoded: String) -> Data? {
    var b64 = encoded.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let pad = (4 - b64.count % 4) % 4
    b64.append(String(repeating: "=", count: pad))
    return Data(base64Encoded: b64)
  }

  /// Builds a DER-encoded ECDSA signature from raw r and s INTEGER bytes (not pre-padded).
  /// Produces: 0x30 <total_len> 0x02 <rLen> <r> 0x02 <sLen> <s>.
  private func encodeDER(rBytes: Data, sBytes: Data) -> Data {
    var out = Data()
    out.append(0x30)
    out.append(UInt8(2 + rBytes.count + 2 + sBytes.count))
    out.append(0x02)
    out.append(UInt8(rBytes.count))
    out.append(rBytes)
    out.append(0x02)
    out.append(UInt8(sBytes.count))
    out.append(sBytes)
    return out
  }

  /// Wraps raw 64-byte r||s back into DER for `SecKeyVerifySignature`.
  private func rawToDER(_ raw: Data) -> Data? {
    guard raw.count == 64 else { return nil }

    let rBytes = stripAndAddSignBit(raw.subdata(in: 0 ..< 32))
    let sBytes = stripAndAddSignBit(raw.subdata(in: 32 ..< 64))
    return encodeDER(rBytes: rBytes, sBytes: sBytes)
  }

  /// Strips leading zeros, then prepends 0x00 if the high bit is set, to keep the
  /// integer positive in DER encoding.
  private func stripAndAddSignBit(_ data: Data) -> Data {
    var trimmed = data
    while trimmed.count > 1, trimmed.first == 0 { trimmed = trimmed.dropFirst() }
    if let first = trimmed.first, first & 0x80 != 0 {
      var padded = Data([0x00])
      padded.append(trimmed)
      return padded
    }
    return trimmed
  }
}
