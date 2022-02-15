/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

final class ErrorFactoryTests: XCTestCase {

  // MARK: - Test Assumptions

  private enum Assumptions {
    static let noDefaultClassReporter = """
      The error factory type should not have a default error reporter by default
      """
    static let defaultClassReporter = """
      The error factory type should have a default error reporter
      """

    static let noDefaultInstanceReporter = """
      Should be able to create an error factory without a default error reporter
      """

    static let errorReporter = """
      An error factory should be created with the provided error reporter
      """

    static let facebookDomain = """
      An error should be created with the Facebook error domain when another \
      domain is not provided
      """
    static let providedDomain = """
      An error should be created with the provided domain
      """

    static let providedCode = """
      An error should be created with the provided code
      """
    static let invalidArgumentCode = """
      An error should be created with an invalid argument code
      """
    static let unknownCode = "An error should be created with an unknown code"

    static let nilMessage = """
      An error should be created without a message if one is not provided
      """
    static let providedMessage = """
      An error should be created with the provided message
      """
    static let invalidArgumentMessage = """
      An error should be created with a default invalid argument message
      """
    static let requiredArgumentMessage = """
      Value for \(requiredArgumentName) is required.
      """

    static let invalidArgumentName = """
      Invalid argument errors should be created with a name
      """
    static let invalidArgumentWithoutValue = """
      Invalid argument errors should be created with a nil value
      """
    static let invalidArgumentWithValue = """
      Invalid argument errors should be created with a value
      """
    static let requiredArgumentName = """
      Required argument errors should be created with a name
      """

    static let nilUnderlyingError = """
      An error should be created without an underlying error if one \
      is not provided
      """
    static let providedUnderlyingError = """
      An error should be created with the provided underlying error
      """

    static let noAdditionalUserInfo = """
      An error should be created without additional user info values if \
      they are not provided
      """
    static let additionalUserInfo = """
      An error should be created with additional user info values if \
      they are provided
      """

    static let reporting = """
      An error should be sent to the factory's error reporter
      """
    static let defaultReporting = """
      An error factory using the default error reporter should report errors
      """
  }

  // MARK: - Test Fixture

  // swiftlint:disable implicitly_unwrapped_optional
  var factory: ErrorFactory!
  var reporter: TestErrorReporter!
  var defaultReporter: TestErrorReporter!
  var error: Error!
  // swiftlint:enable implicitly_unwrapped_optional

  var nsError: NSError { error as NSError }

  override func setUp() {
    super.setUp()

    ErrorFactory.resetClassDependencies()

    reporter = TestErrorReporter()
    defaultReporter = TestErrorReporter()
    factory = ErrorFactory(reporter: reporter)
  }

  override func tearDown() {
    reporter = nil
    defaultReporter = nil
    error = nil
    factory = nil

    super.tearDown()
  }

  // MARK: - Tests

  // MARK: Dependencies

  func testClassDependencies() {
    XCTAssertNil(
      ErrorFactory.defaultReporter,
      Assumptions.noDefaultClassReporter
    )

    ErrorFactory.configure(defaultReporter: defaultReporter)

    XCTAssertIdentical(
      ErrorFactory.defaultReporter,
      defaultReporter,
      Assumptions.defaultClassReporter
    )
  }

  func testNullaryInitialization() {
    factory = ErrorFactory()

    XCTAssertNil(
      factory.reporter,
      Assumptions.noDefaultInstanceReporter
    )
  }

  func testInitializationWithDependencies() {
    XCTAssertTrue(factory.reporter === reporter, Assumptions.errorReporter)
  }

  // MARK: General Errors

