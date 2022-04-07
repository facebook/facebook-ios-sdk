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

  func testEncodingAndDecoding() throws {
    let dict = ["id": "110843418940484", "name": "Seattle, Washington"]
    let location = try XCTUnwrap(Location(from: dict))

    let decodedObject = try CodabilityTesting.encodeAndDecode(location)

    // Test Objects
    XCTAssertNotIdentical(location, decodedObject, .isCodable)
    XCTAssertEqual(location, decodedObject, .isCodable)

    // Test Properties
    XCTAssertEqual(location.id, decodedObject.id, .isCodable)
    XCTAssertEqual(location.name, decodedObject.name, .isCodable)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "Location should be encodable and decodable"
}
