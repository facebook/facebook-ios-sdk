/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Represents user login information including both user and authentication data
public final class UserSession: Codable {

  /// The id of the user
  public let userID: UInt
  /// It represents login account type (Facebook/Meta)
  public let graphDomain: GraphDomain
  /// Access token for using Meta SDK APIs
  public internal(set) var accessToken: AccessToken
  /// The permissions that were requested when the token was obtained
  public internal(set) var requestedPermissions: [String]
  /// The permissions that were declined when the token was obtained
  public internal(set) var declinedPermissions: [String]

  internal init(
    userID: UInt,
    graphDomain: GraphDomain,
    accessToken: AccessToken,
    requestedPermissions: [String],
    declinedPermissions: [String]
  ) {
    self.accessToken = accessToken
    self.graphDomain = graphDomain
    self.requestedPermissions = requestedPermissions
    self.userID = userID
    self.declinedPermissions = declinedPermissions
  }
}
