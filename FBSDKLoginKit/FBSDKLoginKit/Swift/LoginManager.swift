/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

import UIKit

/// Login Result Block
public typealias LoginResultBlock = (LoginResult) -> Void

/// Describes the result of a login attempt.
@frozen
public enum LoginResult {
  /// User succesfully logged in. Contains granted, declined permissions and access token.
  case success(granted: Set<Permission>, declined: Set<Permission>, token: FBSDKCoreKit.AccessToken?)
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

    let granted: Set<Permission> = Set(result.grantedPermissions.map { Permission(stringLiteral: $0) })
    let declined: Set<Permission> = Set(result.declinedPermissions.map { Permission(stringLiteral: $0) })
    self = .success(granted: granted, declined: declined, token: result.token)
  }
}

/**
 This class provides methods for logging the user in and out.
 It works directly with `AccessToken.current` and
 sets the "current" token upon successful authorizations (or sets `nil` in case of `logOut`).

 You should check `AccessToken.current` before calling `logIn()` to see if there is
 a cached token available (typically in your `viewDidLoad`).

 If you are managing your own token instances outside of `AccessToken.current`, you will need to set
 `current` before calling `logIn()` to authorize further permissions on your tokens.
 */
public extension LoginManager {
  /**
   Initialize an instance of `LoginManager.`

   - parameter defaultAudience: Optional default audience to use. Default: `.Friends`.
   */
  convenience init(defaultAudience: DefaultAudience = .friends) {
    self.init()
    self.defaultAudience = defaultAudience
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for permissions. You should only ask for permissions when they
   are needed and the value should be explained to the user. You can inspect the result's `declinedPermissions` to also
   provide more information to the user if they decline permissions.

   This method will present a UI to the user. To reduce unnecessary app switching, you should typically check if
   `AccessToken.current` already contains the permissions you need. If it does, you probably
   do not need to call this method.

   You can only perform one login call at a time. Calling a login method before the completion handler is called
   on a previous login will result in an error.

   - parameter permissions: Array of read permissions. Default: `[.PublicProfile]`
   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter completion: Optional callback.
   */
  func logIn(
    permissions: [Permission] = [.publicProfile],
    viewController: UIViewController? = nil,
    completion: LoginResultBlock? = nil
  ) {
    logIn(permissions: permissions.map { $0.name }, from: viewController, handler: sdkCompletion(completion))
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for permissions. You should only ask for permissions when they
   are needed and the value should be explained to the user. You can inspect the result's `declinedPermissions` to also
   provide more information to the user if they decline permissions.

   This method will present a UI to the user. To reduce unnecessary app switching, you should typically check if
   `AccessToken.current` already contains the permissions you need. If it does, you probably
   do not need to call this method.

   You can only perform one login call at a time. Calling a login method before the completion handler is called
   on a previous login will result in an error.

   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter configuration the login configuration to use.
   - parameter completion: Optional callback.
   */
  func logIn(
    viewController: UIViewController? = nil,
    configuration: LoginConfiguration,
    completion: @escaping LoginResultBlock
  ) {
    let legacyCompletion = { (result: LoginManagerLoginResult?, error: Error?) in
      let result = LoginResult(result: result, error: error)
      completion(result)
    }
    __logIn(from: viewController, configuration: configuration, completion: legacyCompletion)
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for permissions. You should only ask for permissions when they
   are needed and the value should be explained to the user. You can inspect the result's `declinedPermissions` to also
   provide more information to the user if they decline permissions.

   This method will present a UI to the user. To reduce unnecessary app switching, you should typically check if
   `AccessToken.current` already contains the permissions you need. If it does, you probably
   do not need to call this method.

   You can only perform one login call at a time. Calling a login method before the completion handler is called
   on a previous login will result in an error.

   - parameter configuration the login configuration to use.
   - parameter completion: Optional callback.
   */
  func logIn(
    configuration: LoginConfiguration,
    completion: @escaping LoginResultBlock
  ) {
    let legacyCompletion = { (result: LoginManagerLoginResult?, error: Error?) in
      let result = LoginResult(result: result, error: error)
      completion(result)
    }
    __logIn(from: nil, configuration: configuration, completion: legacyCompletion)
  }

  private func sdkCompletion(_ completion: LoginResultBlock?) -> LoginManagerLoginResultBlock? {
    guard let original = completion else {
      return nil
    }
    return convertedResultHandler(original)
  }

  private func convertedResultHandler(_ original: @escaping LoginResultBlock) -> LoginManagerLoginResultBlock {
    { (result: LoginManagerLoginResult?, error: Error?) in
      let result = LoginResult(result: result, error: error)
      original(result)
    }
  }
}

#endif
