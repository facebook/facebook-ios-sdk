/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

@objcMembers
final class TestBridgeAPIRequestFactory: NSObject, BridgeAPIRequestCreating {
  var capturedProtocolType: FBSDKBridgeAPIProtocolType?
  var capturedScheme: String?
  var capturedMethodName: String?
  var capturedParameters: [String: Any]?
  var capturedUserInfo: [String: Any]?
  var stubbedBridgeAPIRequest: TestBridgeAPIRequest?

  func bridgeAPIRequest(
    with protocolType: FBSDKBridgeAPIProtocolType,
    scheme: String,
    methodName: String?,
    parameters: [String: Any]? = nil,
    userInfo: [String: Any]? = nil
  ) -> BridgeAPIRequestProtocol? {
    capturedProtocolType = protocolType
    capturedScheme = scheme
    capturedMethodName = methodName
    capturedParameters = parameters
    capturedUserInfo = userInfo

    return stubbedBridgeAPIRequest
  }
}
