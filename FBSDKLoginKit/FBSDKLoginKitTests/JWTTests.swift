/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import Foundation
import XCTest

final class JWTTests: XCTestCase {

  // MARK: - Helpers

  private func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private func makeJWT(payload: [String: Any]) throws -> String {
    let header = ["alg": "RS256", "typ": "JWT"]
    let headerSegment = base64URLEncode(try JSONSerialization.data(withJSONObject: header))
    let payloadSegment = base64URLEncode(try JSONSerialization.data(withJSONObject: payload))
    return "\(headerSegment).\(payloadSegment).fakesignature"
  }

  // MARK: - Happy path

  func testReturnsPayloadDictionaryForValidJWT() throws {
    let claims: [String: Any] = [
      "iss": "https://www.facebook.com",
      "sub": "1234",
      "aud": "app",
      "iat": 1_700_000_000,
      "nonce": "abc",
    ]
    let jwt = try makeJWT(payload: claims)

    let decoded = JWT.payload(from: jwt)

    XCTAssertEqual(decoded?["sub"] as? String, "1234")
    XCTAssertEqual(decoded?["aud"] as? String, "app")
    XCTAssertEqual(decoded?["iat"] as? Int, 1_700_000_000)
    XCTAssertEqual(decoded?["nonce"] as? String, "abc")
  }

  func testReturnsNestedClaim() throws {
    // `cnf.jkt` is the most common nested claim we read in production.
    let claims: [String: Any] = [
      "sub": "1234",
      "cnf": ["jkt": "deadbeef-thumbprint"],
    ]
    let jwt = try makeJWT(payload: claims)

    let decoded = JWT.payload(from: jwt)
    let cnf = decoded?["cnf"] as? [String: Any]
    XCTAssertEqual(cnf?["jkt"] as? String, "deadbeef-thumbprint")
  }

  func testIgnoresStaleIatThatAuthenticationTokenClaimsWouldReject() throws {
    // Regression: AuthenticationTokenClaims.init? rejects iat > 10 min ago, but
    // JWT.payload must not — it's the validation-free reader by design.
    let claims: [String: Any] = ["sub": "1234", "iat": 1_000]
    let jwt = try makeJWT(payload: claims)

    XCTAssertNotNil(JWT.payload(from: jwt))
  }

  // MARK: - Padding edge cases

  func testHandlesPayloadRequiringPadding() throws {
    // Use a value whose JSON encoding produces a base64url string of length
    // not divisible by 4 (forcing the padding loop to run).
    let claims: [String: Any] = ["a": "b"] // {"a":"b"} → 7 bytes → base64 length 12 (already aligned)
    let jwt = try makeJWT(payload: claims)
    XCTAssertNotNil(JWT.payload(from: jwt))

    // Hand-roll a payload that produces a base64url length not divisible by 4
    // (forcing the padding loop to run).
    let raw = #"{"k":"value"}"# // 13 bytes → base64 length ~20, needs padding
    let manualSegment = base64URLEncode(Data(raw.utf8))
    let jwtManual = "headerseg.\(manualSegment).sigseg"
    let decoded = JWT.payload(from: jwtManual)
    XCTAssertEqual(decoded?["k"] as? String, "value")
  }

  // MARK: - Malformed input

  func testReturnsNilForNonJWTString() {
    XCTAssertNil(JWT.payload(from: ""))
    XCTAssertNil(JWT.payload(from: "not a jwt"))
    XCTAssertNil(JWT.payload(from: "only.two"))
    XCTAssertNil(JWT.payload(from: "a.b.c.d"))
  }

  func testReturnsNilWhenPayloadSegmentIsNotBase64URL() {
    XCTAssertNil(JWT.payload(from: "header.@@@invalid@@@.sig"))
  }

  func testReturnsNilWhenPayloadSegmentDecodesToNonJSON() {
    let payloadSegment = base64URLEncode(Data("not json".utf8))
    XCTAssertNil(JWT.payload(from: "header.\(payloadSegment).sig"))
  }

  func testReturnsNilWhenPayloadSegmentDecodesToJSONArray() throws {
    // Top-level must be an object/dictionary; arrays should not decode.
    let payloadSegment = base64URLEncode(try JSONSerialization.data(withJSONObject: [1, 2, 3]))
    XCTAssertNil(JWT.payload(from: "header.\(payloadSegment).sig"))
  }
}
