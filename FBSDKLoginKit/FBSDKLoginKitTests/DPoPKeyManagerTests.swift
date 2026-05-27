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

/// In-memory store backed by a transient `SecKey` so tests run without keychain entitlement.
@available(iOS 13.0, *)
final class InMemoryDPoPKeyStore: DPoPKeyStoring {

  private var key: SecKey?

  func loadKey() -> SecKey? { key }

  func generateKey() throws -> SecKey {
    // Transient key (never persisted) — works in xctest without entitlements.
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: false] as [String: Any],
    ]
    var error: Unmanaged<CFError>?
    guard let newKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw LimitedLoginRefreshError.dpopKeyGenerationFailed
    }
    key = newKey
    return newKey
  }

  func deleteKey() { key = nil }
}

@available(iOS 13.0, *)
final class DPoPKeyManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  private var store: InMemoryDPoPKeyStore!
  private var manager: DPoPKeyManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    store = InMemoryDPoPKeyStore()
    manager = DPoPKeyManager(store: store)
  }

  override func tearDown() {
    manager = nil
    store = nil
    super.tearDown()
  }

  // MARK: - Lifecycle

  func testGenerateKeyPairCreatesKey() throws {
    let key = try manager.generateKeyPair()
    XCTAssertNotNil(SecKeyCopyPublicKey(key))
    XCTAssertNotNil(manager.getPrivateKey())
  }

  func testGenerateKeyPairReplacesExistingKey() throws {
    let first = try manager.generateKeyPair()
    let second = try manager.generateKeyPair()
    let firstPub = try XCTUnwrap(SecKeyCopyPublicKey(first))
    let secondPub = try XCTUnwrap(SecKeyCopyPublicKey(second))
    let firstData = SecKeyCopyExternalRepresentation(firstPub, nil) as Data?
    let secondData = SecKeyCopyExternalRepresentation(secondPub, nil) as Data?
    XCTAssertNotEqual(firstData, secondData)
  }

  func testGenerateKeyPairIfNeededReturnsExistingKey() throws {
    let first = try manager.generateKeyPairIfNeeded()
    let second = try manager.generateKeyPairIfNeeded()
    let firstPub = try XCTUnwrap(SecKeyCopyPublicKey(first))
    let secondPub = try XCTUnwrap(SecKeyCopyPublicKey(second))
    let firstData = SecKeyCopyExternalRepresentation(firstPub, nil) as Data?
    let secondData = SecKeyCopyExternalRepresentation(secondPub, nil) as Data?
    XCTAssertEqual(firstData, secondData)
  }

  func testGenerateKeyPairIfNeededCreatesKeyWhenMissing() throws {
    XCTAssertNil(manager.getPrivateKey())
    _ = try manager.generateKeyPairIfNeeded()
    XCTAssertNotNil(manager.getPrivateKey())
  }

  func testGetPrivateKeyRetrievesExistingKey() throws {
    _ = try manager.generateKeyPair()
    XCTAssertNotNil(manager.getPrivateKey())
  }

  func testDeleteKeyPairRemovesKey() throws {
    _ = try manager.generateKeyPair()
    XCTAssertNotNil(manager.getPrivateKey())
    manager.deleteKeyPair()
    XCTAssertNil(manager.getPrivateKey())
  }

  func testGetPrivateKeyReturnsNilAfterDelete() throws {
    _ = try manager.generateKeyPair()
    manager.deleteKeyPair()
    XCTAssertNil(manager.getPrivateKey())
  }

  // MARK: - JWK / Thumbprint

  func testGetPublicKeyJWKReturnsValidStructure() throws {
    _ = try manager.generateKeyPair()
    let jwk = try XCTUnwrap(manager.getPublicKeyJWK())
    XCTAssertEqual(jwk["kty"], "EC")
    XCTAssertEqual(jwk["crv"], "P-256")
    XCTAssertEqual(jwk["x"]?.count, 43)
    XCTAssertEqual(jwk["y"]?.count, 43)
  }

  func testGetPublicKeyJWKReturnsNilWhenNoKey() {
    XCTAssertNil(manager.getPublicKeyJWK())
  }

  func testGetJWKThumbprintReturns43Characters() throws {
    _ = try manager.generateKeyPair()
    let thumbprint = try XCTUnwrap(manager.getJWKThumbprint())
    XCTAssertEqual(thumbprint.count, 43)
  }

  func testJWKThumbprintIsStableForSameKey() throws {
    _ = try manager.generateKeyPair()
    let first = manager.getJWKThumbprint()
    let second = manager.getJWKThumbprint()
    XCTAssertNotNil(first)
    XCTAssertEqual(first, second)
  }

  func testJWKThumbprintChangesForDifferentKey() throws {
    _ = try manager.generateKeyPair()
    let first = manager.getJWKThumbprint()
    _ = try manager.generateKeyPair()
    let second = manager.getJWKThumbprint()
    XCTAssertNotNil(first)
    XCTAssertNotNil(second)
    XCTAssertNotEqual(first, second)
  }

  func testJWKThumbprintMatchesRFC7638CanonicalJSON() throws {
    _ = try manager.generateKeyPair()
    let jwk = try XCTUnwrap(manager.getPublicKeyJWK())
    let crv = try XCTUnwrap(jwk["crv"])
    let kty = try XCTUnwrap(jwk["kty"])
    let xCoord = try XCTUnwrap(jwk["x"])
    let yCoord = try XCTUnwrap(jwk["y"])
    let canonical = "{\"crv\":\"\(crv)\",\"kty\":\"\(kty)\",\"x\":\"\(xCoord)\",\"y\":\"\(yCoord)\"}"
    let expected = Data(SHA256.hash(data: Data(canonical.utf8))).base64URLEncodedString()
    XCTAssertEqual(manager.getJWKThumbprint(), expected)
  }

  // MARK: - RFC 7638 reference vector

  /// Verifies the thumbprint computation against a hand-built JWK so we know the canonical
  /// JSON ordering and SHA-256 hashing produce a stable, externally reproducible value.
  func testThumbprintMatchesExpectedValueForFixedJWK() {
    let jwk: [String: String] = [
      "kty": "EC",
      "crv": "P-256",
      "x": "f83OJ3D2xF4_AAA_AAA_AAA_AAA_AAA_AAA_AAA_AAA",
      "y": "x_FEzRu9d8jWzCNJ0PqJYHHaXpKJ_AAA_AAA_AAA_AAA",
    ]
    let canonical = "{\"crv\":\"P-256\",\"kty\":\"EC\","
      + "\"x\":\"f83OJ3D2xF4_AAA_AAA_AAA_AAA_AAA_AAA_AAA_AAA\","
      + "\"y\":\"x_FEzRu9d8jWzCNJ0PqJYHHaXpKJ_AAA_AAA_AAA_AAA\"}"
    let expected = Data(SHA256.hash(data: Data(canonical.utf8))).base64URLEncodedString()
    XCTAssertEqual(DPoPKeyManager.thumbprint(for: jwk), expected)
  }
}
