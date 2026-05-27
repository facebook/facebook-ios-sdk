/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit
import XCTest

final class LimitedLoginRefreshErrorTests: XCTestCase {

  func testErrorRawValues() {
    XCTAssertEqual(LimitedLoginRefreshError.noCurrentToken.rawValue, 0)
    XCTAssertEqual(LimitedLoginRefreshError.notLimitedLogin.rawValue, 1)
    XCTAssertEqual(LimitedLoginRefreshError.loginRequired.rawValue, 2)
    XCTAssertEqual(LimitedLoginRefreshError.consentRequired.rawValue, 3)
    XCTAssertEqual(LimitedLoginRefreshError.userMismatch.rawValue, 4)
    XCTAssertEqual(LimitedLoginRefreshError.networkError.rawValue, 5)
    XCTAssertEqual(LimitedLoginRefreshError.timeout.rawValue, 6)
    XCTAssertEqual(LimitedLoginRefreshError.rateLimited.rawValue, 7)
    XCTAssertEqual(LimitedLoginRefreshError.invalidResponse.rawValue, 8)
    XCTAssertEqual(LimitedLoginRefreshError.cancelled.rawValue, 9)
    XCTAssertEqual(LimitedLoginRefreshError.featureDisabled.rawValue, 10)
    XCTAssertEqual(LimitedLoginRefreshError.unsupportedPlatform.rawValue, 11)
    XCTAssertEqual(LimitedLoginRefreshError.notDPoPBound.rawValue, 12)
    XCTAssertEqual(LimitedLoginRefreshError.dpopKeyGenerationFailed.rawValue, 13)
    XCTAssertEqual(LimitedLoginRefreshError.unknown.rawValue, 14)
  }

  func testLocalizedDescriptions() {
    let allCases: [LimitedLoginRefreshError] = [
      .noCurrentToken,
      .notLimitedLogin,
      .loginRequired,
      .consentRequired,
      .userMismatch,
      .networkError,
      .timeout,
      .rateLimited,
      .invalidResponse,
      .cancelled,
      .featureDisabled,
      .unsupportedPlatform,
      .notDPoPBound,
      .dpopKeyGenerationFailed,
      .unknown,
    ]

    for error in allCases {
      let description = error.errorDescription
      XCTAssertNotNil(description, "errorDescription should not be nil for \(error)")
      XCTAssertFalse(
        description?.isEmpty ?? true,
        "errorDescription should not be empty for \(error)"
      )
    }
  }

  func testCustomNSErrorDomain() {
    XCTAssertEqual(
      LimitedLoginRefreshError.errorDomain,
      "com.facebook.sdk.login.refresh"
    )
  }

  func testCustomNSErrorCode() {
    let allCases: [LimitedLoginRefreshError] = [
      .noCurrentToken,
      .notLimitedLogin,
      .loginRequired,
      .consentRequired,
      .userMismatch,
      .networkError,
      .timeout,
      .rateLimited,
      .invalidResponse,
      .cancelled,
      .featureDisabled,
      .unsupportedPlatform,
      .notDPoPBound,
      .dpopKeyGenerationFailed,
      .unknown,
    ]

    for error in allCases {
      XCTAssertEqual(
        error.errorCode,
        error.rawValue,
        "errorCode should match rawValue for \(error)"
      )
    }
  }

  func testFallbackPolicyRawValues() {
    XCTAssertEqual(RefreshFallbackPolicy.automatic.rawValue, 0)
    XCTAssertEqual(RefreshFallbackPolicy.silentOnly.rawValue, 1)
    XCTAssertEqual(RefreshFallbackPolicy.explicitOnly.rawValue, 2)
  }
}
