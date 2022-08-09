/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

struct UnknownAuthenticationSessionError: Error {}

struct WebAuthenticationSessionFactory: WebAuthenticationSessionCreating {
  func createWebAuthenticationSession(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping AuthWebViewCompletion
  ) -> WebAuthenticationSession {
    let handler: (URL?, Error?) -> Void = { potentialURL, potentialError in
      if let error = potentialError {
        completionHandler(.failure(error))
      }
      if let url = potentialURL {
        completionHandler(.success(url))
      }
      completionHandler(.failure(UnknownAuthenticationSessionError()))
    }
    return ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: handler)
  }
}
