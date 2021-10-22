/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class NetworkErrorCheckerTests: XCTestCase {

  // MARK: - Test Assumptions

  private enum Assumptions {
    static let isNonNetworkErrorByCode = """
      An error without a network error code and no underlying network error is \
      not a network error
      """

    static let isNonNetworkErrorByUnderlyingError = """
      An error without a network error code is only a network error if it \
      contains an underlying network error
      """

    static func isNetworkErrorByCode(_ code: URLError.Code) -> String {
      "An error with a network error code \(code) is a network error"
    }

    static let isNetworkErrorByUnderlyingNetworkError = """
      An error with an underlying error that is a network error is itself a \
      network error
      """
  }

  // MARK: - Error Codes

  static let nonNetworkErrorCode = URLError.Code.cancelled
  static let networkErrorCodes: [URLError.Code] = [
    .timedOut,
    .cannotFindHost,
    .cannotConnectToHost,
    .networkConnectionLost,
    .dnsLookupFailed,
    .notConnectedToInternet,
    .internationalRoamingOff,
    .callIsActive,
    .dataNotAllowed
  ]

  // MARK: - Test Fixture

  let checker: NetworkErrorChecking = NetworkErrorChecker()

  private func makeError(
    networkCode: URLError.Code,
    underlyingError: Error? = nil
  ) -> NSError {
    var userInfo: [String: Any]?
    if let underlyingError = underlyingError {
      userInfo = [NSUnderlyingErrorKey: underlyingError]
    }

    return NSError(
      domain: "",
      code: networkCode.rawValue,
      userInfo: userInfo
    )
  }

  // MARK: - Tests

  func testNonNetworkErrorWithoutUnderlyingError() {
    let error = makeError(networkCode: Self.nonNetworkErrorCode)
    XCTAssertFalse(
      checker.isNetworkError(error),
      Assumptions.isNonNetworkErrorByCode
    )
  }

  func testNonNetworkErrorWithUnderlyingError() {
    let underlyingError = makeError(networkCode: Self.nonNetworkErrorCode)
    let error = makeError(
      networkCode: Self.nonNetworkErrorCode,
      underlyingError: underlyingError
    )

    XCTAssertFalse(
      checker.isNetworkError(error),
      Assumptions.isNonNetworkErrorByUnderlyingError
    )
  }

  func testNetworkErrorWithoutUnderlyingError() {
    Self.networkErrorCodes
      .forEach { code in
        let error = makeError(networkCode: code)
        XCTAssertTrue(
          checker.isNetworkError(error),
          Assumptions.isNetworkErrorByCode(code)
        )
      }
  }

  func testNetworkErrorWithUnderlyingError() throws {
    let code = try XCTUnwrap(Self.networkErrorCodes.randomElement())
    let underlyingError = makeError(networkCode: code)
    let error = makeError(
      networkCode: Self.nonNetworkErrorCode,
      underlyingError: underlyingError
    )

    XCTAssertTrue(
      checker.isNetworkError(error),
      Assumptions.isNetworkErrorByUnderlyingNetworkError
    )
  }
}
