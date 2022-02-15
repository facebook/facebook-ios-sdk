/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class CodeVerifierTests: XCTestCase {

  func testDefaultInitialization() {
    let codeVerifier = CodeVerifier()
    XCTAssertNotNil(codeVerifier.value)
  }

  func testInvalidCodeVerifers() {
    [
      "",
      "abcdefg", // too short
      String(repeating: "a", count: 129), // too long
      "OB6imf0pt3YLueBtNlljrdJZXdFk8gKJ97UQEpz1ojlEUL4p=", // invalid character
    ].forEach { codeVerifier in
      XCTAssertNil(
        CodeVerifier(string: codeVerifier),
        "Should not consider: \(codeVerifier) to be a valid code verifier"
      )
    }
  }

  func testValidCodeVerifers() {
    [
      String(repeating: "a", count: 43),
      String(repeating: "a", count: 128),
      "OB6imf0pt3YLueBtNlljrdJZXdFk8gKJ97UQEpz1ojlEUL4p",
      "OB6imf0pt3YLueBtNlljrdJZXdFk8gKJ97UQEpz1ojlEUL4p-._~",
    ].forEach { codeVerifier in
      XCTAssertNotNil(
        CodeVerifier(string: codeVerifier),
        "Should consider: \(codeVerifier) to be a valid code verifier"
      )
    }
  }

  func testCodeChallenge() throws {
    let codeVerifier = CodeVerifier(string: "OB6imf0pt3YLueBtNlljrdJZXdFk8gKJ97UQEpz1ojlEUL4p")
    let challenge = try XCTUnwrap(codeVerifier?.challenge)
    XCTAssertEqual(challenge, "4oJe_Hdk_xC_YCWjumgE5RjIkW-YVmFm_nYnIckxR0c")
  }
}
