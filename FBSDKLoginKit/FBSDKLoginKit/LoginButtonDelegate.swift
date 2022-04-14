/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

#if !os(tvOS)

/**
 A delegate for `FBSDKLoginButton`
 */
@objc(FBSDKLoginButtonDelegate)
public protocol LoginButtonDelegate: NSObjectProtocol {

  /**
   Sent to the delegate when the button was used to login.
   @param loginButton The button being used to log in
   @param result The results of the login
   @param error The error (if any) from the login
   */
  @objc(loginButton:didCompleteWithResult:error:)
  func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?)

  /**
   Sent to the delegate when the button was used to logout.
   @param loginButton The button being used to log out.
   */
  @objc
  func loginButtonDidLogOut(_ loginButton: FBLoginButton)

  /**
   Sent to the delegate when the button is about to login.
   @param loginButton The button being used to log in
   @return `true` if the login should be allowed to proceed, `false` otherwise
   */
  @objc
  optional func loginButtonWillLogin(_ loginButton: FBLoginButton) -> Bool
}

#endif