  func testGeneralErrorWithOnlyCode() throws {
    error = factory.error(
      code: Values.code,
      userInfo: nil,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(nsError.code, Values.code, Assumptions.providedCode)
    XCTAssertFalse(
      nsError.userInfo.keys.contains(Values.userInfoKey),
      Assumptions.noAdditionalUserInfo
    )
    XCTAssertNil(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Assumptions.nilMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(domain: ErrorDomain, code: Values.code, message: nil)
  }

  func testGeneralErrorWithAllParameters() throws {
    error = factory.error(
      domain: Values.domain,
      code: Values.code,
      userInfo: Values.userInfo,
      message: Values.message,
      underlyingError: Values.underlyingError
    )

    XCTAssertEqual(nsError.domain, Values.domain, Assumptions.providedDomain)
    XCTAssertEqual(nsError.code, Values.code, Assumptions.providedCode)
    XCTAssertEqual(
      nsError.userInfo[Values.userInfoKey] as? String,
      Values.userInfoValue,
      Assumptions.additionalUserInfo
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Values.message,
      Assumptions.providedMessage
    )
    XCTAssertEqual(
      nsError.userInfo[NSUnderlyingErrorKey] as? UnderlyingError,
      Values.underlyingError,
      Assumptions.providedUnderlyingError
    )
    try checkReporting(
      domain: Values.domain,
      code: Values.code,
      message: Values.message
    )
  }

  // MARK: - Invalid Argument Errors

  func testInvalidArgumentErrorWithoutValue() throws {
    let argument = Argument.invalid(name: Values.argumentName, value: nil)
    error = factory.invalidArgumentError(
      name: argument.name,
      value: argument.value,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      Values.argumentName,
      Assumptions.invalidArgumentName
    )
    XCTAssertNil(
      nsError.userInfo[ErrorArgumentValueKey],
      Assumptions.invalidArgumentWithoutValue
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      argument.expectedMessage,
      Assumptions.invalidArgumentMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: argument.expectedMessage
    )
  }

  func testInvalidArgumentErrorWithValue() throws {
    let argument = Argument.invalid(
      name: Values.argumentName,
      value: Values.argumentValue
    )
    error = factory.invalidArgumentError(
      name: argument.name,
      value: argument.value,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      Values.argumentName,
      Assumptions.invalidArgumentName
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentValueKey] as? String,
      Values.argumentValue,
      Assumptions.invalidArgumentWithValue
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      argument.expectedMessage,
      Assumptions.invalidArgumentMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: argument.expectedMessage
    )
  }

  func testInvalidArgumentErrorWithAllParameters() throws {
    let argument = Argument.invalid(
      name: Values.argumentName,
      value: Values.argumentValue
    )
    error = factory.invalidArgumentError(
      domain: Values.domain,
      name: Values.argumentName,
      value: Values.argumentValue,
      message: Values.message,
      underlyingError: Values.underlyingError
    )

    XCTAssertEqual(nsError.domain, Values.domain, Assumptions.providedDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      argument.name,
      Assumptions.invalidArgumentName
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentValueKey] as? String,
      argument.value,
      Assumptions.invalidArgumentWithValue
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Values.message,
      Assumptions.providedMessage
    )
    XCTAssertEqual(
      nsError.userInfo[NSUnderlyingErrorKey] as? UnderlyingError,
      Values.underlyingError,
      Assumptions.providedUnderlyingError
    )
    try checkReporting(
      domain: Values.domain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: Values.message
    )
  }

  // MARK: - Required Argument Errors

  func testRequiredArgumentErrorWithOnlyName() throws {
    let argument = Argument.required(name: Values.argumentName)
    error = factory.requiredArgumentError(
      name: argument.name,
      message: nil,
      underlyingError: nil
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.providedCode
    )
    XCTAssertFalse(
      nsError.userInfo.keys.contains(Values.userInfoKey),
      Assumptions.noAdditionalUserInfo
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      argument.name,
      Assumptions.requiredArgumentName
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      argument.expectedMessage,
      Assumptions.requiredArgumentMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: argument.expectedMessage
    )
  }

