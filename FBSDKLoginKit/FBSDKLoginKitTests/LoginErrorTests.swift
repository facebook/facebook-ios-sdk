/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit
import XCTest

// These tests can likely be simplified once we move to a pure Swift implementation and no longer
// need to have the error types conform to `CustomNSError`.
final class LoginErrorTests: XCTestCase {

  func testDomains() {
    XCTAssertEqual(LoginErrorDomain, "com.facebook.sdk.login", .domain)
    XCTAssertEqual(LoginError.errorDomain, LoginErrorDomain, .domainInLoginError)
    XCTAssertEqual(DeviceLoginError.errorDomain, LoginErrorDomain, .domainInDeviceLoginError)
  }

  func testLoginErrorCodes() {
    testLoginError(LoginError.reserved, code: .reserved, rawValue: 300)
    testLoginError(LoginError.unknown, code: .unknown, rawValue: 301)
    testLoginError(LoginError.passwordChanged, code: .passwordChanged, rawValue: 302)
    testLoginError(LoginError.userCheckpointed, code: .userCheckpointed, rawValue: 303)
    testLoginError(LoginError.userMismatch, code: .userMismatch, rawValue: 304)
    testLoginError(LoginError.unconfirmedUser, code: .unconfirmedUser, rawValue: 305)
    testLoginError(LoginError.systemAccountAppDisabled, code: .systemAccountAppDisabled, rawValue: 306)
    testLoginError(LoginError.systemAccountUnavailable, code: .systemAccountUnavailable, rawValue: 307)
    testLoginError(LoginError.badChallengeString, code: .badChallengeString, rawValue: 308)
    testLoginError(LoginError.invalidIDToken, code: .invalidIDToken, rawValue: 309)
    testLoginError(LoginError.missingAccessToken, code: .missingAccessToken, rawValue: 310)
  }

  func testLoginErrorCreationFromNSError() {
    let error = LoginError(_nsError: .sample)
    XCTAssertIdentical(error._nsError, NSError.sample, .nsErrorSource)
    XCTAssertEqual(error.errorCode, .sampleErrorCode, .usesNSErrorCode)
    XCTAssertEqual(error.errorUserInfo[.userInfoStringKey] as? String, .userInfoValue, .usesNSErrorUserInfo)
  }

  func testLoginErrorCreationFromCode() {
    let error = LoginError(.missingAccessToken)
    XCTAssertEqual(error.errorCode, LoginError.Code.missingAccessToken.rawValue, .usesCode)
  }

  func testLoginErrorCreationFromCodeAndUserInfo() {
    let error = LoginError(.missingAccessToken, userInfo: .sample)
    XCTAssertEqual(error.errorCode, LoginError.Code.missingAccessToken.rawValue, .usesCode)
    XCTAssertEqual(error.errorUserInfo[.userInfoStringKey] as? String, .userInfoValue, .usesUserInfo)
  }

  func testDeviceLoginErrorCodes() {
    testDeviceLoginError(DeviceLoginError.excessivePolling, code: .excessivePolling, rawValue: 1349172)
    testDeviceLoginError(DeviceLoginError.authorizationDeclined, code: .authorizationDeclined, rawValue: 1349173)
    testDeviceLoginError(DeviceLoginError.authorizationPending, code: .authorizationPending, rawValue: 1349174)
    testDeviceLoginError(DeviceLoginError.codeExpired, code: .codeExpired, rawValue: 1349152)
  }

  func testDeviceLoginErrorCreationFromNSError() {
    let error = DeviceLoginError(_nsError: .sample)
    XCTAssertIdentical(error._nsError, NSError.sample, .nsErrorSource)
    XCTAssertEqual(error.errorCode, .sampleErrorCode, .usesNSErrorCode)
    XCTAssertEqual(error.errorUserInfo[.userInfoStringKey] as? String, .userInfoValue, .usesNSErrorUserInfo)
  }

  func testDeviceLoginErrorCreationFromCode() {
    let error = DeviceLoginError(.authorizationPending)
    XCTAssertEqual(error.errorCode, DeviceLoginError.Code.authorizationPending.rawValue, .usesCode)
  }

  func testDeviceLoginErrorCreationFromCodeAndUserInfo() {
    let error = DeviceLoginError(.authorizationPending, userInfo: .sample)
    XCTAssertEqual(error.errorCode, DeviceLoginError.Code.authorizationPending.rawValue, .usesCode)
    XCTAssertEqual(error.errorUserInfo[.userInfoStringKey] as? String, .userInfoValue, .usesUserInfo)
  }

  // MARK: - Helpers

  private func testLoginError(
    _ member: LoginError.Code,
    code: LoginError.Code,
    rawValue: LoginError.Code.RawValue,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertEqual(code.rawValue, rawValue, .loginErrorCode(code, rawValue: rawValue), file: file, line: line)
    XCTAssertEqual(member, code, .loginErrorMember(member, code: code), file: file, line: line)
  }

  private func testDeviceLoginError(
    _ member: DeviceLoginError.Code,
    code: DeviceLoginError.Code,
    rawValue: DeviceLoginError.Code.RawValue,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertEqual(code.rawValue, rawValue, .deviceLoginErrorCode(code, rawValue: rawValue), file: file, line: line)
    XCTAssertEqual(member, code, .deviceLoginErrorMember(member, code: code), file: file, line: line)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let domain = "The LoginErrorDomain is 'com.facebook.sdk.login'"
  static let domainInLoginError = "The LoginError error domain should is equal to LoginErrorDomain"
  static let domainInDeviceLoginError = "The DeviceLoginError error domain should is equal to LoginErrorDomain"

  static let nsErrorSource = "A custom error created with an NSError keeps the NSError"
  static let usesNSErrorCode = "Creating a custom error with an NSError uses the NSError's code"
  static let usesNSErrorUserInfo = "Creating a custom error with an NSError uses the NSError's user info values"
  static let usesCode = "Creating a custom error a code uses that code"
  static let usesUserInfo = "Creating a custom error with user info values uses those values"

  static func loginErrorCode(_ code: LoginError.Code, rawValue: LoginError.Code.RawValue) -> String {
    "The \(String(describing: code)) login error code has a raw value of \(rawValue)"
  }

  static func loginErrorMember(_ member: LoginError.Code, code: LoginError.Code) -> String {
    "LoginError has a member with a code equal to \(String(describing: code))"
  }

  static func deviceLoginErrorCode(_ code: DeviceLoginError.Code, rawValue: DeviceLoginError.Code.RawValue) -> String {
    "The \(String(describing: code)) device login error code has a raw value of \(rawValue)"
  }

  static func deviceLoginErrorMember(_ member: DeviceLoginError.Code, code: DeviceLoginError.Code) -> String {
    "DeviceLoginError has a member with a code equal to \(String(describing: code))"
  }
}

// MARK: - Test Values

fileprivate extension NSError {
  static let sample = NSError(domain: .sampleErrorDomain, code: .sampleErrorCode, userInfo: .sample)
}

fileprivate extension String {
  static let sampleErrorDomain = "THIS IS IGNORED"
  static let userInfoStringKey = "string"
  static let userInfoIntegerKey = "integer"
  static let userInfoValue = "sample string"
}

fileprivate extension Int {
  static let sampleErrorCode = 12_345_678
  static let userInfoValue = 1234
}

fileprivate extension Dictionary where Key == String, Value == Any {
  static var sample: Self {
    [
      .userInfoStringKey: String.userInfoValue,
      .userInfoIntegerKey: Int.userInfoValue,
    ]
  }
}
