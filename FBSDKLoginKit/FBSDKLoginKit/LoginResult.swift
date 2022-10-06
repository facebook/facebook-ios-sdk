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
    guard
      let result = result,
      error == nil
    else {
      self = .failed(error ?? LoginError(LoginError.unknown))
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

  var loginManagerResult: LoginManagerLoginResult? {
    LoginManagerLoginResult(
      token: accessToken,
      authenticationToken: nil,
      isCancelled: isCancelled,
      grantedPermissions: grantedPermissions,
      declinedPermissions: declinedPermissions
    )
  }

  private var accessToken: AccessToken? {
    switch self {
    case let .success(granted: _, declined: _, token: accessToken):
      return accessToken
    default:
      return nil
    }
  }

  private var isCancelled: Bool {
    switch self {
    case .cancelled: return true
    default: return false
    }
  }

  private var grantedPermissions: Set<String> {
    switch self {
    case let .success(granted: granted, declined: _, token: _):
      return Set(granted.map(\.name))
    default:
      return []
    }
  }

  private var declinedPermissions: Set<String> {
    switch self {
    case let .success(granted: _, declined: declined, token: _):
      return Set(declined.map(\.name))
    default:
      return []
    }
  }

  var error: Error? {
    switch self {
    case let .failed(error): return error
    default: return nil
    }
  }
}

#endif