  func testRequiredArgumentErrorWithAllParameters() throws {
    let argument = Argument.required(name: Values.argumentName)
    error = factory.requiredArgumentError(
      domain: Values.domain,
      name: argument.name,
      message: Values.message,
      underlyingError: Values.underlyingError
    )

    XCTAssertEqual(nsError.domain, Values.domain, Assumptions.providedDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorInvalidArgument.rawValue,
      Assumptions.invalidArgumentCode
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorArgumentNameKey] as? String,
      argument.name,
      Assumptions.requiredArgumentName
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Values.message,
      Assumptions.providedMessage
    )
    XCTAssertEqual(
      nsError.userInfo[NSUnderlyingErrorKey] as? UnderlyingError,
      Values.underlyingError,
      Assumptions.providedUnderlyingError
    )
    try checkReporting(
      domain: Values.domain,
      code: CoreError.errorInvalidArgument.rawValue,
      message: Values.message
    )
  }

  // MARK: - Unknown Errors

  func testUnknownErrorWithoutParameters() throws {
    error = factory.unknownError(message: nil, userInfo: nil)

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorUnknown.rawValue,
      Assumptions.unknownCode
    )
    XCTAssertFalse(
      nsError.userInfo.keys.contains(Values.userInfoKey),
      Assumptions.noAdditionalUserInfo
    )
    XCTAssertNil(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Assumptions.nilMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorUnknown.rawValue,
      message: nil
    )
  }

  func testUnknownErrorWithAllParameters() throws {
    error = factory.unknownError(
      message: Values.message,
      userInfo: Values.userInfo
    )

    XCTAssertEqual(nsError.domain, ErrorDomain, Assumptions.facebookDomain)
    XCTAssertEqual(
      nsError.code,
      CoreError.errorUnknown.rawValue,
      Assumptions.unknownCode
    )
    XCTAssertEqual(
      nsError.userInfo[Values.userInfoKey] as? String,
      Values.userInfoValue,
      Assumptions.additionalUserInfo
    )
    XCTAssertEqual(
      nsError.userInfo[ErrorDeveloperMessageKey] as? String,
      Values.message,
      Assumptions.providedMessage
    )
    XCTAssertNil(
      nsError.userInfo[NSUnderlyingErrorKey],
      Assumptions.nilUnderlyingError
    )
    try checkReporting(
      domain: ErrorDomain,
      code: CoreError.errorUnknown.rawValue,
      message: Values.message
    )
  }

  // MARK: - Using Default Reporter

  func testUsingDefaultErrorReporter() throws {
    // Creating a factory without a reporter or a default reporter
    factory = ErrorFactory()

    // Adding the default reporter after the fact
    ErrorFactory.configure(defaultReporter: defaultReporter)

    error = factory.unknownError(
      message: Values.message,
      userInfo: Values.userInfo
    )
    try checkReporting(
      reporter: defaultReporter,
      domain: ErrorDomain,
      code: CoreError.errorUnknown.rawValue,
      message: Values.message,
      assumption: Assumptions.defaultReporting
    )
  }

  // MARK: - Provided and Expected Values

  private enum Values {
    static let domain = "domain"
    static let code = 14
    static let underlyingError = UnderlyingError()
    static let message = "message"
    static let argumentName = "name"
    static let argumentValue = "value"

    static let userInfoKey = "userInfoKey"
    static let userInfoValue = "userInfoValue"
    static let userInfo: [String: Any] = [
      userInfoKey: userInfoValue,
    ]
  }

  struct UnderlyingError: Error, Equatable {}

  enum Argument {
    case invalid(name: String, value: String?)
    case required(name: String)

    var name: String {
      switch self {
      case let .invalid(name: name, _),
           let .required(name: name):
        return name
      }
    }

    var value: String? {
      switch self {
      case let .invalid(_, value: value):
        return value
      case .required:
        return nil
      }
    }

    var expectedMessage: String {
      switch self {
      case .invalid:
        return "Invalid value for \(name): \(value ?? "(null)")"
      case .required:
        return "Value for \(name) is required."
      }
    }
  }

  // MARK: - Common Validation

  private func checkReporting(
    reporter reporterToCheck: TestErrorReporter? = nil,
    domain: String,
    code: Int,
    message: String?,
    file: StaticString = #file,
    line: UInt = #line,
    assumption: String = Assumptions.reporting
  ) throws {
    let testReporter: TestErrorReporter = reporterToCheck ?? reporter

    XCTAssertEqual(
      testReporter.capturedErrorDomain,
      domain,
      assumption,
      file: file,
      line: line
    )
    XCTAssertEqual(
      testReporter.capturedErrorCode,
      code,
      assumption,
      file: file,
      line: line
    )
    XCTAssertEqual(
      testReporter.capturedMessage,
      message,
      assumption,
      file: file,
      line: line
    )
  }
}
