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

final class BridgeAPIResponseFactoryTests: XCTestCase {

  let factory = _BridgeAPIResponseFactory()
  let request = TestBridgeAPIRequest(url: SampleURLs.valid)
  let error = SampleError()
  lazy var response = factory.createResponse(
    request: request,
    error: error
  )

  func testCreatingResponseWithError() {
    response = factory.createResponse(
      request: request,
      error: error
    )
    XCTAssertEqual(
      response.request as? TestBridgeAPIRequest,
      request,
      "Should set the request on the response"
    )
    XCTAssertTrue(
      response.error is SampleError,
      "Should set the error on the request"
    )
  }

  func testCreatingCancelledResponse() {
    response = factory.createResponseCancelled(request: request)

    XCTAssertEqual(
      response.request as? TestBridgeAPIRequest,
      request,
      "Should set the request on the response"
    )
    XCTAssertTrue(
      response.isCancelled,
      "Should create a cancelled response"
    )
  }

  func testCreatingWithRequestResponseAndSourceApplication() throws {
    request.protocol = TestBridgeAPIProtocol()
    response = try factory.createResponse(
      request: request,
      responseURL: SampleURLs.valid,
      sourceApplication: "foo"
    )

    XCTAssertEqual(
      response.request as? TestBridgeAPIRequest,
      request,
      "Should set the request on the response"
    )
    XCTAssertFalse(
      response.isCancelled,
      "Should not create a cancelled response"
    )
  }
}
