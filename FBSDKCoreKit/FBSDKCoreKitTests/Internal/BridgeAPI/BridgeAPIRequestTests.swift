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

import UIKit
import XCTest

class BridgeAPIRequestTests: XCTestCase {

  let internalURLOpener = TestInternalURLOpener(canOpenUrl: true)
  let internalUtility = TestInternalUtility()
  let settings = TestSettings()

  override func setUp() {
    super.setUp()

    BridgeAPIRequest.configure(
      internalURLOpener: internalURLOpener,
      internalUtility: internalUtility,
      settings: settings
    )
  }

  override func tearDown() {
    BridgeAPIRequest.resetClassDependencies()
    super.tearDown()
  }

  private func makeRequest(
    protocolType: FBSDKBridgeAPIProtocolType = .web,
    scheme: URLScheme = .https
  ) -> BridgeAPIRequest? {
    BridgeAPIRequest(
      protocolType: protocolType,
      scheme: scheme,
      methodName: "methodName",
      methodVersion: "methodVersion",
      parameters: ["parameter": "value"],
      userInfo: ["key": "value"]
    )
  }

  func testDefaultClassDependencies() throws {
    BridgeAPIRequest.resetClassDependencies()
    _ = makeRequest()

    let testInternalURLOpener = {
      XCTAssertTrue(
        BridgeAPIRequest.internalURLOpener === UIApplication.shared,
        "BridgeAPIRequest should use the shared application for its default internal URL opener dependency"
      )
    }

    #if BUCK
    testInternalURLOpener()
    #else
    XCTExpectFailure(
      "The following test should fail since the tests do not have a valid application singleton",
      failingBlock: testInternalURLOpener
    )
    #endif

    XCTAssertTrue(
      BridgeAPIRequest.internalUtility === InternalUtility.shared,
      "BridgeAPIRequest should use the shared utility for its default internal utility dependency"
    )
    XCTAssertTrue(
      BridgeAPIRequest.settings === Settings.shared,
      "BridgeAPIRequest should use the shared settings for its default settings dependency"
    )
  }

  func testRequestProtocolConformance() {
    XCTAssertTrue(
      (BridgeAPIRequest.self as Any) is BridgeAPIRequestProtocol.Type,
      "BridgeAPIRequest should conform to the expected protocol"
    )
  }

  func testUnsupportedWebURL() {
    XCTAssertNil(
      makeRequest(protocolType: .web, scheme: .facebookApp),
      "BridgeAPIRequests should only be created for valid combinations of protocol type and scheme"
    )
  }

  func testUnopenableURL() {
    internalURLOpener.canOpenUrl = false
    XCTAssertNil(
      makeRequest(protocolType: .native, scheme: .facebookApp),
      "BridgeAPIRequests should only be created for openable URLs"
    )
  }

  func testOpenableURL() {
    XCTAssertNotNil(
      makeRequest(protocolType: .native, scheme: .facebookApp),
      "BridgeAPIRequests should only be created for openable URLs"
    )
  }

  func testProperties() throws {
    let request = try XCTUnwrap(makeRequest())

    XCTAssertEqual(request.protocolType, .web, "A request should use the provided protocol type")
    XCTAssertTrue(
      request.protocol is BridgeAPIProtocolWebV1,
      "A request should use a protocol based on its protocol type"
    )
    XCTAssertEqual(request.scheme, .https, "A request should use the provided scheme")
    XCTAssertEqual(request.methodName, "methodName", "A request should use the provided method name")
    XCTAssertEqual(request.methodVersion, "methodVersion", "A request should use the provided method version")

    let parametersMessage = "A request should use the provided parameters"
    let parameters = try XCTUnwrap(request.parameters, parametersMessage)
    XCTAssertEqual(parameters.count, 1, parametersMessage)
    XCTAssertEqual(parameters["parameter"] as? String, "value", parametersMessage)

    let userInfoMessage = "A request should use the provided user info"
    let userInfo = try XCTUnwrap(request.userInfo, userInfoMessage)
    XCTAssertEqual(userInfo.count, 1, userInfoMessage)
    XCTAssertEqual(userInfo["key"] as? String, "value", userInfoMessage)
  }

  func testUnopenableRequestURL() throws {
    let request = try XCTUnwrap(makeRequest())
    internalURLOpener.canOpenUrl = false

    XCTAssertThrowsError(
      try request.requestURL(),
      "Unopenable request URLs should not be provided"
    )
  }

  func testCopying() throws {
    let request = try XCTUnwrap(makeRequest())
    let copy = try XCTUnwrap(request.copy() as AnyObject)
    XCTAssertTrue(request === copy, "Instances should be provided as copies of themselves")
  }
}
