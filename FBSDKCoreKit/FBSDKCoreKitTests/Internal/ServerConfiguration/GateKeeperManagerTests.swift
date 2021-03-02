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

  var graphRequestFactory = TestGraphRequestFactory()

  override func setUp() {
    super.setUp()

    GateKeeperManager.configure(
      settings: TestSettings.self,
      graphRequestProvider: graphRequestFactory
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
      GateKeeperManager.settings,
      "Should not have settings by default"
    )
  }

  func testConfiguringWithDependencies() {
    GateKeeperManager.configure(
      settings: TestSettings.self,
      graphRequestProvider: graphRequestFactory
    )
    XCTAssertTrue(GateKeeperManager.requestProvider === graphRequestFactory)
    XCTAssertTrue(GateKeeperManager.settings is TestSettings.Type)
  }

  // MARK: - Loading Gatekeepers

  func testLoadingGateKeepersBeforeConfiguring() {
    GateKeeperManager.reset()

    GateKeeperManager.loadGateKeepers { error in
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

  // MARK: - Request Creation

  func testCreatingRequest() {
    graphRequestFactory.stubbedRequest = GraphRequest(graphPath: "me")
    let appIdentifier = "foo"
    let version = "bar"
    TestSettings.appID = appIdentifier
    TestSettings.sdkVersion = version
    let _ = GateKeeperManager.requestToLoadGateKeepers()

    XCTAssertEqual(
      graphRequestFactory.capturedWithGraphPath,
      "\(appIdentifier)/mobile_sdk_gk",
      "Should use the app identifier from the settings"
    )
    XCTAssertEqual(graphRequestFactory.capturedParameters["platform"] as? String, "ios")
    XCTAssertEqual(
      graphRequestFactory.capturedParameters["sdk_version"] as? String,
      version,
      "Should use the sdk version from the settings"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedParameters["fields"] as? String,
      "gatekeepers",
      "Should request the expected fields"
    )
    XCTAssertNil(
      graphRequestFactory.capturedTokenString,
      "The gate keepers request should be tokenless"
    )
    XCTAssertNil(
      graphRequestFactory.capturedHttpMethod,
      "Should not provide an explicit http method"
    )
    XCTAssertEqual(
      graphRequestFactory.capturedFlags,
      [GraphRequestFlags.skipClientToken, GraphRequestFlags.disableErrorRecovery],
      "Should provide the expected graph request flags"
    )
  }

}
