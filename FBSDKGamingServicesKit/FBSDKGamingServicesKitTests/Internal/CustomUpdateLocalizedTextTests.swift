/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import XCTest

final class CustomUpdateLocalizedTextTests: XCTestCase {
  let fakeLocalization = ["es_pa": "spanish"]

  func testIntilization() {
    let text = CustomUpdateLocalizedText(defaultString: "test", localizations: fakeLocalization)

    XCTAssertNotNil(text)
    XCTAssertEqual(text?.localizations, fakeLocalization)
  }

  func testIntilizationWithEmptyString() {
    XCTAssertNil(CustomUpdateLocalizedText(defaultString: "", localizations: [:]))
  }
}
