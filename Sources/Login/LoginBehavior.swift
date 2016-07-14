// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

import FBSDKLoginKit

/**
 Indicates how Facebook Login should be attempted.

 Facebook Login authorizes the application to act on behalf of the user, using the user's Facebook account.
 Usually a Facebook Login will rely on an account maintained outside of the application,
 by the native Facebook application, the browser, or perhaps the device itself.
 This avoids the need for a user to enter their username and password directly,
 and provides the most secure and lowest friction way for a user to authorize the application to interact with Facebook.

 This enum specifies which log-in methods may be used.
 The SDK will determine the best behavior based on the current device (such as OS version).
 */
public enum LoginBehavior {
  /**
   This is the default behavior, and indicates logging in through the native Facebook app may be used.
   The SDK may still use Safari.app or `SFSafariViewController` instead.
   */
  case Native
  /**
   Attempts log in through the Safari.app or `SFSafariViewController`, if available.
   */
  case Browser
  /**
   Attempts log in through the Facebook account currently signed in through the the device Settings.

   - note: If the account is not available to the app (either not configured by user or
   as determined by the SDK) this behavior falls back to `.Native`.
   */
  case SystemAccount
  /**
   Attempts log in through a modal `WebView` pop up.

   - note: This behavior is only available to certain types of apps.
   Please check the Facebook Platform Policy to verify your app meets the restrictions.
   */
  case Web
}

extension LoginBehavior {
  var sdkBehavior: FBSDKLoginBehavior {
    switch self {
    case .Native: return .Native
    case .Browser: return .Browser
    case .SystemAccount: return .SystemAccount
    case .Web: return .Web
    }
  }
}
