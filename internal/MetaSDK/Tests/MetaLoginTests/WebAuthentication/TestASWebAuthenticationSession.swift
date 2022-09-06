/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices

final class TestASWebAuthenticationSession: ASWebAuthenticationSession {

  static let defaultURL = URL(string: "https://facebook.com/auth")!
  static let defaultCallbackURLScheme = "auth"

  convenience init() {
    self.init(
      url: Self.defaultURL,
      callbackURLScheme: Self.defaultCallbackURLScheme
    ) { _, _ in }
  }
}
