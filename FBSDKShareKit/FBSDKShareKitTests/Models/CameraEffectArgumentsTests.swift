/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class CameraEffectArgumentsTests: XCTestCase {

  func testCoding() throws {
    let arguments = ShareModelTestUtility.cameraEffectArguments
    let data = NSKeyedArchiver.archivedData(withRootObject: arguments)

    let unarchivedArguments = try XCTUnwrap(
      NSKeyedUnarchiver.unarchivedObject(ofClass: CameraEffectArguments.self, from: data)
    )

    let arguments1 = arguments.allArguments()
    let arguments2 = unarchivedArguments.allArguments()

    guard Set(arguments1.keys) == Set(arguments2.keys) else {
      return XCTFail("Coding failed")
    }

    for (key, value) in arguments1 {
      if let string1 = value as? String,
         let string2 = arguments2[key] as? String {
        XCTAssertEqual(string1, string2, "Unequal arguments for key: \(key)")
      } else if let array1 = value as? [String],
                let array2 = arguments2[key] as? [String] {
        XCTAssertEqual(array1, array2, "Unequal arguments for key: \(key)")
      } else {
        XCTFail("Invalid argument type: \(type(of: value))")
      }
    }
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
