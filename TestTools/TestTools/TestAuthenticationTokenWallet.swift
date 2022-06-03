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
public final class TestAuthenticationTokenWallet: NSObject, AuthenticationTokenProviding {
  public static var tokenCache: TokenCaching?
  public static var current: AuthenticationToken?

  public static func reset() {
    tokenCache = nil
    current = nil
  }
}
