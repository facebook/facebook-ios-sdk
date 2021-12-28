/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestLoginButtonDelegate: NSObject, LoginButtonDelegate {
  var didLoggedOut = false
  var willLogin = false
  var capturedResult: LoginManagerLoginResult?
  var capturedError: Error?

  var shouldLogin = true

  func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
    capturedResult = result
    capturedError = error
  }

  func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
    didLoggedOut = true
  }

  func loginButtonWillLogin(_ loginButton: FBLoginButton) -> Bool {
    willLogin = true
    return shouldLogin
  }
}
