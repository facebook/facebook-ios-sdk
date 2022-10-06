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
  var currentTime = Date().timeIntervalSince1970

  // swiftlint:disable implicitly_unwrapped_optional
  var settings: SettingsProtocol!
  var claims: AuthenticationTokenClaims!
  var claimsValues: [String: Any]!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    settings.appID = appID
    AuthenticationTokenClaims.setDependencies(.init(settings: settings))

    claims = makeClaims()
    claimsValues = getClaimsValues(from: claims)
  }

  override func tearDown() {
    AuthenticationTokenClaims.resetDependencies()

    settings = nil
    claims = nil
    claimsValues = nil

    super.tearDown()
  }

  // MARK: - Class Dependencies

  func testDefaultClassDependencies() throws {
    AuthenticationTokenClaims.resetDependencies()

    let dependencies = try AuthenticationTokenClaims.getDependencies()

    XCTAssertTrue(
      dependencies.settings === Settings.shared,
      "The class should use the shared settings by default"
    )
  }

  func testCustomClassDependencies() throws {
    let dependencies = try AuthenticationTokenClaims.getDependencies()

    XCTAssertTrue(
      dependencies.settings === settings,
      "Should be able to configure the settings dependency on the type"
    )
  }

  // MARK: - Decoding Claims

  func testDecodeValidClaims() throws {
    let values = try XCTUnwrap(claimsValues)
    let data = try TypeUtility.data(withJSONObject: values, options: [])
    let encoded = base64URLEncodeData(data)
    let decoded = try XCTUnwrap(
      AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce)
    )

    XCTAssertTrue(claimsAreEqual(decoded, claims))
  }

  func testDecodeValidClaimsWithLegacyIssuer() throws {
    var claims = try XCTUnwrap(claimsValues)
    claims["iss"] = "https://facebook.com"
    let data = try TypeUtility.data(withJSONObject: claims, options: [])
    let encoded = base64URLEncodeData(data)
    let decoded = AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce)
    XCTAssertNotNil(decoded)
  }

  func testDecodeInvalidFormatClaims() {
    let data = "invalid_claims".data(using: .utf8)! // swiftlint:disable:this force_unwrapping
    let encoded = base64URLEncodeData(data)

    XCTAssertNil(AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce))
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
    var values = try XCTUnwrap(claimsValues)
    values["user_friends"] = [String]()

    let data = try TypeUtility.data(withJSONObject: values, options: [])
    let encoded = base64URLEncodeData(data)

    let decoded = try XCTUnwrap(AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce))
    let friends = try XCTUnwrap(decoded.userFriends)
    XCTAssertTrue(friends.isEmpty)
  }

  func testDecodeEmptyClaims() throws {
    let data = try TypeUtility.data(withJSONObject: [String: Any?](), options: [])
    let encoded = base64URLEncodeData(data)

    XCTAssertNil(AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce))
  }

  // swiftlint:disable:next identifier_name
  func _testDecodeRandomClaims() throws {
    try XCTSkipIf(true) // see T98167812
    let values = try XCTUnwrap(claimsValues)

    try (0 ..< 100).forEach { _ in
      let randomized = Fuzzer.randomize(json: values)
      let data = try TypeUtility.data(withJSONObject: randomized, options: [])
      let encoded = base64URLEncodeData(data)

      _ = AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce)
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
    )
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
    var invalidClaims = try XCTUnwrap(claimsValues)

    if let value = potentialValue {
      invalidClaims[key] = value
    } else {
      invalidClaims.removeValue(forKey: key)
    }

    let data = try TypeUtility.data(withJSONObject: invalidClaims, options: [])
    let encoded = base64URLEncodeData(data)

    XCTAssertNil(
      AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce),
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
    var invalidClaims = try XCTUnwrap(claimsValues)

    if let value = potentialValue {
      invalidClaims[key] = value
    } else {
      invalidClaims.removeValue(forKey: key)
    }

    let data = try TypeUtility.data(withJSONObject: invalidClaims, options: [])
    let encoded = base64URLEncodeData(data)

    let claims = try XCTUnwrap(
      AuthenticationTokenClaims(encodedClaims: encoded, nonce: nonce),
      file: file,
      line: line
    )

    let claimsValues = getClaimsValues(from: claims)
    XCTAssertNil(claimsValues[key], file: file, line: line)
  }

  private func claimsAreEqual(_ claims: AuthenticationTokenClaims, _ otherClaims: AuthenticationTokenClaims) -> Bool {
    claims.jti == otherClaims.jti
      && claims.iss == otherClaims.iss
      && claims.aud == otherClaims.aud
      && claims.nonce == otherClaims.nonce
      && claims.exp == otherClaims.exp
      && claims.iat == otherClaims.iat
      && claims.sub == otherClaims.sub
      && claims.name == otherClaims.name
      && claims.givenName == otherClaims.givenName
      && claims.middleName == otherClaims.middleName
      && claims.familyName == otherClaims.familyName
      && claims.email == otherClaims.email
      && claims.picture == otherClaims.picture
      && claims.userFriends == otherClaims.userFriends
      && claims.userBirthday == otherClaims.userBirthday
      && claims.userAgeRange == otherClaims.userAgeRange
      && claims.userHometown == otherClaims.userHometown
      && claims.userLocation == otherClaims.userLocation
      && claims.userGender == otherClaims.userGender
      && claims.userLink == otherClaims.userLink
  }
}
