// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
