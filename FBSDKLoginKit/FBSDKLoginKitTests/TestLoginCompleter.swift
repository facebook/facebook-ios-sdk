/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit
import Foundation

@objcMembers
final class TestLoginCompleter: NSObject, LoginCompleting {

  var capturedCompletionHandler: LoginCompletionParametersBlock?
  var capturedNonce: String?
  var capturedCodeVerifier: String?

  func completeLogin(handler: @escaping LoginCompletionParametersBlock) {
    capturedCompletionHandler = handler
  }

  func completeLogin(handler: @escaping LoginCompletionParametersBlock, nonce: String?, codeVerifier: String?) {
    capturedCompletionHandler = handler
    capturedNonce = nonce
    capturedCodeVerifier = codeVerifier
  }
}
