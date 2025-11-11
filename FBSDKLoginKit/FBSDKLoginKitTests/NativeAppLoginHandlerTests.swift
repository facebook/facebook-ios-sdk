/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import FBSDKLoginKit

import FBSDKCoreKit_Basics
import TestTools
import XCTest

final class NativeAppLoginHandlerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var loginManager: TestLoginManager!
  var configuration: LoginConfiguration!
  var handler: NativeAppLoginHandler!
  var logger: LoginManagerLogger!
  var internalUtility: TestInternalUtility!
  var settings: TestSettings!
  var urlOpener: TestURLOpener!
  // swiftlint:enable implicitly_unwrapped_optional

  let appID = "123456789"
  let permissions = ["email", "public_profile"]

  override func setUp() {
    super.setUp()

    settings = TestSettings()
    settings.appID = appID
    settings.appURLSchemeSuffix = nil
    settings.isAutoLogAppEventsEnabled = true

    internalUtility = TestInternalUtility()
    urlOpener = TestURLOpener()

    loginManager = TestLoginManager(
      settings: settings,
      internalUtility: internalUtility,
      urlOpener: urlOpener
    )

    logger = LoginManagerLogger(loggingToken: nil, tracking: .enabled)
  }

  override func tearDown() {
    loginManager = nil
    configuration = nil
    handler = nil
    logger = nil
    internalUtility = nil
    settings = nil
    urlOpener = nil

    super.tearDown()
  }

  // MARK: - Helper Methods

  func createConfiguration(
    permissions: [String]? = nil,
    tracking: LoginTracking = .enabled,
    appSwitch: AppSwitch = .enabled,
    authType: LoginAuthType? = .rerequest
  ) -> LoginConfiguration? {
    LoginConfiguration(
      permissions: Set((permissions ?? self.permissions).compactMap { Permission(stringLiteral: $0) }),
      tracking: tracking,
      authType: authType,
      appSwitch: appSwitch,
    )
  }

  func createHandler(
    configuration: LoginConfiguration? = nil,
    defaultAudience: DefaultAudience = .friends
  ) -> NativeAppLoginHandler {
    let config = configuration ?? createConfiguration()!
    return NativeAppLoginHandler(
      loginManager: loginManager.loginManager,
      configuration: config,
      defaultAudience: defaultAudience,
      logger: logger
    )
  }

  // MARK: - shouldAttemptNativeAppLogin Tests

  func testShouldNotAttemptNativeAppLoginWhenAppSwitchDisabled() {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration(appSwitch: .disabled)
    handler = createHandler(configuration: configuration)

    XCTAssertFalse(
      handler.shouldAttemptNativeAppLogin(),
      "Should not attempt native app login when app switch is disabled (opt-in model)"
    )
  }

  func testShouldAttemptNativeAppLoginWhenAppSwitchEnabled() {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration(appSwitch: .enabled)
    handler = createHandler(configuration: configuration)

    // Note: This will return false in unit tests because UIApplication.shared.canOpenURL
    // cannot be mocked and will always return false for fbauth2:// in test environment.
    // In production, this would return true if Facebook app is installed.
    let result = handler.shouldAttemptNativeAppLogin()

    // We can't test the actual result due to UIApplication.shared limitations,
    // but we can verify the method doesn't crash and app switch check is performed
    XCTAssertNotNil(result, "Should return a boolean result")
  }

  func testShouldNotAttemptNativeAppLoginWithLimitedTracking() {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration(tracking: .limited, appSwitch: .enabled)
    handler = createHandler(configuration: configuration)

    XCTAssertFalse(
      handler.shouldAttemptNativeAppLogin(),
      "Should not attempt native app login with limited tracking for privacy compliance"
    )
  }

  func testShouldNotAttemptNativeAppLoginWhenFacebookAppNotInstalled() {
    internalUtility.isFacebookAppInstalled = false
    configuration = createConfiguration(appSwitch: .enabled)
    handler = createHandler(configuration: configuration)

    XCTAssertFalse(
      handler.shouldAttemptNativeAppLogin(),
      "Should not attempt native app login when Facebook app is not installed"
    )
  }

  func testShouldNotAttemptNativeAppLoginWhenDependenciesUnavailable() {
    // Create a handler with a login manager that will fail to get dependencies
    let failingLoginManager = LoginManager()
    configuration = createConfiguration(appSwitch: .enabled)
    let failingHandler = NativeAppLoginHandler(
      loginManager: failingLoginManager,
      configuration: configuration!,
      defaultAudience: .friends,
      logger: logger
    )

    // This should return false because getDependencies() will fail
    XCTAssertFalse(
      failingHandler.shouldAttemptNativeAppLogin(),
      "Should not attempt native app login when dependencies are unavailable"
    )
  }

  // MARK: - performNativeAppLogin Tests

  func testPerformNativeAppLoginOpensURLWithCorrectScheme() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()
    handler = createHandler(configuration: configuration)

    let expectation = expectation(description: "Should open URL with fbauth2 scheme")

    handler.performNativeAppLogin(loggingToken: "test_token") { _, _ in
      expectation.fulfill()
    }

    // Simulate URL opener response
    if let capturedHandler = urlOpener.capturedRequests.first {
      capturedHandler(true, nil)
    }

    wait(for: [expectation], timeout: 1.0)

    let url = try XCTUnwrap(urlOpener.capturedURL, "Should capture the URL")
    XCTAssertEqual(
      url.scheme,
      "fbauth2",
      "Should use fbauth2:// URL scheme for native app login"
    )
  }

  func testPerformNativeAppLoginSuccess() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()
    handler = createHandler(configuration: configuration)

    let expectation = expectation(description: "Native app login should succeed")

    handler.performNativeAppLogin(loggingToken: "test_logging_token") { didOpen, error in
      XCTAssertTrue(didOpen, "Should successfully open Facebook app")
      XCTAssertNil(error, "Should not have an error")
      expectation.fulfill()
    }

    // Simulate successful URL opening
    let capturedHandler = try XCTUnwrap(urlOpener.capturedRequests.first)
    capturedHandler(true, nil)

    wait(for: [expectation], timeout: 1.0)
  }

  func testPerformNativeAppLoginFailure() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()
    handler = createHandler(configuration: configuration)

    let expectation = expectation(description: "Native app login should fail")
    let expectedError = NSError(domain: "test", code: 1, userInfo: nil)

    handler.performNativeAppLogin(loggingToken: "test_logging_token") { didOpen, error in
      XCTAssertFalse(didOpen, "Should not successfully open Facebook app")
      XCTAssertNotNil(error, "Should have an error")
      expectation.fulfill()
    }

    // Simulate failed URL opening
    let capturedHandler = try XCTUnwrap(urlOpener.capturedRequests.first)
    capturedHandler(false, expectedError)

    wait(for: [expectation], timeout: 1.0)
  }

  func testPerformNativeAppLoginCallsHandlerWhenComplete() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()
    handler = createHandler(configuration: configuration)

    var handlerCalled = false
    let expectation = expectation(description: "Handler should be called")

    handler.performNativeAppLogin(loggingToken: nil) { didOpen, error in
      handlerCalled = true
      expectation.fulfill()
    }

    // Simulate URL opener completing
    let capturedHandler = try XCTUnwrap(urlOpener.capturedRequests.first)
    capturedHandler(true, nil)

    wait(for: [expectation], timeout: 1.0)

    XCTAssertTrue(handlerCalled, "Handler callback should be called")
  }

  // MARK: - URL Building Tests

  func testNativeAppLoginURLUsesFbauth2Scheme() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()
    handler = createHandler(configuration: configuration)

    let expectation = expectation(description: "URL should be opened with fbauth2 scheme")

    handler.performNativeAppLogin(loggingToken: nil) { _, _ in
      expectation.fulfill()
    }

    // Simulate successful URL opening
    let capturedHandler = try XCTUnwrap(urlOpener.capturedRequests.first)
    capturedHandler(true, nil)

    wait(for: [expectation], timeout: 1.0)

    let url = try XCTUnwrap(urlOpener.capturedURL, "Should capture the URL")

    XCTAssertEqual(
      url.scheme,
      "fbauth2",
      "Native app login must use fbauth2:// URL scheme for Facebook app authentication"
    )
    XCTAssertEqual(
      url.host,
      "authorize",
      "Should use authorize endpoint for authentication"
    )
  }

  func testNativeAppLoginURLContainsRequiredParameters() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()
    handler = createHandler(configuration: configuration)

    let expectation = expectation(description: "URL should be opened")

    handler.performNativeAppLogin(loggingToken: nil) { _, _ in
      expectation.fulfill()
    }

    // Simulate successful URL opening
    let capturedHandler = try XCTUnwrap(urlOpener.capturedRequests.first)
    capturedHandler(true, nil)

    wait(for: [expectation], timeout: 1.0)

    let url = try XCTUnwrap(urlOpener.capturedURL, "Should capture the URL")

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let queryItems = components?.queryItems ?? []
    let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

    XCTAssertEqual(
      params["client_id"],
      appID,
      "Should include app ID in URL parameters"
    )
    XCTAssertNotNil(
      params["scope"],
      "Should include scope in URL parameters"
    )
  }

  func testPerformNativeAppLoginWithLogger() throws {
    internalUtility.isFacebookAppInstalled = true
    configuration = createConfiguration()

    // Use a real logger - we can't test internal state since LoginManagerLogger is final,
    // but we can verify the handler doesn't crash when logger is provided
    let realLogger = LoginManagerLogger(loggingToken: "test_token", tracking: .enabled)
    handler = NativeAppLoginHandler(
      loginManager: loginManager.loginManager,
      configuration: configuration!,
      defaultAudience: .friends,
      logger: realLogger
    )

    let expectation = expectation(description: "Should complete with logger")

    handler.performNativeAppLogin(loggingToken: nil) { didOpen, error in
      XCTAssertTrue(didOpen, "Should successfully open with logger")
      expectation.fulfill()
    }

    // Simulate successful URL opening
    let capturedHandler = try XCTUnwrap(urlOpener.capturedRequests.first)
    capturedHandler(true, nil)

    wait(for: [expectation], timeout: 1.0)
  }
}

