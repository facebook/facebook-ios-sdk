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

class GateKeeperManagerTests: XCTestCase {

  let requestFactory = TestGraphRequestFactory()
  let connection = TestGraphRequestConnection()
  let connectionFactory = TestGraphRequestConnectionFactory()

  override func setUp() {
    super.setUp()

    connectionFactory.stubbedConnection = connection
    GateKeeperManager.configure(
      settings: TestSettings.self,
      requestProvider: requestFactory,
      connectionProvider: connectionFactory
    )
    GateKeeperManager.logger = TestLogger()
  }

  override func tearDown() {
    super.tearDown()

    TestSettings.reset()
    GateKeeperManager.reset()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    GateKeeperManager.reset()

    XCTAssertNotNil(
      GateKeeperManager.logger,
      "Should have a logger by default"
    )
    XCTAssertNil(
      GateKeeperManager.requestProvider,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      GateKeeperManager.connectionProvider,
      "Should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      GateKeeperManager.settings,
      "Should not have settings by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(GateKeeperManager.requestProvider === requestFactory)
    XCTAssertTrue(GateKeeperManager.connectionProvider === connectionFactory)
    XCTAssertTrue(GateKeeperManager.settings is TestSettings.Type)
  }

  // MARK: - Gatekeeper Validity

  func testValidityWithUnfinishedRequeryWithInvalidTimestamp()
  {
    GateKeeperManager.requeryFinishedForAppStart = false
    GateKeeperManager.timestamp = Date.distantPast

    XCTAssertFalse(
      GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with an unfinished requery and an invalid timestamp is not valid"
    )
  }

  func testValidityWithUnfinishedRequeryWithValidTimestamp()
  {
    GateKeeperManager.requeryFinishedForAppStart = false
    GateKeeperManager.timestamp = Date()

    XCTAssertFalse(
      GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with an unfinished requery and a valid timestamp is not valid"
    )
  }

  func testValidityWithFinishedRequeryWithInvalidTimestamp()
  {
    GateKeeperManager.requeryFinishedForAppStart = true
    GateKeeperManager.timestamp = Date.distantPast

    XCTAssertFalse(
      GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with a finished requery and an invalid timestamp is not valid"
    )
  }

  func testValidityWithFinishedRequeryWithValidTimestamp()
  {
    GateKeeperManager.requeryFinishedForAppStart = true
    GateKeeperManager.timestamp = Date()

    XCTAssertTrue(
      GateKeeperManager._gateKeeperIsValid(),
      "A gatekeeper with a finished requery and a valid timestamp is valid"
    )
  }

  // MARK: - Loading Gatekeepers

  func testLoadingGateKeepersBeforeConfiguring() {
    GateKeeperManager.reset()

    GateKeeperManager.loadGateKeepers { _ in
      XCTFail("Should not invoke the completion when exiting early")
    }
    XCTAssertEqual(
      TestLogger.capturedLogEntry,
      "Cannot load gate keepers before configuring.",
      "Should log a developer warning when trying to use a non-configured manager"
    )
    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      LoggingBehavior.developerErrors.rawValue,
      "Should log a developer warning when trying to use a non-configured manager"
    )
  }

  func testLoadingGateKeepersWithoutAppIdWithoutCompletion() {
    TestSettings.appID = nil
    GateKeeperManager.gateKeepers = ["foo": "true"]
    GateKeeperManager.loadGateKeepers(nil)
    XCTAssertNil(
      GateKeeperManager.gateKeepers,
      "Should clear existing gatekeepers when trying to load without an app id"
    )
  }

  func testLoadingGateKeepersWithoutAppIdWithCompletion() {
    var didInvokeCompletion = false
    GateKeeperManager.loadGateKeepers { potentialError in
      XCTAssertNil(
        potentialError,
        "Should complete without error if the app id is missing"
      );
      didInvokeCompletion = true
    }
    XCTAssertTrue(didInvokeCompletion)
  }

  func testLoadingGateKeepersWhenValid() {
    self.updateGateKeeperValidity(true)

    var didInvokeCompletion = false
    GateKeeperManager.loadGateKeepers { potentialError in
      XCTAssertNil(
        potentialError,
        "Should complete without error if the gatekeeper is valid"
      );
      didInvokeCompletion = true
    }
    XCTAssertTrue(didInvokeCompletion)
    XCTAssertNil(
      requestFactory.capturedWithGraphPath,
      "Should not create a graph request if the gatekeeper is valid"
    )
    XCTAssertNil(
      connection.capturedRequest,
      "Should not create a graph connection if the gatekeeper is valid"
    )
  }

