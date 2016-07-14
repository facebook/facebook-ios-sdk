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
@testable import FacebookCore
import FBSDKLoginKit

/**
 Describes the result of a login attempt.
 */
public enum LoginResult {
  /// User succesfully logged in. Contains granted, declined permissions and access token.
  case Success(grantedPermissions: Set<Permission>, declinedPermissions: Set<Permission>, token: AccessToken)
  /// Login attempt was cancelled by the user.
  case Cancelled
  /// Login attempt failed.
  case Failed(ErrorType)
}

extension LoginResult {
  internal init(sdkResult: FBSDKLoginManagerLoginResult?, error: NSError?) {
    if let error = error {
      self = .Failed(error)
      return
    }
    guard let sdkResult = sdkResult else {
      //FIXME: (nlutsenko) Use a good error type here.
      let error = NSError(domain: "", code: 42, userInfo: nil)
      self = .Failed(error)
      return
    }
    if sdkResult.isCancelled {
      self = .Cancelled
    } else {
      let grantedPermissions = (sdkResult.grantedPermissions?.flatMap({ $0 as? String }).map({ Permission(name: $0) })).map(Set.init)
      let declinedPermissions = (sdkResult.declinedPermissions?.flatMap({ $0 as? String }).map({ Permission(name: $0) })).map(Set.init)
      self = .Success(grantedPermissions: grantedPermissions ?? [],
                      declinedPermissions: declinedPermissions ?? [],
                      token: AccessToken(sdkAccessToken: sdkResult.token))

    }
  }
}
