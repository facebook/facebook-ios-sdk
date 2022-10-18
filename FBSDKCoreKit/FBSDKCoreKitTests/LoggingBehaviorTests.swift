/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class LoggingBehaviorTests: XCTestCase {
  func testBehaviors() {
    XCTAssertEqual(
      LoggingBehavior.accessTokens.rawValue,
      "include_access_tokens",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.performanceCharacteristics.rawValue,
      "perf_characteristics",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.appEvents.rawValue,
      "app_events",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.informational.rawValue,
      "informational",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.cacheErrors.rawValue,
      "cache_errors",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.uiControlErrors.rawValue,
      "ui_control_errors",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.graphAPIDebugWarning.rawValue,
      "graph_api_debug_warning",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.graphAPIDebugInfo.rawValue,
      "graph_api_debug_info",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.networkRequests.rawValue,
      "network_requests",
      .rawValue
    )
    XCTAssertEqual(
      LoggingBehavior.developerErrors.rawValue,
      "developer_errors",
      .rawValue
    )
  }
}

// MARK: - Assumptions

// swiftformat:disable:next extensionAccessControl
fileprivate extension String {
  static let rawValue = "A logging behavior has a well-known raw value"
}
