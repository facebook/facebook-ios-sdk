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
