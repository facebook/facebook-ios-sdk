/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class ServerConfigurationManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var connection: TestGraphRequestConnection!
  var requestFactory: TestGraphRequestFactory!
  var connectionFactory: TestGraphRequestConnectionFactory!
  var dialogConfigurationMapBuilder: TestDialogConfigurationMapBuilder!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    connection = TestGraphRequestConnection()
    requestFactory = TestGraphRequestFactory()
    connectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    dialogConfigurationMapBuilder = TestDialogConfigurationMapBuilder()
    _ServerConfigurationManager.shared.configure(
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory,
      dialogConfigurationMapBuilder: dialogConfigurationMapBuilder
    )
  }

  override func tearDown() {
    _ServerConfigurationManager.shared.reset()
    connection = nil
    requestFactory = nil
    connectionFactory = nil
    dialogConfigurationMapBuilder = nil

    super.tearDown()
  }

  func testDefaultDependencies() {
    _ServerConfigurationManager.shared.reset()

    XCTAssertNil(
      _ServerConfigurationManager.shared.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      _ServerConfigurationManager.shared.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
    XCTAssertNil(
      _ServerConfigurationManager.shared.dialogConfigurationMapBuilder,
      "Should not have a dialog configuration map builder by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      _ServerConfigurationManager.shared.graphRequestFactory === requestFactory,
      "Should set the provided graph request factory"
    )
    XCTAssertTrue(
      _ServerConfigurationManager.shared.graphRequestConnectionFactory === connectionFactory,
      "Should set the provided graph request connection factory"
    )
    XCTAssertTrue(
      _ServerConfigurationManager.shared.dialogConfigurationMapBuilder === dialogConfigurationMapBuilder,
      "Should set the provided dialog configuration map builder"
    )
  }

  // swiftlint:disable:next identifier_name
  func _testCompleteFetchingServerConfigurationWithoutConnectionResponseOrError() throws {
    // This test needs more work before it can be included in the regular test suite
    // See T105037698
    try XCTSkipIf(true)

    var didInvokeCompletion = false
    var configuration: _ServerConfiguration?
    var error: Error?
    _ServerConfigurationManager.shared.loadServerConfiguration { potentialConfiguration, potentialError in
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

  func testParsingWithMissingDialogConfigurations() {
    _ServerConfigurationManager.shared.processLoadRequestResponse(
      [String: Any](),
      error: nil,
      appID: name
    )
    XCTAssertNil(
      dialogConfigurationMapBuilder.capturedRawConfigurations,
      "Should not invoke the dialog configuration builder when the raw response is missing a raw dialog configuration"
    )
  }

  func testParsingWithDialogConfigurationsMissingDataKey() {
    let response = [
      RawServerConfigurationResponseFixtures.Keys.dialogConfigurations: [String: Any](),
    ]

    _ServerConfigurationManager.shared.processLoadRequestResponse(
      response,
      error: nil,
      appID: name
    )
    XCTAssertNil(
      dialogConfigurationMapBuilder.capturedRawConfigurations,
      "Should not invoke the dialog configuration builder when the raw dialog configuration is missing a data key"
    )
  }

  func testParsingWithValidDialogConfigurations() {
    let expectedRawConfigurations = [
      SampleRawDialogConfigurations.createValid(name: name),
      SampleRawDialogConfigurations.createValid(name: "foo"),
    ]
    let response = [
      "ios_dialog_configs": [
        "data": expectedRawConfigurations,
      ],
    ]

    _ServerConfigurationManager.shared.processLoadRequestResponse(
      response,
      error: nil,
      appID: name
    )

    zip(
      dialogConfigurationMapBuilder.capturedRawConfigurations ?? [],
      expectedRawConfigurations
    )
    .forEach { actual, expected in
      assertEqualRawDialogConfigurations(actual, expected)
    }
  }

  func testParsingResponses() {
    for _ in 0 ..< 100 {
      _ServerConfigurationManager.shared.processLoadRequestResponse(
        RawServerConfigurationResponseFixtures.random,
        error: nil,
        appID: name
      )
    }
  }

  // MARK: - Helpers

  func assertEqualRawDialogConfigurations(
    _ actual: [String: Any],
    _ expected: [String: Any],
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    XCTAssertEqual(
      actual["name"] as? String,
      expected["name"] as? String,
      file: file,
      line: line
    )
    XCTAssertEqual(
      actual["url"] as? String,
      expected["url"] as? String,
      file: file,
      line: line
    )
    XCTAssertEqual(
      actual["versions"] as? [String],
      expected["versions"] as? [String],
      file: file,
      line: line
    )
  }
}
