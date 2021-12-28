/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class EventDeactivationTests: XCTestCase {

  enum Keys {
    static let ui = "_ui" // swiftlint:disable:this identifier_name
    static let logTime = "_logTime"
    static let sessionID = "_session_id"
    static let launchSource = "fb_mobile_launch_source"
    static let deprecated = "deprecated_3"
  }

  let rawConfiguration = [
    "restrictiveParams": [
      "fb_mobile_catalog_update": [
        "restrictive_param": ["first_name": "6"]
      ],
      "manual_initiated_checkout": [
        "deprecated_param": ["deprecated_3"]
      ]
    ]
  ]
  lazy var serverConfiguration = ServerConfigurationFixtures.config(withDictionary: rawConfiguration)
  lazy var provider = TestServerConfigurationProvider(configuration: serverConfiguration)
  lazy var eventDeactivationManager = EventDeactivationManager(
    serverConfigurationProvider: provider
  )

  func testProcessParameters() {
    eventDeactivationManager.enable()

    let parameters: [String: Any] = [
      Keys.ui: "UITabBarController",
      Keys.logTime: 1_576_109_848,
      Keys.sessionID: "30AF582C-0225-40A4-B3EE-2A571AB926F3",
      Keys.launchSource: "Unclassified",
      Keys.deprecated: "test",
    ]

    guard let result = eventDeactivationManager.processParameters(
      parameters,
      eventName: "manual_initiated_checkout"
    ) else {
      XCTFail("Result must not be nil")
      return
    }

    XCTAssertNil(result[Keys.deprecated])
    XCTAssertNotNil(result[Keys.ui])
    XCTAssertNotNil(result[Keys.logTime])
    XCTAssertNotNil(result[Keys.sessionID])
    XCTAssertNotNil(result[Keys.launchSource])
  }
}