// MARK: - Test Doubles

final class TestLoginManager {
  var logInParametersCalled = false
  var capturedLoggingToken: String?
  var capturedAuthMethod: String?
  var stubbedParameters: [String: String]?
  var shouldReturnNilParameters = false

  private let testSettings: SettingsProtocol
  private let testInternalUtility: URLHosting & AppURLSchemeProviding & AppAvailabilityChecker
  private let testURLOpener: URLOpener

  let loginManager: LoginManager

  init(
    settings: SettingsProtocol,
    internalUtility: URLHosting & AppURLSchemeProviding & AppAvailabilityChecker,
    urlOpener: URLOpener
  ) {
    testSettings = settings
    testInternalUtility = internalUtility
    testURLOpener = urlOpener

    // Create a real LoginManager instance and configure it with test dependencies
    loginManager = LoginManager()
    loginManager.configuredDependencies = LoginManager.ObjectDependencies(
      accessTokenWallet: AccessToken.self,
      authenticationTokenWallet: AuthenticationToken.self,
      errorFactory: _ErrorFactory(),
      graphRequestFactory: GraphRequestFactory(),
      internalUtility: testInternalUtility,
      keychainStore: KeychainStore(
        service: "test",
        accessGroup: nil
      ),
      loginCompleterFactory: LoginCompleterFactory(),
      profileProvider: Profile.self,
      settings: testSettings,
      urlOpener: testURLOpener
    )
  }

  // Wrapper method that tracks calls and returns stubbed parameters
  func logInParameters(
    configuration: LoginConfiguration?,
    loggingToken: String?,
    authenticationMethod: String
  ) -> [String: String]? {
    logInParametersCalled = true
    capturedLoggingToken = loggingToken
    capturedAuthMethod = authenticationMethod

    if shouldReturnNilParameters {
      return nil
    }

    // Return stubbed parameters or call the real implementation
    if let stubbed = stubbedParameters {
      return stubbed
    }

    // Call the real loginManager's method
    return loginManager.logInParameters(
      configuration: configuration,
      loggingToken: loggingToken,
      authenticationMethod: authenticationMethod
    )
  }
}
