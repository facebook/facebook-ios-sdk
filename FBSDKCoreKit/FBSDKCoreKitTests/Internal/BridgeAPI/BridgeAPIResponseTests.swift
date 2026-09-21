/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class BridgeAPIResponseTests: XCTestCase {
  let request = TestBridgeAPIRequest(url: SampleURLs.valid)
  let bridgeProtocol = TestBridgeAPIProtocol()
  let queryItems = [URLQueryItem(name: "foo", value: "bar")]
  lazy var responseURL = SampleURLs.valid(queryItems: queryItems)

  func testCreatingWithMinimalInput() {
    let response = BridgeAPIResponse(request: request, error: SampleError())

    XCTAssertFalse(
      response.isCancelled,
      "The response should not be cancelled by default"
    )
    XCTAssertEqual(
      response.request as? TestBridgeAPIRequest,
      request,
      "Should store the request it was created with"
    )
    XCTAssertNil(
      response.responseParameters,
      "Should not have response parameters by default"
    )
  }

  func testCreatingCancelledWithRequest() {
    let response = BridgeAPIResponse(cancelledWith: request)

    XCTAssertTrue(
      response.isCancelled,
      "The response should be cancelled upon creation"
    )
    XCTAssertEqual(
      response.request as? TestBridgeAPIRequest,
      request,
      "Should store the request it was created with"
    )
    XCTAssertNil(
      response.responseParameters,
      "Should not have parameters when creating as cancelled"
    )
    XCTAssertNil(
      response.error,
      "Should not have an error reference by default"
    )
  }

  func testCreatingWithValidResponseParameters() {
    request.actionID = "123"
    request.protocol = bridgeProtocol

    _ = try? BridgeAPIResponse(
      request: request,
      responseURL: responseURL,
      sourceApplication: "foo"
    )
    XCTAssertEqual(
      bridgeProtocol.capturedResponseActionID,
      request.actionID,
      "Should use the action ID from the request to generate the response"
    )
    XCTAssertNotNil(
      bridgeProtocol.capturedResponseCancelledRef,
      "Should call the response helper with an error reference"
    )
    XCTAssertEqual(
      bridgeProtocol.capturedResponseQueryParameters as? [String: String],
      ["foo": "bar"],
      "Should use the query items from the response url to create the bridge response"
    )
  }
}
