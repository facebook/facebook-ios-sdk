/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import WebKit

class TestWebKitNavigationAction: WKNavigationAction {
  let stubbedRequest: URLRequest
  let stubbedNavigationType: WKNavigationType

  init(
    stubbedRequest: URLRequest,
    navigationType: WKNavigationType = .other
  ) {
    self.stubbedRequest = stubbedRequest
    stubbedNavigationType = navigationType

    super.init()
  }

  override var request: URLRequest {
    stubbedRequest
  }

  override var navigationType: WKNavigationType {
    stubbedNavigationType
  }
}
