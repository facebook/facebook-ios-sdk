/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class MathUtilityTests: XCTestCase {
  func testCeilForSize() {
    let fixtures: [(size: CGSize, expectedSize: CGSize)] = [
      (CGSize.zero, .zero),
      (CGSize(width: 10.1, height: 10.1), CGSize(width: 11, height: 11)),
      (CGSize(width: 10.5, height: 10.5), CGSize(width: 11, height: 11)),
      (CGSize(width: 10.7, height: 10.7), CGSize(width: 11, height: 11)),
    ]

    fixtures.forEach { fixture in
      XCTAssertEqual(
        FBSDKMath.ceil(for: fixture.size),
        fixture.expectedSize,
        "Should provide the correct ceiling size for \(fixture.size)"
      )
    }
  }

  func testFloorForSize() {
    let fixtures: [(size: CGSize, expectedSize: CGSize)] = [
      (CGSize.zero, .zero),
      (CGSize(width: 10.1, height: 10.1), CGSize(width: 10, height: 10)),
      (CGSize(width: 10.5, height: 10.5), CGSize(width: 10, height: 10)),
      (CGSize(width: 10.7, height: 10.7), CGSize(width: 10, height: 10)),
    ]

    fixtures.forEach { fixture in
      XCTAssertEqual(
        FBSDKMath.floor(for: fixture.size),
        fixture.expectedSize,
        "Should provide the correct floor size for \(fixture.size)"
      )
    }
  }

  func testHashWithInteger() {
    XCTAssertEqual(
      14624536017465086961,
      FBSDKMath.hash(with: 5),
      "Hashing an integer should return a predictable value"
    )
  }

  func testHashWithIntegerArray() {
    var array: [UInt] = [1, 2, 3]
    let hash = FBSDKMath.hash(withIntegerArray: &array, count: 10)
    let hash2 = FBSDKMath.hash(withIntegerArray: &array, count: 10)

    XCTAssertEqual(
      hash,
      hash2,
      "Hashing functions should return predicable values"
    )
  }

  func testHashingIntegerArrayWithEmptyCount() {
    var array: [UInt] = [1, 2, 3]
    XCTAssertEqual(FBSDKMath.hash(withIntegerArray: &array, count: 0), 0)
  }
}
