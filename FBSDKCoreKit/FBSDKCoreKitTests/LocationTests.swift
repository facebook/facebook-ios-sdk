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

import XCTest

// MARK: Creation

class LocationTests: XCTestCase {

  func testCreate() throws {
    let dict = ["id": "110843418940484", "name": "Seattle, Washington"]
    let location = try XCTUnwrap(Location(from: dict), "Should be able to create Location")
    XCTAssertEqual(location.id, dict["id"])
    XCTAssertEqual(location.name, dict["name"])
  }

  func testCreateWithIdOnly() {
    let dict = ["id": "110843418940484"]
    let location = Location(from: dict)

    XCTAssertNil(
      location,
      "Should not be able to create Location with no name specified"
    )
  }

  func testCreateWithNameOnly() {
    let dict = ["name": "Seattle, Washington"]
    let location = Location(from: dict)

    XCTAssertNil(
      location,
      "Should not be able to create Location with no id specified"
    )
  }

  func testCreateWithEmptyDictionary() {
    XCTAssertNil(Location(from: [:]), "Should not be able to create Location from empty dictionary")
  }

  func testEncoding() throws {
    let dict = ["id": "110843418940484", "name": "Seattle, Washington"]
    let location = try XCTUnwrap(Location(from: dict))

    let coder = TestCoder()
    location.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject["FBSDKLocationIdCodingKey"] as? String,
      location.id,
      "Should encode the expected id value"
    )
  }

  func testDecoding() {
    let coder = TestCoder()
    let location = Location(coder: coder)

    XCTAssertNotNil(location)
    XCTAssertTrue(
      coder.decodedObject["FBSDKLocationIdCodingKey"] as? Any.Type == NSString.self,
      "Should decode a string for the id key"
    )
    XCTAssertTrue(
      coder.decodedObject["FBSDKLocationNameCodingKey"] as? Any.Type == NSString.self,
      "Should decode a string for the name key"
    )
  }
}
