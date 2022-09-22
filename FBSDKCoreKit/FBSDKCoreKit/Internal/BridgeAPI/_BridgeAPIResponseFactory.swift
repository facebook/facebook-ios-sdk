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
@objc(FBSDKBridgeAPIResponseFactory)
public final class _BridgeAPIResponseFactory: NSObject, _BridgeAPIResponseCreating {
  public func createResponse(request: BridgeAPIRequestProtocol, error: Error) -> BridgeAPIResponse {
    BridgeAPIResponse(request: request, error: error)
  }

  public func createResponse(
    request: BridgeAPIRequestProtocol,
    responseURL: URL,
    sourceApplication: String?
  ) throws -> BridgeAPIResponse {
    try BridgeAPIResponse(
      request: request,
      responseURL: responseURL,
      sourceApplication: sourceApplication
    )
  }

  public func createResponseCancelled(request: BridgeAPIRequestProtocol) -> BridgeAPIResponse {
    BridgeAPIResponse(cancelledWith: request)
  }
}

#endif
