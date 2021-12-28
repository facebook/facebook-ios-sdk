/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
public class TestAccessTokenWallet: NSObject, AccessTokenProviding, AccessTokenSetting, TokenStringProviding {

  public static var tokenCache: TokenCaching?
  public static var stubbedCurrentAccessToken: AccessToken?
  public static var wasTokenRead = false

  public static var currentAccessToken: AccessToken? {
    get {
      wasTokenRead = true
      return stubbedCurrentAccessToken
    }
    set {
      stubbedCurrentAccessToken = newValue
    }
  }

  public static var tokenString: String? {
    currentAccessToken?.tokenString
  }

  public static func reset() {
    tokenCache = nil
    currentAccessToken = nil
    wasTokenRead = false
  }
}
