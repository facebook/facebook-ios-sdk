/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import TestTools
import XCTest

final class LoginManagerLoggerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var loginManagerLogger: _LoginManagerLogger!
  var eventLogger: TestLoginEventLogger!
  // swiftlint:enable implicitly_unwrapped_optional

  let validParameters = [
    "state": "{\"challenge\":\"ibUuyvhzJW36TvC7BBYpasPHrXk%3D\",\"0_auth_logger_id\":\"A48F8D79-F2DF-4E04-B893-B29879A9A37B\",\"com.facebook.sdk_client_state\":true,\"3_method\":\"sfvc_auth\"}", // swiftlint:disable:this line_length
  ]

  override func setUp() {
    super.setUp()
    eventLogger = TestLoginEventLogger()
    loginManagerLogger = _LoginManagerLogger(loggingToken: "123", tracking: .enabled)
    _LoginManagerLogger.setDependencies(.init(eventLogger: eventLogger))
  }

  override func tearDown() {
    eventLogger = nil
    loginManagerLogger = nil
    _LoginManagerLogger.resetDependencies()
    super.tearDown()
  }

  func testDefaultTypeDependencies() throws {
    _LoginManagerLogger.resetDependencies()
    let dependencies = try _LoginManagerLogger.getDependencies()

    XCTAssertIdentical(
      dependencies.eventLogger,
      AppEvents.shared,
      .defaultDependency("the shared AppEvents", for: "event logging")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try _LoginManagerLogger.getDependencies()

    XCTAssertIdentical(
      dependencies.eventLogger,
      eventLogger,
      .customDependency(for: "event logging")
    )
  }

  func testCreatingWithMissingParametersWithTrackingEnabled() {
    XCTAssertNil(
      _LoginManagerLogger(
        parameters: nil,
        tracking: .enabled
      ),
      "Should not create a logger with missing parameters"
    )
  }

  func testCreatingWithEmptyParametersWithTrackingEnabled() {
    XCTAssertNil(
      _LoginManagerLogger(
        parameters: [:],
        tracking: .enabled
      ),
      "Should not create a logger with empty parameters"
    )
  }

  func testCreatingWithParametersWithTrackingEnabled() {
    XCTAssertNotNil(
      _LoginManagerLogger(
        parameters: validParameters,
        tracking: .enabled
      ),
      "Should create a logger with valid parameters and tracking enabled"
    )
  }

  func testCreatingWithMissingParametersWithTrackingLimited() {
    XCTAssertNil(
      _LoginManagerLogger(
        parameters: nil,
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testCreatingWithEmptyParametersWithTrackingLimited() {
    XCTAssertNil(
      _LoginManagerLogger(
        parameters: [:],
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testCreatingWithParametersWithTrackingLimited() {
    XCTAssertNil(
      _LoginManagerLogger(
        parameters: validParameters,
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testInitializingWithMissingLoggingTokenWithTrackingEnabled() {
    XCTAssertNotNil(
      _LoginManagerLogger(
        loggingToken: nil,
        tracking: .enabled
      ),
      "Shouldn't create a logger with a missing logging token but it will"
    )
  }

  func testInitializingloggingTokenWithTrackingEnabled() {
    XCTAssertNotNil(
      _LoginManagerLogger(
        loggingToken: "123",
        tracking: .enabled
      ),
      "Should create a logger with a logging token"
    )
  }

  func testInitializingWithMissingLoggingTokenWithTrackingLimited() {
    XCTAssertNil(
      _LoginManagerLogger(
        loggingToken: nil,
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testInitializingWithLoggingTokenWithTrackingLimited() {
    XCTAssertNil(
      _LoginManagerLogger(
        loggingToken: "123",
        tracking: .limited
      ),
      "Should not create a logger with limited tracking"
    )
  }

  func testStartingSessionForLoginManager() throws {
    let loginManager = LoginManager(defaultAudience: .friends)
    loginManager.setRequestedPermissions(["user_friends"])
    loginManagerLogger.startSession(for: loginManager)

    validateCommonEventLoggingParameters()
    try validateEmptyResult()

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(rawValue: "fb_mobile_login_start"),
      .logsEventName
    )

    let extras = try XCTUnwrap(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "6_extras")] as? String,
      .containsExtraParameters
    )

    let data = try XCTUnwrap(extras.data(using: .utf16), .containsExtraParameters)
    let loginExtraParameters = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any],
      .containsExtraParameters
    )

    XCTAssertEqual(
      "FBSDKLoginBehaviorBrowser",
      loginExtraParameters["login_behavior"] as? String,
      .containsExtraParameters
    )
    XCTAssertEqual("friends", loginExtraParameters["default_audience"] as? String, .containsExtraParameters)
    XCTAssertEqual(false, loginExtraParameters["tryFBAppAuth"] as? Bool, .containsExtraParameters)
    XCTAssertEqual(true, loginExtraParameters["trySafariAuth"] as? Bool, .containsExtraParameters)
    XCTAssertEqual("user_friends", loginExtraParameters["permissions"] as? String, .containsPermissions)
  }

  func testEndingSession() throws {
    loginManagerLogger.endSession()

    validateCommonEventLoggingParameters()
    try validateEmptyExtraParameters()
    try validateEmptyResult()

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(rawValue: "fb_mobile_login_complete"),
      .logsEventName
    )
  }

  func testStartingAuthMethodAppLink() throws {
    try testAuthMethod("applink_auth")
  }

  func testStartingAuthMethodSafari() throws {
    try testAuthMethod("sfvc_auth")
  }

  func testStartingAuthMethodBrowser() throws {
    try testAuthMethod("browser_auth")
  }

  func testStartingAuthMethodNative() throws {
    try testAuthMethod("fb_application_web_auth")
  }

  func testEndingLoginWithSuccessResult() throws {
    let granted = Set<String>()
    let declined = Set<String>()
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: SampleAuthenticationToken.validToken,
      isCancelled: false,
      grantedPermissions: granted,
      declinedPermissions: declined
    )
    loginManagerLogger.endLogin(with: result, error: nil)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(rawValue: "fb_mobile_login_method_complete"),
      .logsEventName
    )

    validateCommonEventLoggingParameters()
    try validateEmptyExtraParameters()

    XCTAssertEqual(
      "success",
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "2_result")] as? String,
      .containsSuccessfulResult
    )
  }

  func testEndingLoginWithSuccessResultWithDeclinedPermissions() throws {
    let granted = Set(SampleAccessTokens.validToken.permissions.map { $0.name })
    let declined: Set = ["email"]
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: SampleAuthenticationToken.validToken,
      isCancelled: false,
      grantedPermissions: granted,
      declinedPermissions: declined
    )
    loginManagerLogger.endLogin(with: result, error: nil)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(rawValue: "fb_mobile_login_method_complete"),
      .logsEventName
    )

    validateCommonEventLoggingParameters()

    XCTAssertEqual(
      "success",
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "2_result")] as? String,
      .containsSuccessfulResult
    )

    let extras = try XCTUnwrap(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "6_extras")] as? String,
      .containsExtraParameters
    )

    let data = try XCTUnwrap(extras.data(using: .utf16), .containsExtraParameters)
    let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], .containsExtraParameters)
    XCTAssertEqual("email", dict["declined_permissions"] as? String, .containsDeclinePermissions)
  }

  func testEndingLoginWithCancelledResult() throws {
    let granted = Set(SampleAccessTokens.validToken.permissions.map { $0.name })
    let declined = Set(SampleAccessTokens.validToken.declinedPermissions.map { $0.name })
    let result = LoginManagerLoginResult(
      token: SampleAccessTokens.validToken,
      authenticationToken: SampleAuthenticationToken.validToken,
      isCancelled: true,
      grantedPermissions: granted,
      declinedPermissions: declined
    )

    loginManagerLogger.endLogin(with: result, error: nil)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(rawValue: "fb_mobile_login_method_complete"),
      .logsEventName
    )

    validateCommonEventLoggingParameters()
    try validateEmptyExtraParameters()

    XCTAssertEqual(
      "cancelled",
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "2_result")] as? String,
      .containsCanceledResult
    )
  }

  func testEndingLoginWithError() throws {
    let errorDomain = "testingDomain"
    let errorCode = -1
    let error = NSError(domain: errorDomain, code: errorCode)
    loginManagerLogger.endLogin(with: nil, error: error)

    XCTAssertEqual(eventLogger.capturedEventName, AppEvents.Name(rawValue: "fb_mobile_login_method_complete"))
    try validateEmptyExtraParameters()

    XCTAssertEqual(
      "error",
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "2_result")] as? String,
      .containsErrorResult
    )
    XCTAssertEqual(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "4_error_code")] as? Int,
      errorCode,
      .containsErrorCode
    )
    XCTAssertEqual(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "5_error_message")] as? String,
      "The operation couldn’t be completed. (\(errorDomain) error \(errorCode).)",
      .containsErrorMessage
    )
  }

  func testPostingLoginHeartbeat() throws {
    loginManagerLogger.postLoginHeartbeat()
    XCTAssertNil(eventLogger.capturedEventName, .doesNotLogEventName)

    let expectation = expectation(description: "post login heart beat")
    _ = XCTWaiter.wait(for: [expectation], timeout: 6.0)
    XCTAssertEqual(eventLogger.capturedEventName, AppEvents.Name(rawValue: "fb_mobile_login_heartbeat"))
    validateCommonEventLoggingParameters()
    try validateEmptyExtraParameters()
  }

  func testClientStateForAuthMethodWithNoExistingState() throws {
    let clientStateString = _LoginManagerLogger.clientStateFor(
      authMethod: "sfvc_auth",
      andExistingState: nil,
      logger: loginManagerLogger
    )

    let identifier = try XCTUnwrap(loginManagerLogger.identifier, .formatsClientState)
    let expectedClientState: [String: Any] = [
      "com.facebook.sdk_client_state": true,
      "3_method": "sfvc_auth",
      "0_auth_logger_id": "\(identifier)",
    ]

    let clientState = try XCTUnwrap(clientStateString, .formatsClientState)
    let data = try XCTUnwrap(clientState.data(using: .utf16), .formatsClientState)
    let clientStateDict = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], .formatsClientState)
    XCTAssertEqual(expectedClientState as NSDictionary, clientStateDict as NSDictionary, .formatsClientState)
  }

  func testClientStateForAuthMethodWithExistingState() throws {
    let existingState = ["challenge": "ibUuyvhzJW36TvC7BBYpasPHrXk%3D"]
    let clientStateString = _LoginManagerLogger.clientStateFor(
      authMethod: "sfvc_auth",
      andExistingState: existingState,
      logger: loginManagerLogger
    )

    let clientState = try XCTUnwrap(clientStateString, .formatsClientState)
    let identifier = try XCTUnwrap(loginManagerLogger.identifier, .formatsClientState)

    let expectedDict: [String: Any] = [
      "challenge": "ibUuyvhzJW36TvC7BBYpasPHrXk%3D",
      "com.facebook.sdk_client_state": true,
      "3_method": "sfvc_auth",
      "0_auth_logger_id": "\(identifier)",
    ]
    let data = try XCTUnwrap(clientState.data(using: .utf16), .formatsClientState)
    let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], .formatsClientState)
    XCTAssertEqual(expectedDict as NSDictionary, dict as NSDictionary, .formatsClientState)
  }

  // MARK: - Helpers

  func testAuthMethod(_ method: String) throws {
    loginManagerLogger.startWith(authMethod: method)

    validateCommonEventLoggingParameters()
    try validateEmptyExtraParameters()
    try validateEmptyResult()

    XCTAssertEqual(
      method,
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "3_method")] as? String,
      .containsAuthMethod
    )
    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name(rawValue: "fb_mobile_login_method_start"),
      .logsEventName
    )
  }

  func validateCommonEventLoggingParameters() {
    XCTAssertEqual(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "7_logging_token")] as? String,
      "123",
      .containsLoggingToken
    )
    XCTAssertEqual(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "0_auth_logger_id")] as? String,
      loginManagerLogger.identifier,
      .containsAuthId
    )
    XCTAssertEqual(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "4_error_code")] as? String,
      "",
      .doesNotContainErrorCode
    )
    XCTAssertEqual(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "5_error_message")] as? String,
      "",
      .doesNotContainErrorMessage
    )
  }

  func validateEmptyExtraParameters() throws {
    let extras = try XCTUnwrap(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "6_extras")] as? String,
      .doesNotContainExtraParameters
    )

    let data = try XCTUnwrap(extras.data(using: .utf16), .doesNotContainExtraParameters)
    let dict = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any],
      .doesNotContainExtraParameters
    )

    XCTAssertTrue(dict.isEmpty, .doesNotContainExtraParameters)
  }

  func validateEmptyResult() throws {
    let result = try XCTUnwrap(
      eventLogger.capturedParameters?[AppEvents.ParameterName(rawValue: "2_result")] as? String,
      .doesNotContainResult
    )

    XCTAssertTrue(
      result.isEmpty,
      .doesNotContainResult
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The _LoginManagerLogger type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The _LoginManagerLogger type uses a custom \(type) dependency when provided"
  }

  static let containsLoggingToken = "logger parameters contain a logging token"
  static let containsAuthId = "logger parameters contain an auth identifier"
  static let containsAuthMethod = "logger parameters contain an auth method"
  static let containsSuccessfulResult = "logger parameters contain a successful result"
  static let containsCanceledResult = "logger parameters contain a canceled result"
  static let containsErrorResult = "logger parameters contain an error result"
  static let containsExtraParameters = "logger parameters contain extra parameters"
  static let containsErrorCode = "logger parameters contain an error code"
  static let containsErrorMessage = "logger parameters contain an error message"
  static let containsPermissions = "logger parameters contain permissions"
  static let containsDeclinePermissions = "logger parameters contain declined permissions"
  static let doesNotContainErrorCode = "logger parameters don't contain an error code"
  static let doesNotContainErrorMessage = "logger parameters don't contain an error message"
  static let doesNotContainResult = "logger parameters don't contain a result"
  static let doesNotContainExtraParameters = "logger parameters don't contain extra parameters"
  static let logsEventName = "logs the correct event name"
  static let doesNotLogEventName = "does not log an event name"
  static let formatsClientState = "a proper format for client state is returned"
}
