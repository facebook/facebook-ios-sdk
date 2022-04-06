/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import XCTest

final class LoginManagerLoggerTests: XCTestCase {

  let validParameters = [
    "state": "{\"challenge\":\"ibUuyvhzJW36TvC7BBYpasPHrXk%3D\",\"0_auth_logger_id\":\"A48F8D79-F2DF-4E04-B893-B29879A9A37B\",\"com.facebook.sdk_client_state\":true,\"3_method\":\"sfvc_auth\"}", // swiftlint:disable:this line_length
  ]

  func testCreatingWithMissingParametersWithTrackingEnabled() {
    XCTAssertNil(
      LoginManagerLogger(
        parameters: nil,
        tracking: .enabled
      ),
      "Should not create a logger with missing parameters"
    )
  }

  func testCreatingWithEmptyParametersWithTrackingEnabled() {
    XCTAssertNil(
      LoginManagerLogger(
        parameters: [:],
        tracking: .enabled
      ),
      "Should not create a logger with empty parameters"
    )
  }

  func testCreatingWithParametersWithTrackingEnabled() {
    XCTAssertNotNil(
      LoginManagerLogger(
        parameters: validParameters,
        tracking: .enabled
      ),
      "Should create a logger with valid parameters and tracking enabled"
    )
  }

  func testCreatingWithMissingParametersWithTrackingLimited() {
    XCTAssertNil(
      LoginManagerLogger(
        parameters: nil,
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testCreatingWithEmptyParametersWithTrackingLimited() {
    XCTAssertNil(
      LoginManagerLogger(
        parameters: [:],
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testCreatingWithParametersWithTrackingLimited() {
    XCTAssertNil(
      LoginManagerLogger(
        parameters: validParameters,
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testInitializingWithMissingLoggingTokenWithTrackingEnabled() {
    XCTAssertNotNil(
      LoginManagerLogger(
        loggingToken: nil,
        tracking: .enabled
      ),
      "Shouldn't create a logger with a missing logging token but it will"
    )
  }

  func testInitializingloggingTokenWithTrackingEnabled() {
    XCTAssertNotNil(
      LoginManagerLogger(
        loggingToken: "123",
        tracking: .enabled
      ),
      "Should create a logger with a logging token"
    )
  }

  func testInitializingWithMissingLoggingTokenWithTrackingLimited() {
    XCTAssertNil(
      LoginManagerLogger(
        loggingToken: nil,
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testInitializingWithLoggingTokenWithTrackingLimited() {
    XCTAssertNil(
      LoginManagerLogger(
        loggingToken: "123",
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }
}
