/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

import FBSDKCoreKit_Basics
import TestTools

class AuthenticationTokenHeaderTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var header: AuthenticationTokenHeader!
  var headerDictionary: [String: Any]!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    header = AuthenticationTokenHeader(
      alg: "RS256",
      typ: "JWT",
      kid: "abcd1234"
    )

    headerDictionary = [
      "alg": header.alg,
      "typ": header.typ,
      "kid": header.kid
    ]
  }

  override func tearDown() {
    header = nil
    headerDictionary = nil

    super.tearDown()
  }

  // MARK: - Decoding Header

  func testDecodeValidHeader() throws {
    let headerData = try JSONSerialization.data(withJSONObject: headerDictionary as Any, options: [])
    let encodedHeader = try base64URLEncoded(headerData)

    let decodedHeader = AuthenticationTokenHeader(fromEncodedString: encodedHeader)

    XCTAssertEqual(header, decodedHeader)
  }

  func testDecodeInvalidFormatHeader() throws {
    let headerData = try XCTUnwrap("invalid_header".data(using: .utf8))
    let encodedHeader = try base64URLEncoded(headerData)

    XCTAssertNil(AuthenticationTokenHeader(fromEncodedString: encodedHeader))
  }

  func testDecodeInvalidHeader() throws {
    try assertDecodeHeaderFailWithInvalidEntry(key: "alg", value: "wrong_algorithm")
    try assertDecodeHeaderFailWithInvalidEntry(key: "alg", value: nil)
    try assertDecodeHeaderFailWithInvalidEntry(key: "alg", value: "")

    try assertDecodeHeaderFailWithInvalidEntry(key: "typ", value: "some_type")
    try assertDecodeHeaderFailWithInvalidEntry(key: "typ", value: nil)
    try assertDecodeHeaderFailWithInvalidEntry(key: "typ", value: "")

    try assertDecodeHeaderFailWithInvalidEntry(key: "kid", value: nil)
    try assertDecodeHeaderFailWithInvalidEntry(key: "kid", value: "")
  }

  func testDecodeEmptyHeader() throws {
    let header = [String: Any]()
    let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
    let encodedHeader = try base64URLEncoded(headerData)

    XCTAssertNil(AuthenticationTokenHeader(fromEncodedString: encodedHeader))
  }

  func testDecodeRandomHeader() throws {
    try (1 ..< 100).forEach { _ in
      let randomizedHeader = Fuzzer.randomize(json: headerDictionary as Any)
      guard JSONSerialization.isValidJSONObject(randomizedHeader) else { return }

      let headerData = try JSONSerialization.data(withJSONObject: randomizedHeader, options: [])
      let encodedHeader = try base64URLEncoded(headerData)
      _ = AuthenticationTokenHeader(fromEncodedString: encodedHeader)
    }
  }

  // MARK: - Helpers

  func base64URLEncoded(_ data: Data) throws -> String {
    let base64 = try XCTUnwrap(
      Base64.encode(data),
      "Unable to base 64 encode data"
    )
    return base64
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  func assertDecodeHeaderFailWithInvalidEntry(
    key: String,
    value: Any?,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) throws {
    headerDictionary[key] = value

    let headerData = try JSONSerialization.data(withJSONObject: headerDictionary as Any, options: [])
    let encodedHeader = try base64URLEncoded(headerData)

    XCTAssertNil(
      AuthenticationTokenHeader(fromEncodedString: encodedHeader),
      """
      Should not be able to create a token from a dictionary
      with the value: \(String(describing: value)) for the key: \(key)
      """,
      file: file,
      line: line
    )
  }
}
