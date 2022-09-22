/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKBridgeAPIResponseCreating)
public protocol _BridgeAPIResponseCreating {

  func createResponse(request: BridgeAPIRequestProtocol, error: Error) -> BridgeAPIResponse

  func createResponse(
    request: BridgeAPIRequestProtocol,
    responseURL: URL,
    sourceApplication: String?
  ) throws -> BridgeAPIResponse

  func createResponseCancelled(request: BridgeAPIRequestProtocol) -> BridgeAPIResponse
}

#endif
