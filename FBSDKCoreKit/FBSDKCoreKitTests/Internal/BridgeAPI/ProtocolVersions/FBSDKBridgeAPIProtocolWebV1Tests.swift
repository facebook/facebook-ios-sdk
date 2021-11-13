/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class FBSDKBridgeAPIProtocolWebV1Tests: XCTestCase {

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
    static let methodVersion = "v1"
    static let redirectURI = "fb://bridge/open?bridge_args=%7B%22action_id%22%3A%22123%22%7D"
    static let touch = "touch"
    static let unknownErrorCode = 12345
  }

  enum QueryParameters {
    static let withoutBridgeArgs: [String: Any] = [:]
    static let withEmptyBridgeArgs: [String: Any] = [Keys.bridgeArgs: ""]
    static let valid = withBridgeArgs(responseActionID: Values.actionID)

    // swiftlint:disable force_try force_unwrapping
    static func jsonString(actionID: String) -> String {
      let data = try! JSONSerialization.data(
        withJSONObject: [Keys.actionID: actionID], options: []
      )
      return String(data: data, encoding: .utf8)!
    }
    // swiftlint:enable force_try force_unwrapping

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
  var errorFactory: ErrorCreating!
  var bridge: BridgeAPIProtocolWebV1!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    errorFactory = TestErrorFactory()
    bridge = BridgeAPIProtocolWebV1(errorFactory: errorFactory)
  }

  override func tearDown() {
    errorFactory = nil
    bridge = nil

    super.tearDown()
  }

  func testInitialization() {
    XCTAssertTrue(
      bridge.errorFactory === errorFactory,
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
  }

  func testCreatingURLWithAllFields() throws {
    let url = try bridge.requestURL(
      withActionID: Values.actionID,
      scheme: URLScheme.https.rawValue,
      methodName: Values.methodName,
      parameters: QueryParameters.valid
    )
    let expectedGraphVersion = try XCTUnwrap(Settings.shared.graphAPIVersion)
    XCTAssertEqual(
      url.host,
      "m.facebook.com",
      "Should create a url with the expected host"
    )
    XCTAssertEqual(
      url.path,
      "/\(expectedGraphVersion)/dialog/open",
      "Should create a url with the expected path"
    )
    guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
    else {
      return XCTFail("Should have query items")
    }
    [
      URLQueryItem(name: Keys.bridgeArgs, value: QueryParameters.jsonString(actionID: Values.actionID)),
      URLQueryItem(name: Keys.display, value: Values.touch),
      URLQueryItem(name: Keys.redirectURI, value: Values.redirectURI)
    ].forEach { queryItem in
      XCTAssertTrue(
        queryItems.contains(queryItem)
      )
    }
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
