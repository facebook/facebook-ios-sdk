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

class UIUtilityTests: XCTestCase {

  let edgeInset: CGFloat = 10
  var insets: UIEdgeInsets! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    insets = UIEdgeInsets(
      top: edgeInset,
      left: edgeInset,
      bottom: edgeInset,
      right: edgeInset
    )
  }

  func testEdgeInsetsSizeForZeroStartingSize() {
    let size = FBSDKEdgeInsetsInsetSize(.zero, insets)
    XCTAssertEqual(
      size,
      CGSize(width: -20, height: -20),
      "Should not return a size smaller than the original size of zero but it will"
    )
  }

  func testEdgeInsetsSizeForNonZero() {
    let side: CGFloat = 56
    let size = CGSize(width: side, height: side)
    let insetSize = FBSDKEdgeInsetsInsetSize(size, insets)

    XCTAssertEqual(
      insetSize,
      CGSize(width: side - 2 * edgeInset, height: side - 2 * edgeInset),
      "Should return a new size that equals the old size excluding the insets"
    )
  }

  func testEdgeOutsetsSizeForZero() {
    let size = FBSDKEdgeInsetsOutsetSize(.zero, insets)
    XCTAssertEqual(
      size,
      CGSize(width: 2 * edgeInset, height: 2 * edgeInset),
      "Should return a new size outset from the old size by the edge insets"
    )
  }

  func testEdgeOutsetsSizeForNonZero() {
    let side: CGFloat = 56
    let size = CGSize(width: side, height: side)
    let insetSize = FBSDKEdgeInsetsOutsetSize(size, insets)

    XCTAssertEqual(
      insetSize,
      CGSize(width: side + 2 * edgeInset, height: side + 2 * edgeInset),
      "Should return a new size that equals the old size plus the insets"
    )
  }

  func testTextSizeWithWordWrapping() {
    let size = FBSDKTextSize(
      "A very long string that will need to wrap",
      .boldSystemFont(ofSize: 11),
      CGSize(width: 36, height: 36),
      .byWordWrapping
    )
    XCTAssertEqual(
      size,
      CGSize(width: 36, height: 106),
      "Should increase the text height to account for word wrapping"
    )
  }

  func testTextSizeWithoutText() {
    XCTAssertEqual(
      FBSDKTextSize(
        nil,
        .boldSystemFont(ofSize: 11),
        CGSize(width: 36, height: 36),
        .byTruncatingTail
      ),
      .zero,
      "Should return a size of zero if there is no text"
    )
  }

  func testTextSizeWithTruncation() {
    let size = FBSDKTextSize(
      "A very long string that will need to truncate",
      .boldSystemFont(ofSize: 11),
      CGSize(width: 36, height: 36),
      .byTruncatingTail
    )
    XCTAssertEqual(
      size.width,
      33,
      """
      Sometimes truncated text will allocate less width for a truncated word
      than for the ellipse that replaces it.
      """
    )
    XCTAssertEqual(
      size.height,
      8,
      "Should not increase the height to fit truncated text"
    )
  }
}
