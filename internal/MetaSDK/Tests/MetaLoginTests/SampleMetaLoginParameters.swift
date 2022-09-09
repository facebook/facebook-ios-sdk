/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

enum SampleMetaLoginParameters {
  enum Keys {
    static let fbAppID = "fb_app_id"
    static let metaAppID = "meta_app_id"
    static let display = "display"
    static let sdk = "sdk"
    static let returnScopes = "return_scopes"
    static let cbt = "cbt"
    static let responseType = "response_type"
    static let scope = "scope"
    static let redirectURI = "redirect_uri"
  }

  static let display = "touch"
  static let sdk = "meta_sdk_ios"
  static let returnScopes = "true"
  static let cbt = String(round(1000 * Date().timeIntervalSince1970))
  static let responseType = "token,graph_domain,signed_request"
  static let scope = "user_avatar"
  static let redirectURI = "fbconnect://success"

  static var defaultParameters: [String: Any] = [
    Keys.display: display,
    Keys.sdk: sdk,
    Keys.returnScopes: returnScopes,
    Keys.cbt: cbt,
    Keys.responseType: responseType,
    Keys.scope: scope,
    Keys.redirectURI: redirectURI,
  ]
}
