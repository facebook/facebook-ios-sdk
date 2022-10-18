/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class ValueClampingTests: XCTestCase {
  func testIntegerClamping() {
    XCTAssertEqual((-1).fb_clamped(to: 0 ... 2), 0, .clampedValue)
    XCTAssertEqual(1.fb_clamped(to: 0 ... 2), 1, .clampedValue)
    XCTAssertEqual(3.fb_clamped(to: 0 ... 2), 2, .clampedValue)
  }

  func testDoubleClamping() {
    XCTAssertEqual((-1.0).fb_clamped(to: 0.0 ... 2.0), 0.0, .clampedValue)
    XCTAssertEqual(1.0.fb_clamped(to: 0.0 ... 2.0), 1.0, .clampedValue)
    XCTAssertEqual(3.0.fb_clamped(to: 0.0 ... 2.0), 2.0, .clampedValue)
  }
}

// MARK: - Assumptions

// swiftformat:disable:next extensionAccessControl
fileprivate extension String {
  static let clampedValue = """
    Clamping a comparable value to a range leaves an in-range value unaltered and moves an out-of-range value to the \
    nearest value in the range.
    """
}
