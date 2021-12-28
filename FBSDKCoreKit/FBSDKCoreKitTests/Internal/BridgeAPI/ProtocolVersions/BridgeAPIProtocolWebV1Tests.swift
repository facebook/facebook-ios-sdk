/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class BridgeAPIProtocolWebV1Tests: XCTestCase {

  enum Keys {
    static let actionID = "action_id"
    static let bridgeArgs = "bridge_args"
    static let completionGesture = "completionGesture"
    static let didComplete = "didComplete"
    static let display = "display"
    static let errorCode = "error_code"
    static let redirectURI = "redirect_uri"
  }

  enum Values {
    static let actionID = "123"
    static let cancel = "cancel"
    static let cancellationErrorCode = 4201
    static let methodName = "open"
    static let redirectURI = "fb://bridge/open?bridge_args=%7B%22action_id%22%3A%22123%22%7D"
    static let touch = "touch"
  }

  enum QueryParameters {
    static let withoutBridgeArgs: [String: Any] = [:]
    static let withEmptyBridgeArgs: [String: Any] = [Keys.bridgeArgs: ""]
    static let valid = withBridgeArgs(responseActionID: Values.actionID)

    static func jsonString(actionID: String) -> String {
      let data = try! JSONSerialization.data( // swiftlint:disable:this force_try
        withJSONObject: [Keys.actionID: actionID], options: []
      )
      return String(data: data, encoding: .utf8)! // swiftlint:disable:this force_unwrapping
    }

    static func withBridgeArgs(responseActionID: String) -> [String: Any] {
      [Keys.bridgeArgs: jsonString(actionID: responseActionID)]
    }

    static func validWithErrorCode(_ code: Int) -> [String: Any] {
      [
        Keys.errorCode: code,
        Keys.bridgeArgs: jsonString(actionID: Values.actionID)
      ]
    }
  }

  // swiftlint:disable implicitly_unwrapped_optional
  var bridge: BridgeAPIProtocolWebV1!
  var errorFactory: ErrorCreating!
  var internalUtility: TestInternalUtility!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    errorFactory = TestErrorFactory()
    internalUtility = TestInternalUtility()
    bridge = BridgeAPIProtocolWebV1(
      errorFactory: errorFactory,
      internalUtility: internalUtility
    )
  }

  override func tearDown() {
    errorFactory = nil
    internalUtility = nil
    bridge = nil

    super.tearDown()
  }

  func testInitialization() {
    XCTAssertTrue(
      bridge.errorFactory === errorFactory,
      "Should be able to create an instance with an error factory"
    )
    XCTAssertTrue(
      bridge.internalUtility === internalUtility,
      "Should be able to create an instance with an error factory"
    )
  }

  func testDefaultDependencies() throws {
    bridge = BridgeAPIProtocolWebV1()
    let factory = try XCTUnwrap(
      bridge.errorFactory as? ErrorFactory,
      "The class should have an error factory by default"
    )
    XCTAssertTrue(
      factory.reporter === ErrorReporter.shared,
      "The default factory should use the shared error reporter"
    )
    XCTAssertTrue(
      bridge.internalUtility === InternalUtility.shared,
      "The bridge should use the shared internal utility by default"
    )
  }

  func testCreatingURLWithAllFields() throws {
    // For first use of internal utility
    let redirectURL = SampleURLs.valid.appendingPathComponent("redirect")
    internalUtility.stubbedAppURL = redirectURL

    // For second use of internal utility
    let facebookURL = SampleURLs.valid.appendingPathComponent("facebook")
    internalUtility.stubbedFacebookURL = facebookURL

    let queryParameters = ["a": "b"]

    let url = try bridge.requestURL(
      withActionID: Values.actionID,
      scheme: URLScheme.https.rawValue,
      methodName: Values.methodName,
      parameters: queryParameters
    )

    let appURLMessage = "The protocol should use its internal utility to create an app URL"
    XCTAssertEqual(internalUtility.capturedAppURLHost, "bridge", appURLMessage)
    XCTAssertEqual(internalUtility.capturedAppURLPath, Values.methodName, appURLMessage)
    XCTAssertEqual(
      internalUtility.capturedAppURLQueryParameters,
      ["bridge_args": QueryParameters.jsonString(actionID: Values.actionID)],
      appURLMessage
    )

    let facebookURLMessage = "The protocol should use its internal utility to create a Facebook URL"
    var expectedParameters = queryParameters
    expectedParameters["display"] = "touch"
    expectedParameters["redirect_uri"] = redirectURL.absoluteString

    XCTAssertEqual(internalUtility.capturedFacebookURLHostPrefix, "m", facebookURLMessage)
    XCTAssertEqual(
      internalUtility.capturedFacebookURLPath,
      "/dialog/\(Values.methodName)",
      facebookURLMessage
    )
    XCTAssertEqual(
      internalUtility.capturedFacebookURLQueryParameters,
      expectedParameters,
      facebookURLMessage
    )

    XCTAssertEqual(
      url,
      facebookURL,
      "The protocol should return the Facebook URL created by its internal utility"
    )
  }

  func testResponseParametersWithUnknownErrorCode() {
    XCTAssertNil(
      try? bridge.responseParameters(
        forActionID: Values.actionID,
        queryParameters: QueryParameters.validWithErrorCode(123),
        cancelled: nil
      ),
      "Should not create response parameters when there is an unknown error code"
    )
  }

  func testResponseParametersWithoutBridgeParameters() {
    XCTAssertNil(
      try? bridge.responseParameters(
        forActionID: Values.actionID,
        queryParameters: QueryParameters.withoutBridgeArgs,
        cancelled: nil
      ),
      "Should not create response parameters when there are no bridge arguments"
    )
  }

  func testResponseParametersWithoutActionID() {
    XCTAssertNil(
      try? bridge.responseParameters(
        forActionID: Values.actionID,
        queryParameters: QueryParameters.withEmptyBridgeArgs,
        cancelled: nil
      ),
      "Should not create response parameters when there is no action id"
    )
  }

  func testResponseParametersWithMismatchedResponseActionID() {
    XCTAssertNil(
      try? bridge.responseParameters(
        forActionID: Values.actionID,
        queryParameters: QueryParameters.withBridgeArgs(responseActionID: "foo"),
        cancelled: nil
      ),
      "Should not create response parameters when the action IDs do not match"
    )
  }

  func testResponseParametersWithMatchingResponseActionID() {
    guard let response = try? bridge.responseParameters(
      forActionID: Values.actionID,
      queryParameters: QueryParameters.valid,
      cancelled: nil
    ) else {
      return XCTFail("Should create a valid response")
    }

    XCTAssertEqual(
      response as? [String: Int],
      [Keys.didComplete: 1],
      "Should indicate that the response completed"
    )
  }

  func testResponseParametersWithCancellationErrorCode() {
    guard let response = try? bridge.responseParameters(
      forActionID: Values.actionID,
      queryParameters: QueryParameters.validWithErrorCode(Values.cancellationErrorCode),
      cancelled: nil
    ) else {
      return XCTFail("Should create a valid response")
    }

    XCTAssertEqual(
      response as? [String: String],
      [Keys.completionGesture: Values.cancel],
      "Should indicate a cancelation when there's a cancellation error code"
    )
  }
}
