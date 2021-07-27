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

import FBSDKCoreKit

class UserAgeRangeTests: XCTestCase {

  func testCreateWithMinOnly() {
    let dict: [String: NSNumber] = ["min": 1]
    let ageRange = UserAgeRange(from: dict)

    XCTAssertNotNil(ageRange, "Should be able to create UserAgeRange with min value specified")
    XCTAssertEqual(ageRange?.min, dict["min"])
    XCTAssertNil(ageRange?.max)
  }

  func testCreateWithMaxOnly() {
    let dict: [String: NSNumber] = ["max": 1]
    let ageRange = UserAgeRange(from: dict)

    XCTAssertNotNil(ageRange, "Should be able to create UserAgeRange with max value specified")
    XCTAssertNil(ageRange?.min)
    XCTAssertEqual(ageRange?.max, dict["max"])
  }

  func testCreateWithMinSmallerThanMax() {
    let dict: [String: NSNumber] = ["min": 1, "max": 2]
    let ageRange = UserAgeRange(from: dict)

    XCTAssertNotNil(
      ageRange,
      "Should be able to create UserAgeRange with min value smaller than max"
    )
    XCTAssertEqual(ageRange?.min, dict["min"])
    XCTAssertEqual(ageRange?.max, dict["max"])
  }

  func testCreateFromEmptyDictionary() {
    XCTAssertNil(
      UserAgeRange(from: [:]),
      "Should not be able to create UserAgeRange from empty dictionary"
    )
  }

  func testCreateWithNegativeMin() {
    let dict: [String: NSNumber] = ["min": -1]
    XCTAssertNil(
      UserAgeRange(from: dict),
      "Should not be able to create UserAgeRange with negative min value"
    )
  }

  func testCreateWithNegativeMax() {
    let dict = ["max": -1 as NSNumber]
    XCTAssertNil(
      UserAgeRange(from: dict),
      "Should not be able to create UserAgeRange with negative max value"
    )
  }

  func testCreateWithMinLargerThanMax() {
    let dict: [String: NSNumber] = ["min": 2, "max": 1]
    XCTAssertNil(
      UserAgeRange(from: dict),
      "Should not be able to create UserAgeRange with min larger than max"
    )
  }

  func testCreateWithMinEqualToMax() {
    let dict: [String: NSNumber] = ["min": 1, "max": 1]
    XCTAssertNil(
      UserAgeRange(from: dict),
      "Should not be able to create UserAgeRange with min value equal to max"
    )
  }

  func testEncoding() throws {
    let dict: [String: NSNumber] = ["min": 1, "max": 2]
    let ageRange = try XCTUnwrap(
      UserAgeRange(from: dict),
      "Should be able to create UserAgeRange with min value specified"
    )

    let coder = TestCoder()
    ageRange.encode(with: coder)

    XCTAssertTrue(
      coder.encodedObject["FBSDKUserAgeRangeMinCodingKey"] as? NSNumber == ageRange.min,
      "Should encode the expected min value"
    )

    XCTAssertTrue(
      coder.encodedObject["FBSDKUserAgeRangeMaxCodingKey"] as? NSNumber == ageRange.max,
      "Should encode the expected max value"
    )
  }

  func testDecoding() {
    let coder = TestCoder()
    let ageRange = UserAgeRange(coder: coder)
    XCTAssertNotNil(ageRange)

    XCTAssertTrue(
      coder.decodedObject["FBSDKUserAgeRangeMinCodingKey"] as? Any.Type == NSNumber.self,
      "Should decode a number for the min key"
    )

    XCTAssertTrue(
      coder.decodedObject["FBSDKUserAgeRangeMaxCodingKey"] as? Any.Type == NSNumber.self,
      "Should decode a number for the min key"
    )
  }
}
