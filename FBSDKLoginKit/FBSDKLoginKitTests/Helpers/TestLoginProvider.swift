/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestLoginProvider: _LoginProviding {

  var defaultAudience: DefaultAudience = .friends
  var capturedCompletion: LoginManagerLoginResultBlock?
  var capturedConfiguration: LoginConfiguration?
  var capturedPermissions: [String]?
  var didLogout = false

  func __logIn( // swiftlint:disable:this identifier_name
    from viewController: UIViewController?,
    configuration: LoginConfiguration,
    completion: @escaping LoginManagerLoginResultBlock
  ) {
    capturedConfiguration = configuration
    capturedCompletion = completion
  }

  func logIn(
    permissions: [String],
    from viewController: UIViewController?,
    handler: @escaping LoginManagerLoginResultBlock
  ) {
    capturedPermissions = permissions
    capturedCompletion = handler
  }

  func logOut() {
    didLogout = true
  }
}
