/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class DeviceLoginCodeInfoTests: XCTestCase {

  enum Values {
    static let identifier = "abcd"
    static let identifier2 = "123"
    static let identifier3 = "123abc"
    static let loginCode = "abcd"
    static let loginCode2 = "123"
    static let loginCode3 = "123abc"
    static let verificationURL = URL(string: "https://www.facebook.com/some/test/url")! // swiftlint:disable:this force_unwrapping
    static let expirationDate = Date.distantFuture
    static let pollingInterval: UInt = 10
  }

  func testCreateValidDeviceLoginCodeShouldSucceed() {
    validateSuccessfulCreation(
      identifier: Values.identifier,
      loginCode: Values.loginCode
    )
    validateSuccessfulCreation(
      identifier: Values.identifier2,
      loginCode: Values.loginCode2
    )
    validateSuccessfulCreation(
      identifier: Values.identifier3,
      loginCode: Values.loginCode3
    )
  }

  func testMinimumPollingInterval() {
    let deviceLoginCodeInfo = DeviceLoginCodeInfo(
      identifier: Values.identifier,
      loginCode: Values.loginCode,
      verificationURL: Values.verificationURL,
      expirationDate: Values.expirationDate,
      pollingInterval: 4
    )
    XCTAssertEqual(deviceLoginCodeInfo.pollingInterval, 5)
  }

  func validateSuccessfulCreation(
    identifier: String,
    loginCode: String,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    let deviceLoginCodeInfo = DeviceLoginCodeInfo(
      identifier: identifier,
      loginCode: loginCode,
      verificationURL: Values.verificationURL,
      expirationDate: Values.expirationDate,
      pollingInterval: Values.pollingInterval
    )
    XCTAssertEqual(deviceLoginCodeInfo.identifier, identifier, file: file, line: line)
    XCTAssertEqual(deviceLoginCodeInfo.loginCode, loginCode, file: file, line: line)
    XCTAssertEqual(deviceLoginCodeInfo.verificationURL, Values.verificationURL, file: file, line: line)
    XCTAssertEqual(deviceLoginCodeInfo.expirationDate, Values.expirationDate, file: file, line: line)
    XCTAssertEqual(deviceLoginCodeInfo.pollingInterval, Values.pollingInterval, file: file, line: line)
  }
}
