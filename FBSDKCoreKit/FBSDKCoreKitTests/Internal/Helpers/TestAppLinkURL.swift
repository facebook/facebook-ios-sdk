/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestAppLinkURL: AppLinkURLProtocol {
  var appLinkExtras: [String: Any]?

  init(appLinkExtras: [String: Any] = [:]) {
    self.appLinkExtras = appLinkExtras
  }
}
