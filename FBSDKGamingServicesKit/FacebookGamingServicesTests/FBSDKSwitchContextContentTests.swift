/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

class FBSDKSwitchContextContentTests: XCTestCase {

  lazy var content = SwitchContextContent(contextID: name)

  func testCreatingWithContextIdentifier() {
    XCTAssertEqual(
      content.contextTokenID,
      name,
      "Should store the context identifier it was created with"
    )
  }

  func testValidatingWithInvalidIdentifier() {
    content = SwitchContextContent(contextID: "")

    do {
      try content.validate()
      XCTFail("Content with an empty identifier should not be considered valid")
    } catch let error as NSError {
      XCTAssertEqual(error.domain, ErrorDomain)
      XCTAssertEqual(
        error.userInfo[ErrorDeveloperMessageKey] as? String,
        "The contextToken is required."
      )
    }
  }

  func testValidatingWithValidIdentifier() throws {
    XCTAssertNotNil(
      try? content.validate(),
      "Content with a non-empty identifier should be considered valid"
    )
  }

  func testHashability() {
    let identicalContent = SwitchContextContent(contextID: name)

    XCTAssertEqual(
      content.hashValue,
      identicalContent.hashValue,
      "Identical contents should have the same hash value"
    )
  }

  func testEquatability() {
    XCTAssertEqual(content, content)

    let contentWithSameProperties = SwitchContextContent(contextID: name)

    XCTAssertEqual(content, contentWithSameProperties)

    let contentWithDifferentProperties = SwitchContextContent(contextID: "foo")

    XCTAssertNotEqual(content, contentWithDifferentProperties)
  }

  func testSecureCoding() {
    XCTAssertTrue(
      SwitchContextContent.supportsSecureCoding,
      "Should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    content.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject["contextToken"] as? String,
      content.contextTokenID,
      "Should encode the token identifier under the expected key"
    )
  }

  func testDecoding() {
    let coder = TestCoder()

    _ = SwitchContextContent(coder: coder)

    XCTAssertTrue(
      coder.decodedObject["contextToken"] is NSString.Type,
      "Should attempt to decode a string for the context token"
    )
  }
}
