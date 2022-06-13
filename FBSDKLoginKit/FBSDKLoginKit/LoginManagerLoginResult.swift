/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import Foundation

/// Describes the result of a login attempt.
@objcMembers
@objc(FBSDKLoginManagerLoginResult)
public final class LoginManagerLoginResult: NSObject {

  /// The access token
  public let token: AccessToken?

  /// The authentication token
  public let authenticationToken: AuthenticationToken?

  /// Whether the login was cancelled by the user
  public let isCancelled: Bool

  /// The set of permissions granted by the user in the associated request.
  /// Inspect the token's permissions set for a complete list.
  public let grantedPermissions: Set<String>

  /// The set of permissions declined by the user in the associated request.
  /// Inspect the token's permissions set for a complete list.
  public let declinedPermissions: Set<String>

  private(set) var loggingExtras = [String: Any]()

  /**
   Creates a new result

   @param token The access token
   @param authenticationToken The authentication token
   @param isCancelled whether The login was cancelled by the user
   @param grantedPermissions The set of granted permissions
   @param declinedPermissions The set of declined permissions
   */
  @objc(initWithToken:authenticationToken:isCancelled:grantedPermissions:declinedPermissions:)
  public init(
    token: AccessToken?,
    authenticationToken: AuthenticationToken?,
    isCancelled: Bool,
    grantedPermissions: Set<String>,
    declinedPermissions: Set<String>
  ) {
    self.token = token
    self.authenticationToken = authenticationToken
    self.isCancelled = isCancelled
    self.grantedPermissions = grantedPermissions
    self.declinedPermissions = declinedPermissions
  }

  func addLoggingExtra(_ object: Any, forKey key: String) {
    loggingExtras[key] = object
  }
}

#endif
