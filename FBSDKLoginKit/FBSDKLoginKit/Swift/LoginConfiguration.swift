/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

public extension LoginConfiguration {

  /**
   Attempts to allocate and initialize a new configuration with the expected parameters.

   - parameter permissions: The requested permissions for the login attempt.
   Defaults to an empty `Permission` array.
   - parameter tracking: The tracking preference to use for a login attempt. Defaults to `.enabled`
   - parameter nonce: An optional nonce to use for the login attempt.
    A valid nonce must be an alphanumeric string without whitespace.
    Creation of the configuration will fail if the nonce is invalid. Defaults to a `UUID` string.
   - parameter messengerPageId: An optional page id to use for a login attempt. Defaults to `nil`
   - parameter authType: An optional auth type to use for a login attempt. Defaults to `.rerequest`
   */
  convenience init?(
    permissions: Set<Permission> = [],
    tracking: LoginTracking = .enabled,
    nonce: String = UUID().uuidString,
    messengerPageId: String? = nil,
    authType: LoginAuthType? = .rerequest
  ) {
    self.init(
      __permissions: permissions.map { $0.name },
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: authType
    )
  }
}
