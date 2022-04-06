/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

@testable import FBAEMKit
import XCTest

final class AEMRequestBodyTests: XCTestCase {
  func testEmptyBody() throws {
    let body = _AEMRequestBody()
    XCTAssertNil(body.compressedData())
    XCTAssertEqual(body.data.count, 0)

    let multipartData = try XCTUnwrap(body.multipartData)
    XCTAssertEqual(multipartData.count, 0)
  }

  func testAppendEmptyKeyWithEmptyValue() throws {
    let body = _AEMRequestBody()
    body.append(withKey: "", formValue: "")
    XCTAssertNotNil(body.compressedData())

    let multipartString = try makeString(multipartData: body.multipartData)
    let expectedMultipartString = "--\r\nContent-Disposition: form-data; name=\"\"\r\n\r\n\r\n"
    XCTAssertEqual(multipartString, expectedMultipartString)

    let dictionary = try makeStringDictionary(jsonData: body.data)
    XCTAssertEqual(dictionary.keys.count, 1)
    XCTAssertEqual(dictionary[""], "")
  }

  func testAppendEmptyKeyWithNonEmptyValue() throws {
    let body = _AEMRequestBody()
    body.append(withKey: "", formValue: "value")
    XCTAssertNotNil(body.compressedData())

    let multipartString = try makeString(multipartData: body.multipartData)
    let expectedMultipartString = "--\r\nContent-Disposition: form-data; name=\"\"\r\n\r\nvalue\r\n"
    XCTAssertEqual(multipartString, expectedMultipartString)

    let dictionary = try makeStringDictionary(jsonData: body.data)
    XCTAssertEqual(dictionary.keys.count, 1)
    XCTAssertEqual(dictionary[""], "value")
  }

  func testAppendNonEmptyKeyWithEmptyValue() throws {
    let body = _AEMRequestBody()
    body.append(withKey: "key", formValue: "")
    XCTAssertNotNil(body.compressedData())

    let multipartString = try makeString(multipartData: body.multipartData)
    let expectedMultipartString = "--\r\nContent-Disposition: form-data; name=\"key\"\r\n\r\n\r\n"
    XCTAssertEqual(multipartString, expectedMultipartString)

    let dictionary = try makeStringDictionary(jsonData: body.data)
    XCTAssertEqual(dictionary.keys.count, 1)
    XCTAssertEqual(dictionary["key"], "")
  }

  func testAppendKeysAndValuesWithEscapedCharacters() throws {
    let body = _AEMRequestBody()
    body.append(withKey: "\u{F09F}\u{918D}", formValue: "\u{F09F}\u{918E}")
    body.append(withKey: "\0", formValue: "\0")
    XCTAssertNotNil(body.compressedData())

    let multipartString = try makeString(multipartData: body.multipartData)

    // swiftlint:disable:next line_length
    let expectedMultipartString = "--\r\nContent-Disposition: form-data; name=\"\u{F09F}\u{918D}\"\r\n\r\n\u{F09F}\u{918E}\r\nContent-Disposition: form-data; name=\"\0\"\r\n\r\n\0\r\n"

    XCTAssertEqual(multipartString, expectedMultipartString)

    let dictionary = try makeStringDictionary(jsonData: body.data)
    XCTAssertEqual(dictionary.keys.count, 2)
    XCTAssertEqual(dictionary["\u{F09F}\u{918D}"], "\u{F09F}\u{918E}")
    XCTAssertEqual(dictionary["\0"], "\0")
  }

  private func makeString(multipartData: Data?) throws -> String {
    let multipartData = try XCTUnwrap(multipartData)
    let utf8String = String(data: multipartData, encoding: .utf8)
    return try XCTUnwrap(utf8String)
  }

  private func makeStringDictionary(jsonData: Data) throws -> [String: String] {
    let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
    return try XCTUnwrap(json as? [String: String])
  }
}

#endif
