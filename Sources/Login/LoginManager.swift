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
import UIKit
import FBSDKLoginKit
@testable import FacebookCore

/**
 This class provides methods for logging the user in and out.
 It works directly with `AccessToken.current` and
 sets the "current" token upon successful authorizations (or sets `nil` in case of `logOut`).

 You should check `AccessToken.current` before calling `logIn()` to see if there is
 a cached token available (typically in your `viewDidLoad`).

 If you are managing your own token instances outside of `AccessToken.current`, you will need to set
 `current` before calling `logIn()` to authorize further permissions on your tokens.
 */
public class LoginManager {
  private let sdkManager = FBSDKLoginManager()

  /// The login behavior that is going to be used. Default: `.Native`.
  public var loginBehavior: LoginBehavior {
    didSet {
      sdkManager.loginBehavior = loginBehavior.sdkBehavior
    }
  }

  /// The default audience. Default: `.Friends`.
  public var defaultAudience: LoginDefaultAudience {
    didSet {
      sdkManager.defaultAudience = defaultAudience.sdkAudience
    }
  }

  /**
   Initialize an instance of `LoginManager.`

   - parameter loginBehavior:   Optional login behavior to use. Default: `.Native`.
   - parameter defaultAudience: Optional default audience to use. Default: `.Friends`.
   */
  public init(loginBehavior: LoginBehavior = .Native,
              defaultAudience: LoginDefaultAudience = .Friends) {
    self.loginBehavior = loginBehavior
    self.defaultAudience = defaultAudience
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for read permissions. You should only ask for permissions when they
   are needed and explain the value to the user. You can inspect the `declinedPermissions` in the result to also
   provide more information to the user if they decline permissions.

   This method will present UI the user. You typically should check if `AccessToken.current` already
   contains the permissions you need before asking to reduce unnecessary app switching.

   - parameter permissions:    Array of read permissions. Default: `[.PublicProfile]`
   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter completion:     Optional callback.
   */
  public func logIn(permissions: [ReadPermission] = [.PublicProfile],
                    viewController: UIViewController? = nil,
                    completion: ((LoginResult) -> Void)? = nil) {
    let sdkPermissions = permissions.map({ $0.permissionValue.name })
    sdkManager.logInWithReadPermissions(sdkPermissions,
                                        fromViewController: viewController,
                                        handler: LoginManager.sdkCompletionFor(completion))
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for publish permissions. You should only ask for permissions when they
   are needed and explain the value to the user. You can inspect the `declinedPermissions` in the result to also
   provide more information to the user if they decline permissions.

   This method will present UI the user. You typically should check if `AccessToken.current` already
   contains the permissions you need before asking to reduce unnecessary app switching.

   - parameter permissions:    Array of publish permissions. Default: `[.PublishActions]`
   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter completion:     Optional callback.
   */
  public func logIn(permissions: [PublishPermission] = [.PublishActions],
                    viewController: UIViewController? = nil,
                    completion: ((LoginResult) -> Void)? = nil) {
    let sdkPermissions = permissions.map({ $0.permissionValue.name })
    sdkManager.logInWithPublishPermissions(sdkPermissions,
                                           fromViewController: viewController,
                                           handler: LoginManager.sdkCompletionFor(completion))
  }

  /**
   Logs the user out.
   This calls `AccessToken.current = nil` and `Profile.current = nil`.
   */
  public func logOut() {
    AccessToken.current = nil
    UserProfile.current = nil
  }
}

private extension LoginManager {
  private class func sdkCompletionFor(completion: ((LoginResult) -> Void)?) -> FBSDKLoginManagerRequestTokenHandler? {
    guard let completion = completion else {
      return nil
    }
    return { (sdkResult: FBSDKLoginManagerLoginResult?, error: NSError?) -> Void in
      let result = LoginResult(sdkResult: sdkResult, error: error)
      completion(result)
    }
  }
}
