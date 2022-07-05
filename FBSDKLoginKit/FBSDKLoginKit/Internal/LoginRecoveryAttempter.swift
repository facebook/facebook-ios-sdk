/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

#if !os(tvOS)

final class LoginRecoveryAttempter: NSObject, ErrorRecoveryAttempting {

  func attemptRecovery(fromError error: Error, completionHandler: @escaping (Bool) -> Void) {
    guard
      let dependencies = try? Self.getDependencies(),
      let currentPermissions = dependencies.accessTokenProvider.current?.permissions.map(\.name),
      !currentPermissions.isEmpty
    else {
      completionHandler(false)
      return
    }

    dependencies.loginProvider.logIn(permissions: currentPermissions, from: nil) { result, error in
      guard
        error == nil,
        let result = result
      else {
        completionHandler(false)
        return
      }

      // we can only consider a recovery successful if there are no declines
      // (note this could still set an updated currentAccessToken).
      completionHandler(!result.isCancelled && result.declinedPermissions.isEmpty)
    }
  }
}

extension LoginRecoveryAttempter: DependentAsType {
  struct TypeDependencies {
    var loginProvider: LoginProviding
    var accessTokenProvider: AccessTokenProviding.Type
  }

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    loginProvider: LoginManager(),
    accessTokenProvider: AccessToken.self
  )

  static var configuredDependencies: TypeDependencies?
}

#endif
