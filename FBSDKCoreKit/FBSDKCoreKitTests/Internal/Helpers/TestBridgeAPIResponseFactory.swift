/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestBridgeAPIResponseFactory: NSObject, BridgeAPIResponseCreating {

  var capturedResponseURL: URL?
  var capturedSourceApplication: String?
  var stubbedResponse: BridgeAPIResponse?
  var shouldFailCreation = false

  func createResponseCancelled(with request: BridgeAPIRequestProtocol) -> BridgeAPIResponse {
    stubbedResponse ?? createResponse(request: request, cancelled: true)
  }

  func createResponse(
    with request: BridgeAPIRequestProtocol,
    error: Error
  ) -> BridgeAPIResponse {
    stubbedResponse ?? createResponse(request: request, error: error)
  }

  func createResponse(
    with request: BridgeAPIRequestProtocol,
    responseURL: URL,
    sourceApplication: String?
  ) throws -> BridgeAPIResponse {
    capturedResponseURL = responseURL
    capturedSourceApplication = sourceApplication

    guard !shouldFailCreation else {
      throw CoreError(.errorBridgeAPIResponse)
    }

    return stubbedResponse ?? createResponse(request: request)
  }

  private func createResponse(
    request: BridgeAPIRequestProtocol,
    error: Error? = nil,
    cancelled: Bool = false
  ) -> BridgeAPIResponse {
    BridgeAPIResponse(
      request: request,
      responseParameters: [:],
      cancelled: cancelled,
      error: error
    )
  }
}
