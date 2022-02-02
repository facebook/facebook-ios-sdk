/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

final class SwitchContextContentTests: XCTestCase {

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

  func testEquatability() {
    XCTAssertEqual(content, content)

    let contentWithSameProperties = SwitchContextContent(contextID: name)

    XCTAssertEqual(content, contentWithSameProperties)

    let contentWithDifferentProperties = SwitchContextContent(contextID: "foo")

    XCTAssertNotEqual(content, contentWithDifferentProperties)
  }
}
