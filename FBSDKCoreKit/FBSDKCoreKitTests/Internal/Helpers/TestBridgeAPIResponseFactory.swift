/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class TestBridgeAPIResponseFactory: BridgeAPIResponseCreating {

  var capturedResponseURL: URL?
  var capturedSourceApplication: String?
  var stubbedResponse: BridgeAPIResponse?
  var shouldFailCreation = false

  func createResponseCancelled(request: BridgeAPIRequestProtocol) -> BridgeAPIResponse {
    stubbedResponse ?? createResponse(withRequest: request, cancelled: true)
  }

  func createResponse(
    request: BridgeAPIRequestProtocol,
    error: Error
  ) -> BridgeAPIResponse {
    stubbedResponse ?? createResponse(withRequest: request, error: error)
  }

  func createResponse(
    request: BridgeAPIRequestProtocol,
    responseURL: URL,
    sourceApplication: String?
  ) throws -> BridgeAPIResponse {
    capturedResponseURL = responseURL
    capturedSourceApplication = sourceApplication

    guard !shouldFailCreation else {
      throw CoreError(.errorBridgeAPIResponse)
    }

    return stubbedResponse ?? createResponse(withRequest: request)
  }

  private func createResponse(
    withRequest request: BridgeAPIRequestProtocol,
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
