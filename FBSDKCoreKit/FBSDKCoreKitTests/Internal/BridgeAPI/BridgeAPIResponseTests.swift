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

class BridgeAPIResponseTests: XCTestCase {
  let request = TestBridgeAPIRequest(url: SampleURLs.valid)
  let bridgeProtocol = TestBridgeAPIProtocol()
  let queryItems = [URLQueryItem(name: "foo", value: "bar")]
  lazy var responseURL: URL = {
    SampleURLs.valid(queryItems: queryItems)
  }()

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

  func testCreatingWithInvalidProtocolSourceApplicationCombinations() {
    request.protocol = bridgeProtocol
    [
      FBSDKBridgeAPIProtocolType.native,
      .web
    ]
    .forEach { protocolType in
      request.protocolType = protocolType

      XCTAssertNil(
        try? BridgeAPIResponse(
          request: request,
          responseURL: responseURL,
          sourceApplication: "foo",
          osVersionComparer: TestProcessInfo(stubbedOperatingSystemCheckResult: false)
        ),
        "Should not create a response when the source application is invalid for the protocol type"
      )
    }
  }

  func testCreatingWithValidProtocolAndSourceApplicationCombinations() {
    request.protocol = bridgeProtocol

    let pairs: [(type: FBSDKBridgeAPIProtocolType, sources: [String])] = [
      (.native, ["com.facebook.foo", ".com.facebook.foo"]),
      (.web, ["com.apple.mobilesafari", "com.apple.SafariViewService"])
    ]

    pairs.forEach { pair in
      request.protocolType = pair.type
      pair.sources.forEach { source in
        let response = try? BridgeAPIResponse(
          request: request,
          responseURL: responseURL,
          sourceApplication: source,
          osVersionComparer: TestProcessInfo(stubbedOperatingSystemCheckResult: false)
        )
        XCTAssertNotNil(
          response,
          """
          Should create a response when the source application \(source)
          is valid for the protocol type \(String(describing: pair.type))
          """
        )
      }
    }
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
