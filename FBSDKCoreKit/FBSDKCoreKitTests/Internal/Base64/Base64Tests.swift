/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class Base64Tests: XCTestCase {

  func runTests(_ testsDict: [String: String]) {
    for (plainString, base64String) in testsDict {
      XCTAssertEqual(Base64.encode(plainString), base64String)
      XCTAssertEqual(Base64.decode(as: base64String), plainString)
    }
  }

  func testRFC4648TestVectors() {
    let testsDict = [
      "": "",
      "f": "Zg==",
      "fo": "Zm8=",
      "foo": "Zm9v",
      "foob": "Zm9vYg==",
      "fooba": "Zm9vYmE=",
      "foobar": "Zm9vYmFy",
    ]
    runTests(testsDict)
  }

  func testDecodeVariations() {
    XCTAssertEqual(Base64.decode(as: "aGVsbG8gd29ybGQh"), "hello world!")
    XCTAssertEqual(Base64.decode(as: "a  GVs\tb\r\nG8gd2\n9y\rbGQ h"), "hello world!")
    XCTAssertEqual(Base64.decode(as: "aGVsbG8gd29ybGQh"), "hello world!")
    XCTAssertEqual(Base64.decode(as: "aGVs#bG8*gd^29yb$GQh"), "hello world!")
  }

  func testEncodeDecode() {
    let testsDict = [
      "Hello World": "SGVsbG8gV29ybGQ=",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!%^&*(){}[]": "QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVoxMjM0NTY3ODkwISVeJiooKXt9W10=", // swiftlint:disable:this line_length
      "\n\t Line with control characters\r\n": "CgkgTGluZSB3aXRoIGNvbnRyb2wgY2hhcmFjdGVycw0K",
    ]
    runTests(testsDict)
  }

  func testBase64URLEncode() {
    let urlString = "https://www.example.com/some-path-with-dashes-in-it/"
    let encodedString = Base64.base64(fromBase64Url: urlString)
    XCTAssertEqual(encodedString, "https://www.example.com/some+path+with+dashes+in+it/")
  }
}
