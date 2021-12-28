/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class ShareCameraEffectContentTests: XCTestCase {
  override func setUp() {
    super.setUp()
    _ = ShareCameraEffectContent()
  }

  func testDefaultClassDependencies() {
    XCTAssertTrue(
      ShareCameraEffectContent.internalUtility === InternalUtility.shared,
      "The ShareCameraEffectContent class should use the shared internal utility as a dependency by default"
    )
  }
}
