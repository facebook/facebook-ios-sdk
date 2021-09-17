// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
