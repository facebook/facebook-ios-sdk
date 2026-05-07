/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Wire-format constants for the Facebook OAuth/Login endpoints.
/// Keep in sync with server-side definitions.
enum LoginEndpoints {
  // MARK: - Paths & hosts

  static let oAuthPath = "/dialog/oauth"
  static let redirectHost = "authorize"
  static let limitedHostPrefix = "limited."

  // MARK: - response_type values

  static let responseTypeLimitedLogin = "id_token,graph_domain,user_token_nonce"
  static let responseTypeFullLogin = "id_token,token_or_nonce,signed_request,graph_domain,user_token_nonce"

  // MARK: - Other parameter values

  static let trackingValueDoNotTrack = "ios_14_do_not_track"
  static let displayValueTouch = "touch"
  static let sdkValueIOS = "ios"
  static let pkceMethodS256 = "S256"
  static let openIDScope = "openid"
}
