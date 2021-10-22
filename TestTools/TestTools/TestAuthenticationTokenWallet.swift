/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
public class TestAuthenticationTokenWallet: NSObject, AuthenticationTokenProviding, AuthenticationTokenSetting {
  public static var tokenCache: TokenCaching?
  public static var currentAuthenticationToken: AuthenticationToken?

  public static func reset() {
    tokenCache = nil
    currentAuthenticationToken = nil
  }
}
