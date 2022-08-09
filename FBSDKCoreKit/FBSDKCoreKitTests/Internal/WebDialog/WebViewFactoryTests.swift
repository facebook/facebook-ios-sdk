/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class WebViewFactoryTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var factory: _WebViewFactory!
  // swiftlint:enable implicitly_unwrapped_optional
  let frame = CGRect(origin: .zero, size: .init(width: 5, height: 5))

  override func setUp() {
    super.setUp()
    factory = _WebViewFactory()
  }

  override func tearDown() {
    factory = nil

    super.tearDown()
  }

  func testCreatingWebView() {
    guard let webView = factory.createWebView(frame: frame) as? WKWebView else {
      return XCTFail("Should create a webview of the expected concrete type")
    }

    XCTAssertEqual(
      webView.frame,
      frame,
      "Should create a webview with the given frame"
    )
  }
}
