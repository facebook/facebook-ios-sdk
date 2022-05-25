/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

/// Login Result Block
public typealias LoginResultBlock = (LoginResult) -> Void

/// Describes the result of a login attempt.
@frozen
public enum LoginResult {
  /// User succesfully logged in. Contains granted, declined permissions and access token.
  case success(granted: Set<Permission>, declined: Set<Permission>, token: AccessToken?)
  /// Login attempt was cancelled by the user.
  case cancelled
  /// Login attempt failed.
  case failed(Error)

  init(result: LoginManagerLoginResult?, error: Error?) {
    guard let result = result, error == nil else {
      self = .failed(error ?? LoginError(.unknown))
      return
    }

    guard !result.isCancelled else {
      self = .cancelled
      return
    }

    let granted = Set(result.grantedPermissions.map(Permission.init(stringLiteral:)))
    let declined = Set(result.declinedPermissions.map(Permission.init(stringLiteral:)))
    self = .success(granted: granted, declined: declined, token: result.token)
  }
}

#endif
