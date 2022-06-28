/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import FBSDKCoreKit_Basics
import TestTools
import XCTest

final class AuthenticationTokenHeaderTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var headerDictionary: [String: Any]!
  var header: AuthenticationTokenHeader!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    headerDictionary = [
      "alg": "RS256",
      "typ": "JWT",
      "kid": "abcd1234",
    ]

    guard
      let headerData = try? JSONSerialization.data(withJSONObject: headerDictionary as Any, options: []),
      let encodedHeader = try? base64URLEncoded(headerData)
    else {
      return
    }

    header = AuthenticationTokenHeader(fromEncodedString: encodedHeader)
  }

  override func tearDown() {
    header = nil
    headerDictionary = nil

    super.tearDown()
  }

  // MARK: - Decoding Header

  func testDecodeValidHeader() throws {
    XCTAssertEqual(header.kid, "abcd1234")
  }

  func testDecodeInvalidFormatHeader() throws {
    let headerData = try XCTUnwrap("invalid_header".data(using: .utf8))
    let encodedHeader = try base64URLEncoded(headerData)

    XCTAssertNil(AuthenticationTokenHeader(fromEncodedString: encodedHeader))
  }

  func testDecodeInvalidHeader() throws {
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
    data.base64EncodedString()
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
