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
public final class TestAccessTokenWallet: NSObject, AccessTokenProviding, TokenStringProviding {

  public static var tokenCache: TokenCaching?
  public static var stubbedCurrentAccessToken: AccessToken?
  public static var wasTokenRead = false

  public static var current: AccessToken? {
    get {
      wasTokenRead = true
      return stubbedCurrentAccessToken
    }
    set {
      stubbedCurrentAccessToken = newValue
    }
  }

  public static var tokenString: String? {
    current?.tokenString
  }

  public static func reset() {
    tokenCache = nil
    current = nil
    wasTokenRead = false
  }
}
