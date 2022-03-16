/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import UIKit

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKLoginProviding)
public protocol _LoginProviding {
  var defaultAudience: DefaultAudience { get set }

  @objc(logInFromViewController:configuration:completion:)
  func logIn(
    from viewController: UIViewController?,
    configuration: LoginConfiguration,
    completion: @escaping LoginManagerLoginResultBlock
  )

  @objc(logInWithPermissions:fromViewController:handler:)
  func logIn(
    permissions: [String],
    from viewController: UIViewController?,
    handler: @escaping LoginManagerLoginResultBlock
  )

  func logOut()
}

#endif
