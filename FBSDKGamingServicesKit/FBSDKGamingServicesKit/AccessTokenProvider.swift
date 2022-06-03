/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class AccessTokenProvider: AccessTokenProviding {
  static var tokenCache: TokenCaching? {
    get {
      AccessToken.tokenCache
    }
    set {
      AccessToken.tokenCache = newValue
    }
  }

  static var current: AccessToken? {
    get {
      AccessToken.current
    }
    set {} // swiftlint:disable:this unused_setter_value
  }
}
