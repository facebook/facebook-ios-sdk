/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices

struct DefaultASWebAuthenticationSessionFactory: ASWebAuthenticationSessionFactory {
  func makeSession(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
  ) -> ASWebAuthenticationSession {
    ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackURLScheme,
      completionHandler: completionHandler
    )
  }
}
