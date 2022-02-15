/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class PermissionTests: XCTestCase {

  func testInvalidPermissions() {
    let rawPermissions = [
      "",
      "foo bar",
      "PUBLIC_PROFILE",
      "public profile",
      "public-profile",
      "123_abc",
    ]

    rawPermissions.forEach { rawPermission in
      let permission = FBPermission(string: rawPermission)
      XCTAssertNil(permission)
    }
  }

  func testValidPermissions() {
    let rawPermissions = [
      "email",
      "public_profile",
      "pages_manage_ads",
    ]

    rawPermissions.forEach { rawPermission in
      let permission = FBPermission(string: rawPermission)
      XCTAssertEqual(permission?.value, rawPermission)
    }
  }

  func testRawPermissionsFromPermissions() {
    let permissions = Set(
      [
        FBPermission(string: "email"),
        FBPermission(string: "public_profile"),
      ].compactMap { $0 }
    )
    let rawPermissions = FBPermission.rawPermissions(from: permissions)
    let expectedRawPermissions: Set = ["email", "public_profile"]
    XCTAssertEqual(rawPermissions, expectedRawPermissions)
  }

  func testPermissionsFromValidRawPermissions() {
    let rawPermissions: Set = ["email", "user_friends"]

    let permissions = FBPermission.permissions(fromRawPermissions: rawPermissions)
    let expectedPermissions = Set(
      [
        FBPermission(string: "email"),
        FBPermission(string: "user_friends"),
      ].compactMap { $0 }
    )
    XCTAssertEqual(permissions, expectedPermissions)
  }

  func testPermissionsFromInvalidRawPermissions() {
    let rawPermissions: Set = ["email", ""]

    let permissions = FBPermission.permissions(fromRawPermissions: rawPermissions)
    XCTAssertNil(permissions)
  }

  func testDescription() throws {
    let permission = try XCTUnwrap(FBPermission(string: "test_permission"))
    XCTAssertEqual(permission.description, permission.value, "A permission's description should be equal to its value")
  }

  func testEquality() throws {
    let permission = try XCTUnwrap(FBPermission(string: "test_permission"))
    XCTAssertEqual(permission, permission, "A permission should be equal to itself")

    let permission2 = try XCTUnwrap(FBPermission(string: "test_permission"))
    XCTAssertEqual(permission, permission2, "Permissions with equal string values should be equal")
  }

  func testInequality() throws {
    let permission = try XCTUnwrap(FBPermission(string: "test_permission"))
    let permission2 = try XCTUnwrap(FBPermission(string: "different_permission"))
    XCTAssertNotEqual(permission, permission2, "Permissions with unequal string values should be unequal")
  }
}
