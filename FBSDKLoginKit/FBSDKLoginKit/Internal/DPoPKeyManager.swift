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

/// Persistence strategy for the DPoP private key.
///
/// Production uses `KeychainDPoPKeyStore`. Tests inject an in-memory store
/// because the xctest bundle in this project lacks the keychain entitlement
/// required by `SecItemAdd`/`SecKeyCreateRandomKey` with `kSecAttrIsPermanent`.
@available(iOS 13.0, *)
protocol DPoPKeyStoring {
  func loadKey() -> SecKey?
  func generateKey() throws -> SecKey
  func deleteKey()
}

/// Manages the device's DPoP key pair lifecycle for Limited Login direct refresh.
///
/// On real devices with a Secure Enclave the private key is generated and stored
/// in the Secure Enclave (non-extractable). On the iOS simulator a software-backed
/// P-256 key is generated and stored in the Keychain instead — `SecureEnclave.isAvailable`
/// reports true on Apple-silicon simulators but adding an SE-backed key there fails
/// with `errSecMissingEntitlement`, so we use a compile-time guard.
///
/// The public key is exposed as a JWK (RFC 7517) and as a JWK Thumbprint (RFC 7638)
/// for use as the `dpop_jkt` parameter sent at login time.
@available(iOS 13.0, *)
final class DPoPKeyManager {

  static let shared = DPoPKeyManager()

  private let store: DPoPKeyStoring

  init(store: DPoPKeyStoring = KeychainDPoPKeyStore()) {
    self.store = store
  }

  // MARK: - Key Lifecycle

  /// Generates a new P-256 key pair, replacing any existing key.
  @discardableResult
  func generateKeyPair() throws -> SecKey {
    store.deleteKey()
    return try store.generateKey()
  }

  /// Returns the existing private key, generating one if absent.
  @discardableResult
  func generateKeyPairIfNeeded() throws -> SecKey {
    if let existing = store.loadKey() { return existing }
    return try store.generateKey()
  }

  /// Returns the existing private key, if any.
  func getPrivateKey() -> SecKey? {
    store.loadKey()
  }

  /// Deletes the SDK's DPoP key pair. No-op if none exists.
  func deleteKeyPair() {
    store.deleteKey()
  }

  // MARK: - JWK / Thumbprint

  /// Returns the public key as a JWK dictionary (RFC 7517) for an EC P-256 key.
  func getPublicKeyJWK() -> [String: String]? {
    guard let privateKey = store.loadKey() else { return nil }

    return Self.publicKeyJWK(for: privateKey)
  }

  /// Returns the JWK Thumbprint (RFC 7638) of the device's public key, base64url-encoded.
  func getJWKThumbprint() -> String? {
    guard let jwk = getPublicKeyJWK() else { return nil }

    return Self.thumbprint(for: jwk)
  }

  /// Computes the JWK representation of an EC P-256 public key from a SecKey.
  /// Exposed `internal` so tests can verify the encoding without keychain access.
  static func publicKeyJWK(for privateKey: SecKey) -> [String: String]? {
    guard let publicKey = SecKeyCopyPublicKey(privateKey),
          let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
    else { return nil }

    // EC P-256 uncompressed point: 0x04 || x (32 bytes) || y (32 bytes) — 65 bytes total.
    guard publicKeyData.count == 65, publicKeyData[0] == 0x04 else { return nil }

    let xBytes = publicKeyData.subdata(in: 1 ..< 33)
    let yBytes = publicKeyData.subdata(in: 33 ..< 65)
    return [
      "kty": "EC",
      "crv": "P-256",
      "x": xBytes.base64URLEncodedString(),
      "y": yBytes.base64URLEncodedString(),
    ]
  }

  /// Computes the RFC 7638 JWK Thumbprint of an EC JWK.
  static func thumbprint(for jwk: [String: String]) -> String? {
    guard let crv = jwk["crv"],
          let kty = jwk["kty"],
          let xCoord = jwk["x"],
          let yCoord = jwk["y"]
    else { return nil }

    // Canonical JSON per RFC 7638: required EC members in lexicographic order, no whitespace.
    let canonical = "{\"crv\":\"\(crv)\",\"kty\":\"\(kty)\",\"x\":\"\(xCoord)\",\"y\":\"\(yCoord)\"}"
    let hash = SHA256.hash(data: Data(canonical.utf8))
    return Data(hash).base64URLEncodedString()
  }
}

// MARK: - Keychain-backed store (production)

@available(iOS 13.0, *)
final class KeychainDPoPKeyStore: DPoPKeyStoring {

  private let keyTag = "com.facebook.sdk.dpop.key"

  func loadKey() -> SecKey? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Data(keyTag.utf8),
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let item = item else { return nil }

    return (item as! SecKey) // swiftlint:disable:this force_cast
  }

  func generateKey() throws -> SecKey {
    // Use the Secure Enclave on real devices only. `SecureEnclave.isAvailable`
    // returns true on Apple-silicon iOS simulators, but adding an SE-backed key
    // there fails with errSecMissingEntitlement because the test/host bundle
    // lacks the required signing entitlements. A compile-time simulator guard
    // gives us a deterministic software fallback in that environment.
    #if targetEnvironment(simulator)
    let useSecureEnclave = false
    #else
    let useSecureEnclave = SecureEnclave.isAvailable
    #endif

    var attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrApplicationTag as String: Data(keyTag.utf8),
    ]

    if useSecureEnclave {
      // SecAccessControlCreateWithFlags can return nil; guard it.
      guard let access = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        .privateKeyUsage,
        nil
      ) else {
        throw LimitedLoginRefreshError.dpopKeyGenerationFailed
      }

      attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
      attributes[kSecPrivateKeyAttrs as String] = [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: Data(keyTag.utf8),
        kSecAttrAccessControl as String: access,
      ] as [String: Any]
    } else {
      attributes[kSecPrivateKeyAttrs as String] = [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: Data(keyTag.utf8),
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      ] as [String: Any]
    }

    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw LimitedLoginRefreshError.unknown
    }

    return privateKey
  }

  func deleteKey() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Data(keyTag.utf8),
    ]
    SecItemDelete(query as CFDictionary)
  }
}
