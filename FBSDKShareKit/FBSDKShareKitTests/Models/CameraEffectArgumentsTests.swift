/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class CameraEffectArgumentsTests: XCTestCase {

  func testCopy() {
    let arguments = ShareModelTestUtility.cameraEffectArguments
    XCTAssertEqual(arguments.copy() as? CameraEffectArguments, arguments)
  }

  @available(iOS 11.0, *)
  func testCoding() throws {
    let arguments = ShareModelTestUtility.cameraEffectArguments
    let data = NSKeyedArchiver.archivedData(withRootObject: arguments)

    let unarchivedArguments = try NSKeyedUnarchiver.unarchivedObject(ofClass: CameraEffectArguments.self, from: data)
    XCTAssertEqual(unarchivedArguments, arguments)
  }

  func testTypes() {
    let arguments = CameraEffectArguments()

    // Supported types
    arguments.set("1234", forKey: "string")
    XCTAssertEqual(arguments.string(forKey: "string"), "1234")
    arguments.set(["a", "b", "c"], forKey: "string_array")
    XCTAssertEqual(arguments.array(forKey: "string_array"), ["a", "b", "c"])
    arguments.set([], forKey: "empty_array")
    XCTAssertEqual(arguments.array(forKey: "empty_array"), [])
    assertThrowsSpecificNamed(NSExceptionName.invalidArgumentException) {
      arguments.setNilValueForKey("nil_string")
    }
    XCTAssertNil(arguments.string(forKey: "nil_string"))
    assertThrowsSpecificNamed(NSExceptionName.invalidArgumentException) {
      arguments.setNilValueForKey("nil_array")
    }
    XCTAssertNil(arguments.array(forKey: "nil_array"))
  }
}
