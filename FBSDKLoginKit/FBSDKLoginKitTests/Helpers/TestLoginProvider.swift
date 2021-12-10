/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestLoginProvider: LoginProviding {
  var defaultAudience: DefaultAudience = .friends
  var capturedCompletion: LoginManagerLoginResultBlock?
  var capturedConfiguration: LoginConfiguration?
  var didLogout = false

  func logIn(
    from viewController: UIViewController?,
    configuration: LoginConfiguration,
    completion: @escaping LoginManagerLoginResultBlock
  ) {
    capturedConfiguration = configuration
    capturedCompletion = completion
  }

  func logOut() {
    didLogout = true
  }
}
