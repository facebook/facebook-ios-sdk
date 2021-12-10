/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class ModelUtilityTests: XCTestCase {

  let normalized = "Foo Bar Baz"

  enum UnicodeWhitespace: String, CaseIterable {
    case lineFeed = "\u{000A}"
    case carriageReturn = "\u{000D}"
    case horizontalTab = "\u{0009}"
    case verticalTab = "\u{000B}"
    case formFeed = "\u{000C}"
    // Uncomment when we conver the utility to Swift
    //    case null = "\u{0000}"
  }

  func testNormalizingEmptyText() {
    XCTAssertEqual(
      ModelUtility.normalizedText(""),
      "",
      "Should not return an altered empty string"
    )
  }

  func testNormalizingWithExcessWhitespace() {
    XCTAssertEqual(
      ModelUtility.normalizedText("  Foo  Bar     Baz "),
      normalized,
      "Should replace multiple whitespace characters with single spaces"
    )
  }

  func testNormalizingUnicodeTabWhitespace() {
    let text = ["\t", "Foo", "Bar", "Baz"]
      .joined(separator: UnicodeWhitespace.horizontalTab.rawValue)

    XCTAssertEqual(
      ModelUtility.normalizedText(text),
      normalized,
      "Should replace horizontal tab characters with single spaces"
    )
  }

  func testNormalizingNonTabUnicodeWhitespace() {
    UnicodeWhitespace.allCases
      .forEach {
        let text = [$0.rawValue, "Foo", "Bar", "Baz"]
          .joined(separator: $0.rawValue)

        XCTAssertEqual(
          ModelUtility.normalizedText(text),
          normalized,
          "Should replace non-tab whitespace characters"
        )
      }
  }
}
