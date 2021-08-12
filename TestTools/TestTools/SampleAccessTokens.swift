// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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
import Foundation

@objcMembers
public class SampleAccessTokens: NSObject {

  public static let defaultTokenString = "token123"
  public static let defaultAppID = "appID123"
  public static let defaultUserID = "user123"

  public static var validToken = AccessToken(
    tokenString: defaultTokenString,
    permissions: [],
    declinedPermissions: [],
    expiredPermissions: [],
    appID: defaultAppID,
    userID: defaultUserID,
    expirationDate: nil,
    refreshDate: nil,
    dataAccessExpirationDate: nil
  )

  public static var expiredToken = AccessToken(
    tokenString: defaultTokenString,
    permissions: [],
    declinedPermissions: [],
    expiredPermissions: [],
    appID: defaultAppID,
    userID: defaultUserID,
    expirationDate: .distantPast,
    refreshDate: nil,
    dataAccessExpirationDate: nil
  )

  public static func create(withRefreshDate date: Date?) -> AccessToken {
    AccessToken(
      tokenString: defaultTokenString,
      permissions: [],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: defaultAppID,
      userID: defaultUserID,
      expirationDate: nil,
      refreshDate: date,
      dataAccessExpirationDate: nil
    )
  }

  public static func create(dataAccessExpirationDate date: Date) -> AccessToken {
    AccessToken(
      tokenString: defaultTokenString,
      permissions: [],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: defaultAppID,
      userID: defaultUserID,
      expirationDate: nil,
      refreshDate: nil,
      dataAccessExpirationDate: date
    )
  }

  public static func create(withPermissions permissions: [String]) -> AccessToken {
    AccessToken(
      tokenString: defaultTokenString,
      permissions: permissions,
      declinedPermissions: [],
      expiredPermissions: [],
      appID: defaultAppID,
      userID: defaultUserID,
      expirationDate: nil,
      refreshDate: nil,
      dataAccessExpirationDate: nil
    )
  }

  public static func create(
    withPermissions permissions: [String],
    declinedPermissions: [String] = [],
    expiredPermissions: [String] = []
  ) -> AccessToken {
    AccessToken(
      tokenString: defaultTokenString,
      permissions: permissions,
      declinedPermissions: declinedPermissions,
      expiredPermissions: expiredPermissions,
      appID: defaultAppID,
      userID: defaultUserID,
      expirationDate: nil,
      refreshDate: nil,
      dataAccessExpirationDate: nil
    )
  }
}
