/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class EventDeactivationTests: XCTestCase {

  enum Keys {
    static let ui = AppEvents.ParameterName("_ui")
    static let logTime = AppEvents.ParameterName("_logTime")
    static let sessionID = AppEvents.ParameterName("_session_id")
    static let launchSource = AppEvents.ParameterName("fb_mobile_launch_source")
    static let deprecated = AppEvents.ParameterName("deprecated_3")
  }

  let rawConfiguration = [
    "restrictiveParams": [
      "fb_mobile_catalog_update": [
        "restrictive_param": ["first_name": "6"],
      ],
      "manual_initiated_checkout": [
        "deprecated_param": ["deprecated_3"],
      ],
    ],
  ]

  lazy var serverConfiguration = ServerConfigurationFixtures.configuration(withDictionary: rawConfiguration)

  // swiftlint:disable implicitly_unwrapped_optional
  var provider: TestServerConfigurationProvider!
  var eventDeactivationManager: EventDeactivationManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    eventDeactivationManager = EventDeactivationManager()
    eventDeactivationManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
  }

  override func tearDown() {
    super.tearDown()

    provider = nil
    eventDeactivationManager = nil
  }

  func testDefaultDependencies() throws {
    eventDeactivationManager.resetDependencies()
    XCTAssertTrue(
      eventDeactivationManager.serverConfigurationProvider === _ServerConfigurationManager.shared,
      "Should use the shared server configuration manger by default"
    )
  }

  func testConfiguringDependencies() {
    XCTAssertTrue(
      eventDeactivationManager.serverConfigurationProvider === provider,
      "Should be able to create with a server configuration provider"
    )
  }

  func testProcessParameters() throws {
    eventDeactivationManager.enable()

    let parameters: [AppEvents.ParameterName: Any] = [
      Keys.ui: "UITabBarController",
      Keys.logTime: 1_576_109_848,
      Keys.sessionID: "30AF582C-0225-40A4-B3EE-2A571AB926F3",
      Keys.launchSource: "Unclassified",
      Keys.deprecated: "test",
    ]

    let result = try XCTUnwrap(
      eventDeactivationManager.processParameters(
        parameters,
        eventName: .init("manual_initiated_checkout")
      ),
      "Result must not be nil"
    )

    XCTAssertNil(result[Keys.deprecated])
    XCTAssertNotNil(result[Keys.ui])
    XCTAssertNotNil(result[Keys.logTime])
    XCTAssertNotNil(result[Keys.sessionID])
    XCTAssertNotNil(result[Keys.launchSource])
  }
}
