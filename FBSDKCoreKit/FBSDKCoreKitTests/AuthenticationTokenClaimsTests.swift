/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class AuthenticationTokenClaimsTests: XCTestCase {
  let appID = "4321"
  let jti = "some_jti"
  let nonce = "some_nonce"
  let facebookURL = "https://www.facebook.com/"
  let currentTime = Date().timeIntervalSince1970
  let settings = TestSettings()

  lazy var claims = makeClaims()
  lazy var claimsValues = getClaimsValues(from: claims)

  override func setUp() {
    super.setUp()

    // Calling the configuration method here ensures that subsequent calls in
    // the production code will be ignored and our test doubles from below
    // will be used
    AuthenticationTokenClaims.configureClassDependencies()

    settings.appID = appID
    AuthenticationTokenClaims.configure(settings: settings)
  }

  override func tearDown() {
    AuthenticationTokenClaims.resetClassDependencies()

    super.tearDown()
  }

  // MARK: - Class Dependencies

  func testDefaultClassDependencies() {
    AuthenticationTokenClaims.resetClassDependencies()
    AuthenticationTokenClaims.configureClassDependencies()

    XCTAssertTrue(
      AuthenticationTokenClaims.settings === Settings.shared,
      "The class should use the shared settings by default"
    )
  }

  // MARK: - Decoding Claims

  func testDecodeValidClaims() throws {
    let data = try TypeUtility.data(withJSONObject: claimsValues, options: [])
    let encoded = base64URLEncodeData(data)
    let decoded = AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce)
    XCTAssertEqual(decoded, claims)
  }

  func testDecodeValidClaimsWithLegacyIssuer() throws {
    var claims = claimsValues
    claims["iss"] = "https://facebook.com"
    let data = try TypeUtility.data(withJSONObject: claims, options: [])
    let encoded = base64URLEncodeData(data)
    let decoded = AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce)
    XCTAssertNotNil(decoded)
  }

  func testDecodeInvalidFormatClaims() {
    let data = "invalid_claims".data(using: .utf8)! // swiftlint:disable:this force_unwrapping
    let encoded = base64URLEncodeData(data)

    XCTAssertNil(AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce))
  }

  func testDecodeClaimsWithInvalidRequiredClaims() throws {
    try verifyDecodingFailure(key: "iss", value: "https://notfacebook.com", when: "issuer is not Facebook")
    try verifyDecodingFailure(key: "iss", value: nil, when: "issuer is not Facebook")
    try verifyDecodingFailure(key: "iss", value: "", when: "issuer is not Facebook")

    try verifyDecodingFailure(key: "aud", value: "wrong_app_id", when: "audience is incorrect")
    try verifyDecodingFailure(key: "aud", value: nil, when: "audience is incorrect")
    try verifyDecodingFailure(key: "aud", value: "", when: "audience is incorrect")

    try verifyDecodingFailure(key: "exp", value: currentTime - (60 * 60), when: "expired")
    try verifyDecodingFailure(key: "exp", value: nil, when: "expired")
    try verifyDecodingFailure(key: "exp", value: "", when: "expired")

    try verifyDecodingFailure(key: "iat", value: currentTime - (60 * 60), when: "issued too long ago")
    try verifyDecodingFailure(key: "iat", value: nil, when: "issued too long ago")
    try verifyDecodingFailure(key: "iat", value: "", when: "issued too long ago")

    try verifyDecodingFailure(key: "nonce", value: "incorrect_nonce", when: "nonce is incorrect")
    try verifyDecodingFailure(key: "nonce", value: nil, when: "nonce is incorrect")
    try verifyDecodingFailure(key: "nonce", value: "", when: "nonce is incorrect")

    try verifyDecodingFailure(key: "sub", value: nil, when: "user ID is invalid")
    try verifyDecodingFailure(key: "sub", value: "", when: "user ID is invalid")

    try verifyDecodingFailure(key: "jti", value: nil, when: "JIT is invalid")
    try verifyDecodingFailure(key: "jti", value: "", when: "JIT is invalid")
  }

  func testDecodeClaimsWithInvalidOptionalClaims() throws {
    let keys = [
      "name", "given_name", "middle_name", "family_name", "email",
      "picture", "user_friends", "user_birthday", "user_age_range",
      "user_hometown", "user_location", "user_gender", "user_link",
    ]

    try keys.forEach { key in
      try assertDecodeClaimsDropsInvalidEntry(key: key, value: nil)
      try assertDecodeClaimsDropsInvalidEntry(key: key, value: [:])
    }

    try assertDecodeClaimsDropsInvalidEntry(key: "user_friends", value: [:])

    try assertDecodeClaimsDropsInvalidEntry(key: "user_age_range", value: "")
    try assertDecodeClaimsDropsInvalidEntry(key: "user_age_range", value: ["min": 123, "max": "test"])
    try assertDecodeClaimsDropsInvalidEntry(key: "user_age_range", value: [:])

    try assertDecodeClaimsDropsInvalidEntry(key: "user_hometown", value: ["id": 123, "name": "test"])
    try assertDecodeClaimsDropsInvalidEntry(key: "user_hometown", value: "")
    try assertDecodeClaimsDropsInvalidEntry(key: "user_hometown", value: [:])

    try assertDecodeClaimsDropsInvalidEntry(key: "user_location", value: ["id": 123, "name": "test"])
    try assertDecodeClaimsDropsInvalidEntry(key: "user_location", value: "")
    try assertDecodeClaimsDropsInvalidEntry(key: "user_location", value: [:])
  }

  func testDecodeClaimsWithEmptyFriendsList() throws {
    var values = claimsValues
    values["user_friends"] = [String]()

    let data = try TypeUtility.data(withJSONObject: values, options: [])
    let encoded = base64URLEncodeData(data)

    let decoded = try XCTUnwrap(AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce))
    let friends = try XCTUnwrap(decoded.userFriends)
    XCTAssertTrue(friends.isEmpty)
  }

  func testDecodeEmptyClaims() throws {
    let data = try TypeUtility.data(withJSONObject: [String: Any?](), options: [])
    let encoded = base64URLEncodeData(data)

    XCTAssertNil(AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce))
  }

  // swiftlint:disable:next identifier_name
  func _testDecodeRandomClaims() throws {
    try XCTSkipIf(true) // see T98167812

    try (0 ..< 100).forEach { _ in
      let randomized = Fuzzer.randomize(json: claimsValues)
      let data = try TypeUtility.data(withJSONObject: randomized, options: [])
      let encoded = base64URLEncodeData(data)

      _ = AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce)
    }
  }
}

