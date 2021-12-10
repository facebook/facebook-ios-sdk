/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestWebViewFactory: WebViewProviding {
  var capturedFrame: CGRect?
  let webView = TestWebView()

  func createWebView(withFrame frame: CGRect) -> WebView {
    capturedFrame = frame
    return webView
  }
}
