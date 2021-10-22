/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public class SampleAuthenticationToken: NSObject {

  public static var validToken: AuthenticationToken {
    AuthenticationToken(
      tokenString: "fakeTokenString",
      nonce: "fakeNonce"
    )
  }

  public static func validToken(withGraphDomain domain: String) -> AuthenticationToken {
    AuthenticationToken(
      tokenString: "fakeTokenString",
      nonce: "fakeNonce",
      graphDomain: domain
    )
  }
}
