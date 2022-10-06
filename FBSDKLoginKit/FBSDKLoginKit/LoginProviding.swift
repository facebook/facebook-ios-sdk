/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import UIKit

protocol LoginProviding {

  var defaultAudience: DefaultAudience { get set }

  func logIn(
    viewController: UIViewController?,
    configuration: LoginConfiguration?,
    completion: @escaping LoginResultBlock
  )

  func logIn(
    permissions: [String],
    from viewController: UIViewController?,
    handler: LoginManagerLoginResultBlock?
  )

  func logOut()
}

#endif
