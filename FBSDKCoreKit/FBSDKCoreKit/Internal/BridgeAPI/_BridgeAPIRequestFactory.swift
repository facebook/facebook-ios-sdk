/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKBridgeAPIRequestFactory)
public final class _BridgeAPIRequestFactory: NSObject, BridgeAPIRequestCreating {
  public func bridgeAPIRequest(
    with protocolType: FBSDKBridgeAPIProtocolType,
    scheme: String,
    methodName: String?,
    parameters: [String: Any]?,
    userInfo: [String: Any]? = nil
  ) -> BridgeAPIRequestProtocol? {
    _BridgeAPIRequest(
      protocolType: protocolType,
      scheme: URLScheme(rawValue: scheme),
      methodName: methodName,
      parameters: parameters,
      userInfo: userInfo
    )
  }
}
