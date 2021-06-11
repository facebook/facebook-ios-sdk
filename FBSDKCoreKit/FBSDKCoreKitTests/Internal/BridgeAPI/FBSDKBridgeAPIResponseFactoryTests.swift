// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import XCTest

class FBSDKBridgeAPIResponseFactoryTests: XCTestCase {

  let factory = BridgeAPIResponseFactory()
  let request = TestBridgeApiRequest(url: SampleUrls.valid)
  let error = SampleError()
  var response: BridgeAPIResponse! // swiftlint:disable:this implicitly_unwrapped_optional

  func testCreatingResponseWithError() {
    response = factory.createResponse(
      withRequest: request,
      error: error
    )
    XCTAssertEqual(
      response.request as? TestBridgeApiRequest,
      request,
      "Should set the request on the response"
    )
    XCTAssertTrue(
      response.error is SampleError,
      "Should set the error on the request"
    )
  }

  func testCreatingCancelledResponse() {
    response = factory.createResponseCancelled(withRequest: request)

    XCTAssertEqual(
      response.request as? TestBridgeApiRequest,
      request,
      "Should set the request on the response"
    )
    XCTAssertTrue(
      response.isCancelled,
      "Should create a cancelled response"
    )
  }

  func testCreatingWithRequestResponseAndSourceApplication() throws {
    request.protocol = TestBridgeApiProtocol()
    response = try factory.createResponse(
      withRequest: request,
      responseURL: SampleUrls.valid,
      sourceApplication: "foo"
    )

    XCTAssertEqual(
      response.request as? TestBridgeApiRequest,
      request,
      "Should set the request on the response"
    )
    XCTAssertFalse(
      response.isCancelled,
      "Should not create a cancelled response"
    )
  }
}
