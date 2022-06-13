/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

 typealias AuthenticationTokenBlock = (AuthenticationToken?) -> Void

protocol AuthenticationTokenCreating {
  func createToken(
    tokenString: String,
    nonce: String,
    graphDomain: String,
    completion: @escaping AuthenticationTokenBlock
  )
}

#endif
