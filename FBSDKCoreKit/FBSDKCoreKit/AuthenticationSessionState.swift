/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Specifies state of FBSDKAuthenticationSession
enum AuthenticationSessionState {
  /// There is no active authentication session
  case none
  /// The authentication session has started
  case started
  /// System dialog ("app wants to use facebook.com  to sign in")  to access facebook.com was presented to the user
  case showAlert
  /// Web browser with log in to authentication was presented to the user
  case showWebBrowser
  /// Authentication session was canceled by system. It happens when app goes to background while alert requesting access to facebook.com is presented
  case canceledBySystem
}
