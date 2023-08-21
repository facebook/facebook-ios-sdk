/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class SampleAccessTokens: NSObject {

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
