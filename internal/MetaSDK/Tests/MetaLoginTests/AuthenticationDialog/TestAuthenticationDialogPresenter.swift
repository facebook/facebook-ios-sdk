/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

final class TestAuthenticationDialogPresenter: AuthenticationDialogPresenting {
  var wasPresentAuthenticationDialogCalled = false
  var capturedURL: URL?
  var capturedCallbackURLScheme: String?
  var capturedCompletion: AuthenticationDialogPresenting.CompletionHandler?

  func presentAuthenticationDialog(
    url: URL,
    callbackURLScheme: String,
    completion: @escaping AuthenticationDialogPresenting.CompletionHandler
  ) {
    wasPresentAuthenticationDialogCalled = true
    capturedURL = url
    capturedCallbackURLScheme = callbackURLScheme
    capturedCompletion = completion
  }
}
