/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit

@objcMembers
class TestLoginCompleter: NSObject, LoginCompleting {

  var capturedCompletionHandler: LoginCompletionParametersBlock?
  var capturedNonce: String?

  func completeLogin(handler: @escaping LoginCompletionParametersBlock) {
    capturedCompletionHandler = handler
  }

  func completeLogin(handler: @escaping LoginCompletionParametersBlock, nonce: String?) {
    capturedCompletionHandler = handler
    capturedNonce = nonce
  }
}
