/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices
import XCTest

class FBSDKGamingContextTests: XCTestCase {

  func testCreating() throws {
    let context = try XCTUnwrap(GamingContext(identifier: name, size: 2))
    XCTAssertNotNil(
      context,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.identifier,
      name,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.size,
      2,
      "Should be able to create a context with a valid size"
    )
  }

  func testCreatingWithSizeLessThanZero() throws {
    let context = try XCTUnwrap(GamingContext(identifier: name, size: -2))
    XCTAssertNotNil(
      context,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.identifier,
      name,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.size,
      0,
      "Should not set size less than 0"
    )
  }

  func testCreatingWithEmptyIdentifier() {
    let context = GamingContext(identifier: "", size: 2)
    XCTAssertNil(
      context,
      "Should not be able to create a context with a invalid identifier"
    )
  }
}
