/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import XCTest

final class CameraEffectArgumentsTests: XCTestCase {
  func testTypes() {
    let arguments = CameraEffectArguments()

    // Supported types
    arguments.set("1234", forKey: "string")
    XCTAssertEqual(arguments.string(forKey: "string"), "1234")
    arguments.set(["a", "b", "c"], forKey: "string_array")
    XCTAssertEqual(arguments.array(forKey: "string_array"), ["a", "b", "c"])
    arguments.set([], forKey: "empty_array")
    XCTAssertEqual(arguments.array(forKey: "empty_array"), [])
    XCTAssertNil(arguments.string(forKey: "nil_string"))
    XCTAssertNil(arguments.array(forKey: "nil_array"))
  }
}
