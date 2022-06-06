/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKLoginCompleting)
public protocol _LoginCompleting {

  /**
   Invoke handler with the login parameters derived from the authentication result.
   See the implementing class's documentation for whether it completes synchronously or asynchronously.
   */
  @objc(completeLoginWithHandler:)
  func completeLogin(handler: @escaping LoginCompletionParametersBlock)

  /**
   Invoke handler with the login parameters derived from the authentication result.
   See the implementing class's documentation for whether it completes synchronously or asynchronously.
   */
  @objc(completeLoginWithNonce:codeVerifier:handler:)
  func completeLogin(
    nonce: String?,
    codeVerifier: String?,
    handler: @escaping LoginCompletionParametersBlock
  )
}

#endif
