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

import FBSDKCoreKit

import UIKit

/// Login Result Block
@available(tvOS, unavailable)
public typealias LoginResultBlock = (LoginResult) -> Void

/**
 Describes the result of a login attempt.
 */
@available(tvOS, unavailable)
public enum LoginResult {
  /// User succesfully logged in. Contains granted, declined permissions and access token.
  case success(granted: Set<Permission>, declined: Set<Permission>, token: FBSDKCoreKit.AccessToken)
  /// Login attempt was cancelled by the user.
  case cancelled
  /// Login attempt failed.
  case failed(Error)

  internal init(result: LoginManagerLoginResult?, error: Error?) {
    guard let result = result, error == nil else {
      self = .failed(error ?? LoginError(.unknown))
      return
    }

    guard !result.isCancelled, let token = result.token else {
      self = .cancelled
      return
    }

    let granted: Set<Permission> = Set(result.grantedPermissions.map { Permission(stringLiteral: $0) })
    let declined: Set<Permission> = Set(result.declinedPermissions.map { Permission(stringLiteral: $0) })
    self = .success(granted: granted, declined: declined, token: token)
  }
}

/**
 This class provides methods for logging the user in and out.
 It works directly with `AccessToken.current` and
 sets the "current" token upon successful authorizations (or sets `nil` in case of `logOut`).

 You should check `AccessToken.current` before calling `logIn()` to see if there is
 a cached token available (typically in your `viewDidLoad`).

 If you are managing your own token instances outside of `AccessToken.current`, you will need to set
 `current` before calling `logIn()` to authorize further permissions on your tokens.
 */
@available(tvOS, unavailable)
public extension LoginManager {
  /**
   Initialize an instance of `LoginManager.`

   - parameter defaultAudience: Optional default audience to use. Default: `.Friends`.
   */
  convenience init(defaultAudience: DefaultAudience = .friends) {
    self.init()
    self.defaultAudience = defaultAudience
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for read permissions. You should only ask for permissions when they
   are needed and explain the value to the user. You can inspect the `declinedPermissions` in the result to also
   provide more information to the user if they decline permissions.

   This method will present UI the user. You typically should check if `AccessToken.current` already
   contains the permissions you need before asking to reduce unnecessary app switching.

   - parameter permissions: Array of read permissions. Default: `[.PublicProfile]`
   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter completion: Optional callback.
   */
  func logIn(permissions: [Permission] = [.publicProfile],
             viewController: UIViewController? = nil,
             completion: LoginResultBlock? = nil) {
    self.logIn(permissions: permissions.map { $0.name }, from: viewController, handler: sdkCompletion(completion))
  }

  private func sdkCompletion(_ completion: LoginResultBlock?) -> LoginManagerLoginResultBlock? {
    guard let completion = completion else {
      return nil
    }
    return { (result: LoginManagerLoginResult?, error: Error?) in
      let result = LoginResult(result: result, error: error)
      completion(result)
    }
  }
}
