/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import CryptoKit
import Foundation

private func base64URLEncode(input: Data) -> String {
  input.base64EncodedString()
    .replacingOccurrences(of: "+", with: "-")
    .replacingOccurrences(of: "/", with: "_")
    .replacingOccurrences(of: "=", with: "")
}

private func base64URLDecode(input: String) -> Data? {
  var base64 = input
    .replacingOccurrences(of: "-", with: "+")
    .replacingOccurrences(of: "_", with: "/")
  if base64.count % 4 != 0 {
    base64.append(String(repeating: "=", count: 4 - base64.count % 4))
  }
  return Data(base64Encoded: base64)
}

enum ConvEncUtils {
  /**
   * Encrypt conversion data to the provided public key with HPKE using ciphersuite: Curve25519_SHA256_ChachaPoly
   */
  @available(iOS 17.0, *)
  static func encConvString(publicKeyB64Url: String, dataStr: String) -> String? {
    if let input = dataStr.data(using: .utf8) {
      if let publicKey = b64urlDecodePublicKey(publicKeyB64Url: publicKeyB64Url) {
        return encConvData(publicKey: publicKey, data: input)
      }
    }
    return nil
  }

  @available(iOS 17.0, *)
  static func encConvData(publicKey: Data, data: Data) -> String? {
    // Step 1: convert the key bytes into the right type
    guard let pkCurve25519 = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKey) else {
      return nil
    }
    // Step 2: instantiate the HPKE sender
    let info = "3P_CONV_ENC_HPKE_0020_0001_0003".data(using: .utf8) ?? Data()
    guard var sender = try? HPKE.Sender(
      recipientKey: pkCurve25519,
      ciphersuite: .Curve25519_SHA256_ChachaPoly,
      info: info
    ) else {
      return nil
    }
    // Step 3: encrypt the converstion data
    guard let ciphertext = try? sender.seal(data) else {
      return nil
    }
    // Step 4: construct the ciphertext JSON and serialize it
    let jsonDict: [String: String] = [
      "ciphersuite": "HPKE_0020_0001_0003",
      "ct": base64URLEncode(input: ciphertext),
      "enc": base64URLEncode(input: sender.encapsulatedKey),
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict) {
      return String(data: jsonData, encoding: .utf8)
    } else {
      return nil
    }
  }

  /**
   * Convert a base64URL encoded public key into binary string (Data)
   */
  static func b64urlDecodePublicKey(publicKeyB64Url: String) -> Data? {
    base64URLDecode(input: publicKeyB64Url)
  }
}
