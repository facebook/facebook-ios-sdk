/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class FBSDKServerConfigurationManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var connection: TestGraphRequestConnection!
  var requestFactory: TestGraphRequestFactory!
  var connectionFactory: TestGraphRequestConnectionFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    connection = TestGraphRequestConnection()
    requestFactory = TestGraphRequestFactory()
    connectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    ServerConfigurationManager.shared.configure(
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
    )
  }

  override func tearDown() {
    ServerConfigurationManager.shared.reset()
    connection = nil
    requestFactory = nil
    connectionFactory = nil

    super.tearDown()
  }

  func testDefaultDependencies() {
    ServerConfigurationManager.shared.reset()

    XCTAssertNil(
      ServerConfigurationManager.shared.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      ServerConfigurationManager.shared.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      ServerConfigurationManager.shared.graphRequestFactory === requestFactory,
      "Should set the provided graph request factory"
    )
    XCTAssertTrue(
      ServerConfigurationManager.shared.graphRequestConnectionFactory === connectionFactory,
      "Should set the provided graph request connection factory"
    )
  }

  func testCompleteFetchingServerConfigurationWithoutConnectionResponseOrError() throws {
    // This test needs more work before it can be included in the regular test suite
    // See T105037698
    try XCTSkipIf(true)

    var didInvokeCompletion = false
    var configuration: ServerConfiguration?
    var error: Error?
    ServerConfigurationManager.shared.loadServerConfiguration { potentialConfiguration, potentialError in
      didInvokeCompletion = true
      configuration = potentialConfiguration
      error = potentialError
    }

    let completion = try XCTUnwrap(connection.capturedCompletion)
    completion(nil, nil, nil)
    XCTAssertEqual(
      connection.startCallCount,
      1,
      "Should start the request to fetch a server configuration"
    )
    XCTAssertTrue(didInvokeCompletion)
    XCTAssertNotNil(
      configuration,
      "Should return a server configuration when there is no result from the graph request"
    )
    XCTAssertNil(
      error,
      "Missing results from the graph request should not result in an error"
    )
  }

  func testParsingResponses() {
    for _ in 0..<100 {
      ServerConfigurationManager.shared.processLoadRequestResponse(
        RawServerConfigurationResponseFixtures.random,
        error: nil,
        appID: name
      )
    }
  }
}
