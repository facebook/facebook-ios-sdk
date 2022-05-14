/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAuthenticationTokenFactory: NSObject, _AuthenticationTokenCreating {
  var capturedTokenString: String?
  var capturedNonce: String?
  var capturedCompletion: AuthenticationTokenBlock?

  func createToken(
    tokenString: String,
    nonce: String,
    graphDomain: String,
    completion: @escaping AuthenticationTokenBlock
  ) {
    capturedTokenString = tokenString
    capturedNonce = nonce
    capturedCompletion = completion
  }
}
