/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class WebViewFactoryTests: XCTestCase {

  let factory = WebViewFactory()
  let frame = CGRect(origin: .zero, size: .init(width: 5, height: 5))

  func testCreatingWebView() {
    guard let webView = factory.createWebView(withFrame: frame) as? WKWebView else {
      return XCTFail("Should create a webview of the expected concrete type")
    }

    XCTAssertEqual(
      webView.frame,
      frame,
      "Should create a webview with the given frame"
    )
  }
}