// MARK: - Helpers

extension AuthenticationTokenClaimsTests {
  func makeClaims() -> AuthenticationTokenClaims {
    AuthenticationTokenClaims(
      jti: jti,
      iss: facebookURL,
      aud: appID,
      nonce: nonce,
      exp: currentTime + 60 * 60 * 48, // 2 days later
      iat: currentTime - 60, // 1 min ago
      sub: "1234",
      name: "Test User",
      givenName: "Test",
      middleName: "Middle",
      familyName: "User",
      email: "email@email.com",
      picture: "https://www.facebook.com/some_picture",
      userFriends: ["1122", "3344", "5566"],
      userBirthday: "01/01/1990",
      userAgeRange: ["min": 21],
      userHometown: [
        "id": "112724962075996",
        "name": "Martinez, California",
      ],
      userLocation: [
        "id": "110843418940484",
        "name": "Seattle, Washington",
      ],
      userGender: "male",
      userLink: "facebook.com"
    )! // swiftlint:disable:this force_unwrapping
  }

  func getClaimsValues(from claims: AuthenticationTokenClaims) -> [String: Any] {
    var values: [String: Any] = [
      "iss": claims.iss,
      "aud": claims.aud,
      "nonce": claims.nonce,
      "exp": claims.exp,
      "iat": claims.iat,
      "jti": claims.jti,
      "sub": claims.sub,
    ]

    let optionalValues: [String: Any?] = [
      "name": claims.name,
      "given_name": claims.givenName,
      "middle_name": claims.middleName,
      "family_name": claims.familyName,
      "email": claims.email,
      "picture": claims.picture,
      "user_friends": claims.userFriends,
      "user_birthday": claims.userBirthday,
      "user_age_range": claims.userAgeRange,
      "user_hometown": claims.userHometown,
      "user_location": claims.userLocation,
      "user_gender": claims.userGender,
      "user_link": claims.userLink,
    ]

    for (key, potentialValue) in optionalValues {
      if let value = potentialValue {
        values[key] = value
      }
    }

    return values
  }

  func base64URLEncodeData(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  func verifyDecodingFailure(
    key: String,
    value potentialValue: Any?,
    when reason: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    var invalidClaims = claimsValues

    if let value = potentialValue {
      invalidClaims[key] = value
    } else {
      invalidClaims.removeValue(forKey: key)
    }

    let data = try TypeUtility.data(withJSONObject: invalidClaims, options: [])
    let encoded = base64URLEncodeData(data)

    XCTAssertNil(
      AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce),
      "Decoding of authentication token claims should fail when \(reason)",
      file: file,
      line: line
    )
  }

  func assertDecodeClaimsDropsInvalidEntry(
    key: String,
    value potentialValue: Any?,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    var invalidClaims = claimsValues

    if let value = potentialValue {
      invalidClaims[key] = value
    } else {
      invalidClaims.removeValue(forKey: key)
    }

    let data = try TypeUtility.data(withJSONObject: invalidClaims, options: [])
    let encoded = base64URLEncodeData(data)

    let claims = try XCTUnwrap(
      AuthenticationTokenClaims(fromEncodedString: encoded, nonce: nonce),
      file: file,
      line: line
    )

    let claimsValues = getClaimsValues(from: claims)
    XCTAssertNil(claimsValues[key], file: file, line: line)
  }
}
