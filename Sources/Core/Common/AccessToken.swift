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
import FBSDKCoreKit

//--------------------------------------
// MARK: - Access Token
//--------------------------------------

/**
 Represents an immutable access token used to authenticate with Facebook services.
 */
public struct AccessToken {

  /// The application id for this token.
  public let appId: String

  /// An opaque authentication token.
  public let authenticationToken: String

  /// The logged in user identifier.
  public let userId: String?

  /// The date the token was last refreshed.
  public let refreshDate: Date

  /// The expirate date for the token.
  public let expirationDate: Date

  /// Known granted permissions.
  public let grantedPermissions: Set<Permission>?

  /// Known declined permissions.
  public let declinedPermissions: Set<Permission>?

  /**
   Creates a new access token instance.

   - parameter appId:               Optional application id for this token. Default: `SDKSettings.appId`.
   - parameter authenticationToken: An opaque authentication token.
   - parameter userId:              Optional logged in user identifier.
   - parameter refreshDate:         Optional date the token was last refreshed (defaults to current date).
   - parameter expirationDate:      Optional expiration date (defaults to `NSDate.distantFuture()`).
   - parameter grantedPermissions:  Set of known granted permissions.
   - parameter declinedPermissions: Set of known declined permissions.
   */
  public init(appId: String = SDKSettings.appId,
              authenticationToken: String,
              userId: String? = nil,
              refreshDate: Date = Date(),
              expirationDate: Date = Date.distantFuture,
              grantedPermissions: Set<Permission>? = nil,
              declinedPermissions: Set<Permission>? = nil) {
    self.appId = appId
    self.authenticationToken = authenticationToken
    self.userId = userId
    self.refreshDate = refreshDate
    self.expirationDate = expirationDate
    self.grantedPermissions = grantedPermissions
    self.declinedPermissions = declinedPermissions
  }
}

//--------------------------------------
// MARK: - Current Token
//--------------------------------------

extension AccessToken {
  /**
   A convenient representation of the authentication token of the current user
   that is used by other SDK components (like `LoginManager` or `AppEventsLogger`).
   */
  public static var current: AccessToken? {
    get {
      let token = FBSDKAccessToken.current() as FBSDKAccessToken?
      return token.map(AccessToken.init)
    }
    set {
      FBSDKAccessToken.setCurrent(newValue?.sdkAccessTokenRepresentation)
    }
  }

  /**
   Refresh the current access token's permission state and extend the token's expiration date, if possible.

   On a successful refresh, the `current` access token will be updated automatically, so you don't need to set it again.

   - note: If a token is already expired, it can't be refreshed.
   - parameter completion: Optional completion to call when the token was refreshed or failed.
   */
  public static func refreshCurrentToken(_ completion: ((AccessToken?, Error?) -> Void)? = nil) {
    FBSDKAccessToken.refreshCurrentAccessToken { (_, _, error: Error?) in
      completion?(self.current, error)
    }
  }
}

//--------------------------------------
// MARK: - Internal
//--------------------------------------

extension AccessToken {
  internal init(sdkAccessToken: FBSDKAccessToken) {
    self.init(appId: sdkAccessToken.appID,
              authenticationToken: sdkAccessToken.tokenString,
              userId: sdkAccessToken.userID,
              refreshDate: sdkAccessToken.refreshDate,
              expirationDate: sdkAccessToken.expirationDate,
              grantedPermissions: sdkAccessToken.grantedSwiftPermissions,
              declinedPermissions: sdkAccessToken.declinedSwiftPermissions)
  }

  internal var sdkAccessTokenRepresentation: FBSDKAccessToken {
    return FBSDKAccessToken(tokenString: authenticationToken,
                            permissions: grantedPermissions?.map({ $0.name }),
                            declinedPermissions: declinedPermissions?.map({ $0.name }),
                            appID: appId,
                            userID: userId,
                            expirationDate: expirationDate,
                            refreshDate: refreshDate)
  }
}

private extension FBSDKAccessToken {
  var grantedSwiftPermissions: Set<Permission>? {
    return (permissions?.compactMap({ $0 as? String }).map({ Permission(name: $0) })).map(Set.init)
  }

  var declinedSwiftPermissions: Set<Permission>? {
    return (declinedPermissions?.compactMap({ $0 as? String }).map({ Permission(name: $0) })).map(Set.init)
  }
}
