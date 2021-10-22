/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class AccessTokenProvider: AccessTokenProviding {
  static var tokenCache: TokenCaching? {
    get {
      AccessToken.tokenCache
    }
    set {
      AccessToken.tokenCache = newValue
    }
  }

  static var currentAccessToken: AccessToken? {
    AccessToken.current
  }
}
