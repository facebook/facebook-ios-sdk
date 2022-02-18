/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import TestTools
import XCTest

final class ShareCameraEffectContentTests: XCTestCase {
  // swiftlint:disable:next implicitly_unwrapped_optional
  var content: ShareCameraEffectContent!

  override func setUp() {
    super.setUp()
    content = ShareCameraEffectContent()
  }

  override func tearDown() {
    content = nil
    super.tearDown()
  }

  func testDefaultClassDependencies() {
    XCTAssertTrue(
      ShareCameraEffectContent.internalUtility === InternalUtility.shared,
      "The ShareCameraEffectContent class should use the shared internal utility as a dependency by default"
    )
  }

  func testInvalidEffectIDs() throws {
    try ["a", "1a", "12345x67890"]
      .forEach { effectID in
        content.effectID = effectID
        XCTAssertThrowsError(
          try content.validate(options: []),
          "An effect ID (\(effectID)) must only contain digits"
        )
      }
  }

  func testValidEffectIDs() throws {
    try ["", "1", "123", "1234567890"]
      .forEach { effectID in
        content.effectID = effectID
        XCTAssertNoThrow(
          try content.validate(options: []),
          "An effect ID (\(effectID)) must only contain digits"
        )
      }
  }
}
