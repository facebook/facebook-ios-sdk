/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class LoginErrorFactoryTests: XCTestCase {

  func testErrorForErrorNetwork() throws {
    let code = try XCTUnwrap(LoginError.Code(rawValue: 4))
    let error = LoginErrorFactory.fbErrorForFailedLogin(withCode: code) as NSError

    XCTAssertEqual(error.code, 4, .errorCodeMatches)
    XCTAssertEqual(error.domain, "com.facebook.sdk.core", .errorDomainMatches)
    XCTAssertNotNil(error.userInfo["com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"], .hasValueForUserInfoKey)
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey], .hasNoValueForUserInfoKey)

    let errorDescription = try XCTUnwrap(error.userInfo["NSLocalizedDescription"] as? String, .hasValueForUserInfoKey)
    XCTAssertEqual(
      errorDescription,
      "Unable to connect to Facebook. Check your network connection and try again.",
      .matchesDescriptionError
    )
  }

  func testErrorForUserCheckpointed() throws {
    let loginError = LoginError.userCheckpointed
    let error = LoginErrorFactory.fbErrorForFailedLogin(withCode: loginError) as NSError

    XCTAssertEqual(error.code, 303, .errorCodeMatches)
    XCTAssertEqual(error.domain, "com.facebook.sdk.login", .errorDomainMatches)
    XCTAssertNotNil(error.userInfo["com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"], .hasValueForUserInfoKey)
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey], .hasNoValueForUserInfoKey)

    let errorDescription = try XCTUnwrap(error.userInfo["NSLocalizedDescription"] as? String, .hasValueForUserInfoKey)
    XCTAssertEqual(
      errorDescription,
      "You cannot log in to apps at this time. Please log in to www.facebook.com and follow the instructions given.",
      .matchesDescriptionError
    )
  }

  func testErrorForUnconfirmedUser() throws {
    let loginError = LoginError.unconfirmedUser
    let error = LoginErrorFactory.fbErrorForFailedLogin(withCode: loginError) as NSError

    XCTAssertEqual(error.code, 305, .errorCodeMatches)
    XCTAssertEqual(error.domain, "com.facebook.sdk.login", .errorDomainMatches)
    XCTAssertNotNil(error.userInfo["com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"], .hasValueForUserInfoKey)
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey], .hasNoValueForUserInfoKey)

    let errorDescription = try XCTUnwrap(error.userInfo["NSLocalizedDescription"] as? String, .hasValueForUserInfoKey)
    XCTAssertEqual(
      errorDescription,
      "Your account is not confirmed. Please log in to www.facebook.com and follow the instructions given.",
      .matchesDescriptionError
    )
  }

  func testErrorForSystemAccountAppDisabled() throws {
    let loginError = LoginError.systemAccountAppDisabled
    let error = LoginErrorFactory.fbErrorForFailedLogin(withCode: loginError) as NSError

    XCTAssertEqual(error.code, 306, .errorCodeMatches)
    XCTAssertEqual(error.domain, "com.facebook.sdk.login", .errorDomainMatches)
    XCTAssertNotNil(error.userInfo["com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"], .hasValueForUserInfoKey)
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey], .hasNoValueForUserInfoKey)

    let errorDescription = try XCTUnwrap(error.userInfo["NSLocalizedDescription"] as? String, .hasValueForUserInfoKey)
    XCTAssertEqual(
      errorDescription,
      "Access has not been granted to the Facebook account. Verify device settings.",
      .matchesDescriptionError
    )
  }

  func testErrorForSystemAccountUnavailable() throws {
    let loginError = LoginError.systemAccountUnavailable
    let error = LoginErrorFactory.fbErrorForFailedLogin(withCode: loginError) as NSError

    XCTAssertEqual(error.code, 307, .errorCodeMatches)
    XCTAssertEqual(error.domain, "com.facebook.sdk.login", .errorDomainMatches)
    XCTAssertNotNil(error.userInfo["com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"], .hasValueForUserInfoKey)
    XCTAssertNil(error.userInfo[NSUnderlyingErrorKey], .hasNoValueForUserInfoKey)

    let errorDescription = try XCTUnwrap(error.userInfo["NSLocalizedDescription"] as? String, .hasValueForUserInfoKey)
    XCTAssertEqual(
      errorDescription,
      "The Facebook account has not been configured on the device.",
      .matchesDescriptionError
    )
  }

  func testErrorFromReturnURLParametersWithEmptyParameters() throws {
    let parameters = [String: Any]()
    let error = LoginErrorFactory.fbError(fromReturnURLParameters: parameters)

    XCTAssertNil(error, .noErrorForEmptyParameters)
  }

  func testErrorFromReturnURLParametersWithParameters() throws {
    let parameters = ["error_message": "foo"]
    let returnedError = try XCTUnwrap(
      LoginErrorFactory.fbError(fromReturnURLParameters: parameters),
      .errorForParameters
    )
    let error = try XCTUnwrap(returnedError as NSError, .errorForParameters)

    XCTAssertEqual(error.code, 8, .errorCodeMatches)
    XCTAssertEqual(error.domain, "com.facebook.sdk.core", .errorDomainMatches)
    XCTAssertFalse(error.userInfo.isEmpty, .hasNoValuesForUserInfo)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let noErrorForEmptyParameters = "No error is returned if empty parameters are passed"
  static let errorForParameters = "An error is returned if some parameters are passed"
  static let errorCodeMatches = "The returned error code matches the error code passed"
  static let errorDomainMatches = "The returned error domain matches the expected domain"
  static let hasValueForUserInfoKey = "User info contains a value for the given key"
  static let hasNoValueForUserInfoKey = "User info does not contain a value for the given key"
  static let hasNoValuesForUserInfo = "User info does not contain any values"
  static let matchesDescriptionError = "The returned error description matches the localized error description"
}
