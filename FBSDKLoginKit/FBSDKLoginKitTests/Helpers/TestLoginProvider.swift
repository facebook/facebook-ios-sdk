/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

final class TestLoginProvider: LoginProviding {

  var defaultAudience: DefaultAudience = .friends
  var capturedCompletion: LoginResultBlock?
  var capturedLegacyCompletion: LoginManagerLoginResultBlock?
  var capturedConfiguration: LoginConfiguration?
  var capturedPermissions: [String]?
  var didLogout = false

  func logIn(
    viewController: UIViewController?,
    configuration: LoginConfiguration?,
    completion: @escaping LoginResultBlock
  ) {
    capturedConfiguration = configuration
    capturedCompletion = completion
  }

  func logIn(
    permissions: [String],
    from viewController: UIViewController?,
    handler: LoginManagerLoginResultBlock?
  ) {
    capturedPermissions = permissions
    capturedLegacyCompletion = handler
  }

  func logOut() {
    didLogout = true
  }
}