  func testLoadingGateKeepersWhenInvalidWhenNotCurrentlyLoading() {
    TestSettings.appID = name
    GateKeeperManager.gateKeepers = ["foo": "true"]
    self.updateGateKeeperValidity(false)

    GateKeeperManager.loadGateKeepers { _ in
      XCTFail("Should not invoke completion")
    }
    XCTAssertTrue(GateKeeperManager.isLoadingGateKeepers, "Should track when loading is in progress");
    validateGraphRequest(
      connection.capturedRequest,
      isEqualTo: GateKeeperManager.requestToLoadGateKeepers()
    )
  }

  func testLoadingGateKeepersWhenInvalidWhenCurrentlyLoading() {
    TestSettings.appID = name
    GateKeeperManager.gateKeepers = ["foo": "true"]
    self.updateGateKeeperValidity(false)

    var completionCallCount = 0
    GateKeeperManager.loadGateKeepers { _ in
      completionCallCount += 1
    }
    GateKeeperManager.loadGateKeepers { _ in
      completionCallCount += 1
    }

    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should only start one connection even if there are multiple calls to load gatekeepers"
    )

    connection.capturedCompletion?(nil, nil, nil)

    XCTAssertEqual(completionCallCount, 2, "Should invoke all pending completions when the request finishes")
  }

  // MARK: - Request Creation

  func testCreatingRequest() {
    requestFactory.stubbedRequest = GraphRequest(graphPath: "me")
    let appIdentifier = "foo"
    let version = "bar"
    TestSettings.appID = appIdentifier
    TestSettings.sdkVersion = version
    let _ = GateKeeperManager.requestToLoadGateKeepers()

    XCTAssertEqual(
      requestFactory.capturedWithGraphPath,
      "\(appIdentifier)/mobile_sdk_gk",
      "Should use the app identifier from the settings"
    )
    XCTAssertEqual(requestFactory.capturedParameters["platform"] as? String, "ios")
    XCTAssertEqual(
      requestFactory.capturedParameters["sdk_version"] as? String,
      version,
      "Should use the sdk version from the settings"
    )
    XCTAssertEqual(
      requestFactory.capturedParameters["fields"] as? String,
      "gatekeepers",
      "Should request the expected fields"
    )
    XCTAssertNil(
      requestFactory.capturedTokenString,
      "The gate keepers request should be tokenless"
    )
    XCTAssertNil(
      requestFactory.capturedHttpMethod,
      "Should not provide an explicit http method"
    )
    XCTAssertEqual(
      requestFactory.capturedFlags,
      [GraphRequestFlags.skipClientToken, GraphRequestFlags.disableErrorRecovery],
      "Should provide the expected graph request flags"
    )
  }

  // MARK: -  Helpers

  func updateGateKeeperValidity(_ isValid: Bool) {
    if isValid {
      GateKeeperManager.requeryFinishedForAppStart = true
      GateKeeperManager.timestamp = Date()
    } else {
      GateKeeperManager.requeryFinishedForAppStart = false
      GateKeeperManager.timestamp = Date.distantPast
    }
  }

  func validateGraphRequest(
    _ potentialRequest: GraphRequestProtocol?,
    isEqualTo potentialOtherRequest: GraphRequestProtocol?,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    guard let request = potentialRequest else {
      return XCTFail("First request must not be nil", file: file, line: line)
    }
    guard let otherRequest = potentialOtherRequest else {
      return XCTFail("Second request must not be nil", file: file, line: line)
    }
    XCTAssertEqual(request.graphPath, otherRequest.graphPath, "Graph paths should be equal", file: file, line: line)
    XCTAssertEqual(request.version, otherRequest.version, "Versions should be equal", file: file, line: line)
    XCTAssertEqual(request.httpMethod, otherRequest.httpMethod, "HTTP methods should be equal", file: file, line: line)
    let parameters = request.parameters as NSDictionary
    let otherParameters = otherRequest.parameters as NSDictionary
    XCTAssertEqual(parameters, otherParameters, "Parameters should be equal", file: file, line: line)
    XCTAssertEqual(request.tokenString, otherRequest.tokenString, "Token strings should be equal", file: file, line: line)
  }
}
