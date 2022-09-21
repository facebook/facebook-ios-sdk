/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import MetaLogin
import XCTest

final class PermissionTests: XCTestCase {
  func testInvalidPermissions() {
    XCTAssertNil(Permission(rawValue: ""), .emptyRawValue)

    let invalidRawValues = [
      "a b",
      "a\nb",
      "a\tb",
      "a-b",
      "a+b",
      "A",
      "à",
    ]

    invalidRawValues.forEach { rawValue in
      XCTAssertNil(Permission(rawValue: rawValue), .disallowedCharacters)
    }
  }

  func testValidPermissions() {
    let permissions: [(Permission, String)] = [
      (.userAvatar, "user_avatar"),
    ]

    permissions.forEach { permission, rawValue in
      XCTAssertEqual(Permission(rawValue: rawValue), permission, .validRawValue)
      XCTAssertEqual(permission.rawValue, rawValue, .rawValue(rawValue, for: permission))
    }
  }

  func testCustomPermission() throws {
    let rawValue = "custom_permission"
    let permission = try XCTUnwrap(Permission(rawValue: rawValue), .validRawValue)
    XCTAssertEqual(permission.rawValue, rawValue, .validRawValue)
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static let emptyRawValue = "An empty string cannot be used to create a permission"
  static let disallowedCharacters = "A raw value with disallowed characters cannot be used to create a permission"
  static let validRawValue = "A valid raw value can be used to create a permission"

  static func rawValue(_ rawValue: String, for permission: Permission) -> String {
    "The raw value for the \(permission) permission is '\(permission.rawValue)', not '\(rawValue)'"
  }
}
