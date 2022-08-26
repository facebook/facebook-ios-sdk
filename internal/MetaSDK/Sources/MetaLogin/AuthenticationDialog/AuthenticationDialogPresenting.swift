/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum CompletionLoginResult {
  case cancel
  case success(URL)
  case failure(Error)
}

protocol AuthenticationDialogPresenting {
  typealias CompletionHandler = (CompletionLoginResult) -> Void

  func presentAuthenticationDialog(
    url: URL,
    callbackURLScheme: String,
    completion: @escaping CompletionHandler
  )
}
