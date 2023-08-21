/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

protocol BridgeAPIResponseCreating {
  func createResponse(request: BridgeAPIRequestProtocol, error: Error) -> BridgeAPIResponse

  func createResponse(
    request: BridgeAPIRequestProtocol,
    responseURL: URL,
    sourceApplication: String?
  ) throws -> BridgeAPIResponse

  func createResponseCancelled(request: BridgeAPIRequestProtocol) -> BridgeAPIResponse
}
