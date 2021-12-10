/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

class SDKErrorTests: XCTestCase {

  let errorReporter = TestErrorReporter()
  let code = Int.random(in: 1...500)
  let defaultDomain = "com.facebook.sdk.core"
  let customDomain = "foo"
  let userInfo = ["some": "info"]
  let invalidArgumentErrorCode = 2
  lazy var underlyingErrorWithUserInfo = createNSError(withCode: code)
  lazy var underlyingErrorWithoutUserInfo = createNSError(withCode: code, userInfo: [:])
  lazy var underlyingErrorUsingProvidedUserInfo = createNSError(withCode: code, userInfo: userInfo)

  enum Assertions {
    static let code = "Creating an error should report the expected error code"
    static let domain = "Creating an error should report the expected error domain"
    static let message = "Creating an error should report the expected error message"
  }

  override class func setUp() {
    super.setUp()

    SDKError.reset()
  }

  override func setUp() {
    super.setUp()

    SDKError.configureWithErrorReporter(errorReporter)
  }

  override func tearDown() {
    SDKError.reset()

    super.tearDown()
  }

  func testDefaultErrorReporter() {
    SDKError.reset()

    XCTAssertNil(
      SDKError.errorReporter,
      "Should not have an error reporter by default"
    )
  }

  // MARK: - Error Creation

  func testErrorWithCodeMessage() {
    SDKError.error(withCode: code, message: name)

    XCTAssertEqual(errorReporter.capturedErrorCode, code, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, defaultDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)
  }

  func testErrorWithDomainCodeMessage() {
    SDKError.error(withDomain: customDomain, code: code, message: name)

    XCTAssertEqual(errorReporter.capturedErrorCode, code, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, customDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)
  }

  func testErrorWithCodeMessageAndUnderlyingErrorWithUserInfo() {
    let error = SDKError.error(
      withCode: code,
      message: name,
      underlyingError: underlyingErrorWithUserInfo
    ) as NSError

    XCTAssertEqual(errorReporter.capturedErrorCode, code, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, defaultDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)

    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      name,
      "The returned error should contain the message from the SDK error"
    )
    XCTAssertEqual(
      error.userInfo["NSUnderlyingError"] as? NSError,
      underlyingErrorWithUserInfo,
      "The returned error should include the underlying error in its user info"
    )
  }

  func testErrorWithCodeMessageAndUnderlyingErrorWithoutUserInfo() {
    let error = SDKError.error(
      withCode: code,
      message: name,
      underlyingError: underlyingErrorWithoutUserInfo
    ) as NSError

    XCTAssertEqual(errorReporter.capturedErrorCode, code, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, defaultDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)

    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      name,
      "The returned error should contain the message from the SDK error"
    )
    XCTAssertEqual(
      error.userInfo["NSUnderlyingError"] as? NSError,
      underlyingErrorWithoutUserInfo,
      "The returned error should include the underlying error in its user info"
    )
  }

  func testErrorWithDomainCodeMessageAndUnderlyingError() {
    let error = SDKError.error(
      withDomain: customDomain,
      code: code,
      message: name,
      underlyingError: underlyingErrorWithoutUserInfo
    ) as NSError

    XCTAssertEqual(errorReporter.capturedErrorCode, code, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, customDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)

    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      name,
      "The returned error should contain the message from the SDK error"
    )
    XCTAssertEqual(
      error.userInfo["NSUnderlyingError"] as? NSError,
      underlyingErrorWithoutUserInfo,
      "The returned error should include the underlying error in its user info"
    )
  }

  func testInvalidArgumentErrorWithNameValueMessage() {
    let error = SDKError.invalidArgumentError(withName: "foo", value: "bar", message: name) as NSError

    XCTAssertEqual(errorReporter.capturedErrorCode, invalidArgumentErrorCode, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, defaultDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)

    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      name,
      "The returned error should contain the message from the SDK error"
    )
    XCTAssertEqual(
      error.userInfo[ErrorArgumentNameKey] as? String,
      "foo",
      "The returned error should contain the invalid argument name"
    )
    XCTAssertEqual(
      error.userInfo[ErrorArgumentValueKey] as? String,
      "bar",
      "The returned error should contain the invalid argument value"
    )
  }

  func testRequiredArgumentErrorWithDomainNameMessage() {
    let error = SDKError.requiredArgumentError(
      withDomain: customDomain,
      name: "foo",
      message: name
    ) as NSError

    XCTAssertEqual(errorReporter.capturedErrorCode, invalidArgumentErrorCode, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, customDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)

    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      name,
      "The returned error should contain the message from the SDK error"
    )
    XCTAssertEqual(
      error.userInfo[ErrorArgumentNameKey] as? String,
      "foo",
      "The returned error should contain the invalid argument name"
    )
  }

  func testUnknownError() {
    let error = SDKError.unknownError(withMessage: name) as NSError

    XCTAssertEqual(errorReporter.capturedErrorCode, CoreError.errorUnknown.rawValue, Assertions.code)
    XCTAssertEqual(errorReporter.capturedErrorDomain, defaultDomain, Assertions.domain)
    XCTAssertEqual(errorReporter.capturedMessage, name, Assertions.message)

    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      name,
      "The returned error should contain the message from the SDK error"
    )
  }

  func testIsNetworkError() {
    let errorCodes = [
      NSURLErrorTimedOut,
      NSURLErrorCannotFindHost,
      NSURLErrorCannotConnectToHost,
      NSURLErrorNetworkConnectionLost,
      NSURLErrorDNSLookupFailed,
      NSURLErrorNotConnectedToInternet,
      NSURLErrorInternationalRoamingOff,
      NSURLErrorCallIsActive,
      NSURLErrorDataNotAllowed
    ]
    errorCodes.forEach { errorCode in
      let error = createNSError(withCode: errorCode)
      XCTAssertTrue(SDKError.isNetworkError(error))
    }

    errorCodes.forEach { errorCode in
      let underlyingError = createNSError(withCode: errorCode)
      let error = createNSError(
        withCode: errorCode,
        userInfo: [NSUnderlyingErrorKey: underlyingError]
      )

      XCTAssertTrue(SDKError.isNetworkError(error))
    }
  }

  // MARK: - Helpers

  func createNSError(
    withCode code: Int,
    userInfo: [String: Any] = ["foo": "bar"]
  ) -> NSError {
    NSError(domain: "sample.ns.error", code: code, userInfo: userInfo)
  }
}
