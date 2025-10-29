/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import UIKit
import XCTest

final class BridgeAPIRequestTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var internalURLOpener: TestInternalURLOpener!
  var internalUtility: TestInternalUtility!
  var settings: TestSettings!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    internalURLOpener = TestInternalURLOpener(canOpenURL: true)
    internalUtility = TestInternalUtility()
    settings = TestSettings()

    _BridgeAPIRequest.configure(
      internalURLOpener: internalURLOpener,
      internalUtility: internalUtility,
      settings: settings
    )
  }

  override func tearDown() {
    _BridgeAPIRequest.resetClassDependencies()

    internalURLOpener = nil
    internalUtility = nil
    settings = nil

    super.tearDown()
  }

  private func makeRequest(
    protocolType: FBSDKBridgeAPIProtocolType = .web,
    scheme: URLSchemeEnum = .https
  ) -> _BridgeAPIRequest? {
    _BridgeAPIRequest(
      protocolType: protocolType,
      scheme: scheme,
      methodName: "methodName",
      parameters: ["parameter": "value"],
      userInfo: ["key": "value"]
    )
  }

  func testDefaultClassDependencies() throws {
    _BridgeAPIRequest.resetClassDependencies()
    _ = makeRequest()

    XCTAssertNil(_BridgeAPIRequest.settings, "Should not have a default settings")
    XCTAssertNil(_BridgeAPIRequest.internalUtility, "Should not have a default internal utility")
    XCTAssertNil(_BridgeAPIRequest.internalURLOpener, "Should not have a default internal url opener")
  }

  func testRequestProtocolConformance() {
    XCTAssertTrue(
      (_BridgeAPIRequest.self as Any) is BridgeAPIRequestProtocol.Type,
      "_BridgeAPIRequest should conform to the expected protocol"
    )
  }

  func testOpenableURL() {
    XCTAssertNotNil(
      makeRequest(protocolType: FBSDKBridgeAPIProtocolType.native, scheme: URLSchemeEnum.facebookAPI),
      "BridgeAPIRequests should only be created for openable URLs"
    )
  }

  func testProperties() throws {
    let request: _BridgeAPIRequest = try XCTUnwrap(makeRequest())

    XCTAssertEqual(request.protocolType, FBSDKBridgeAPIProtocolType.web, "A request should use the provided protocol type")
    XCTAssertTrue(
      request.protocol is BridgeAPIProtocolWebV1,
      "A request should use a protocol based on its protocol type"
    )
    XCTAssertEqual(request.scheme, URLSchemeEnum.https, "A request should use the provided scheme")
    XCTAssertEqual(request.methodName, "methodName", "A request should use the provided method name")

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
    let request: _BridgeAPIRequest = try XCTUnwrap(makeRequest())
    internalURLOpener.canOpenURL = false

    XCTAssertThrowsError(
      try request.requestURL(),
      "Unopenable request URLs should not be provided"
    )
  }

  func testCopying() throws {
    let request: _BridgeAPIRequest = try XCTUnwrap(makeRequest())
    let copy = try XCTUnwrap(request.copy() as AnyObject)
    XCTAssertTrue(request === copy, "Instances should be provided as copies of themselves")
  }
}
