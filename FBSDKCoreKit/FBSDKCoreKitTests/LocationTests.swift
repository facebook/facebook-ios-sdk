/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

// MARK: Creation

final class LocationTests: XCTestCase {

  func testCreate() throws {
    let dict = ["id": "110843418940484", "name": "Seattle, Washington"]
    let location = try XCTUnwrap(Location(from: dict), "Should be able to create Location")
    XCTAssertEqual(location.id, dict["id"])
    XCTAssertEqual(location.name, dict["name"])
  }

  func testCreateWithIDOnly() {
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
