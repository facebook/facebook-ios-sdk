/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

final class TestLoginCompleterFactory: LoginCompleterFactoryProtocol {

  let stubbedLoginCompleter: TestLoginCompleter
  var capturedURLParameters = [String: Any]()
  var capturedAppID: String?

  init(stubbedLoginCompleter: TestLoginCompleter = TestLoginCompleter()) {
    self.stubbedLoginCompleter = stubbedLoginCompleter
  }

  func createLoginCompleter(
    urlParameters parameters: [String: Any],
    appID: String
  ) -> _LoginCompleting {
    capturedURLParameters = parameters
    capturedAppID = appID

    return stubbedLoginCompleter
  }
}
