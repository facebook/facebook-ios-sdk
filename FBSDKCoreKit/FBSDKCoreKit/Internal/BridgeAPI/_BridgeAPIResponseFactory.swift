/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class _BridgeAPIResponseFactory: NSObject, BridgeAPIResponseCreating {
  func createResponse(request: BridgeAPIRequestProtocol, error: Error) -> BridgeAPIResponse {
    BridgeAPIResponse(request: request, error: error)
  }

  func createResponse(
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

  func createResponseCancelled(request: BridgeAPIRequestProtocol) -> BridgeAPIResponse {
    BridgeAPIResponse(cancelledWith: request)
  }
}
