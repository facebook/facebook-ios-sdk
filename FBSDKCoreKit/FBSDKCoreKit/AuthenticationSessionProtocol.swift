/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices

typealias AuthenticationCompletionHandler = (URL?, Error?) -> Void

protocol AuthenticationSessionProtocol {
  init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping AuthenticationCompletionHandler
  )

  func start() -> Bool
  func cancel()

  @available(iOS 13.0, *)
  var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? { get set }
}

extension ASWebAuthenticationSession: AuthenticationSessionProtocol {}
