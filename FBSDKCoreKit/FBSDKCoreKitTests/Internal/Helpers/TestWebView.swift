/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestWebView: UIView, WebView {
  weak var navigationDelegate: WKNavigationDelegate?
  var capturedRequest: URLRequest?
  var stopLoadingCallCount = 0

  func load(_ request: URLRequest) -> WKNavigation? {
    capturedRequest = request
    return nil
  }

  func stopLoading() {
    stopLoadingCallCount += 1
  }
}
