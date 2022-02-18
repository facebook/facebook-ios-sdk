/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

final class ShareBridgeAPIRequestFactory: BridgeAPIRequestCreating {

  func bridgeAPIRequest(
    with protocolType: FBSDKBridgeAPIProtocolType,
    scheme: String,
    methodName: String?,
    parameters: [String: Any]?,
    userInfo: [String: Any]?
  ) -> BridgeAPIRequestProtocol? {
    BridgeAPIRequest(
      protocolType: protocolType,
      scheme: URLScheme(rawValue: scheme),
      methodName: methodName,
      parameters: parameters,
      userInfo: userInfo
    )
  }
}

#endif
