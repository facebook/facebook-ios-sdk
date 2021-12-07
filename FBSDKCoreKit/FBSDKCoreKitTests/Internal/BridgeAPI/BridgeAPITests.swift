/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

// swiftlint:disable file_length
class BridgeAPITests: XCTestCase {

  let sampleSource = "com.example"
  let sampleAnnotation = "foo"

  // swiftlint:disable implicitly_unwrapped_optional force_unwrapping
  var sampleURL = URL(string: "https://example.com")!
  var processInfo: TestProcessInfo!
  var logger: TestLogger!
  var urlOpener: TestInternalURLOpener!
  var responseFactory: TestBridgeAPIResponseFactory!
  var frameworkLoader: TestDylibResolver!
  var appURLSchemeProvider: TestInternalUtility!
  var errorFactory: TestErrorFactory!
  var api: BridgeAPI!
  // swiftlint:enable implicitly_unwrapped_optional force_unwrapping

  override func setUp() {
    super.setUp()

    FBSDKLoginManager.resetTestEvidence()

    processInfo = TestProcessInfo()
    logger = TestLogger(loggingBehavior: .developerErrors)
    urlOpener = TestInternalURLOpener()
    responseFactory = TestBridgeAPIResponseFactory()
    frameworkLoader = TestDylibResolver()
    appURLSchemeProvider = TestInternalUtility()
    errorFactory = TestErrorFactory()

    configureSDK()

    api = BridgeAPI(
      processInfo: processInfo,
      logger: logger,
      urlOpener: urlOpener,
      bridgeAPIResponseFactory: responseFactory,
      frameworkLoader: frameworkLoader,
      appURLSchemeProvider: appURLSchemeProvider,
      errorFactory: errorFactory
    )
  }

  override func tearDown() {
    processInfo = nil
    logger = nil
    urlOpener = nil
    responseFactory = nil
    frameworkLoader = nil
    appURLSchemeProvider = nil
    errorFactory = nil
    api = nil

    FBSDKLoginManager.resetTestEvidence()

    super.tearDown()
  }

  func configureSDK() {
    let backgroundEventLogger = TestBackgroundEventLogger(
      infoDictionaryProvider: TestBundle(),
      eventLogger: TestAppEvents()
    )
    let serverConfigurationProvider = TestServerConfigurationProvider(
      configuration: ServerConfigurationFixtures.defaultConfig
    )
    let delegate = ApplicationDelegate(
      notificationCenter: TestNotificationCenter(),
      tokenWallet: TestAccessTokenWallet.self,
      settings: TestSettings(),
      featureChecker: TestFeatureManager(),
      appEvents: TestAppEvents(),
      serverConfigurationProvider: serverConfigurationProvider,
      store: UserDefaultsSpy(),
      authenticationTokenWallet: TestAuthenticationTokenWallet.self,
      profileProvider: TestProfileProvider.self,
      backgroundEventLogger: backgroundEventLogger,
      paymentObserver: TestPaymentObserver()
    )
    delegate.initializeSDK()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() throws {
    XCTAssertTrue(
      BridgeAPI.shared.processInfo is ProcessInfo,
      "The shared bridge API should use the system provided process info by default"
    )
    XCTAssertTrue(
      BridgeAPI.shared.logger is Logger,
      "The shared bridge API should use the expected logger type by default"
    )
    XCTAssertEqual(
      BridgeAPI.shared.urlOpener as? UIApplication,
      UIApplication.shared,
      "Should use the expected concrete url opener by default"
    )
    XCTAssertTrue(
      BridgeAPI.shared.bridgeAPIResponseFactory is BridgeAPIResponseFactory,
      "Should use and instance of the expected concrete response factory type by default"
    )
    XCTAssertEqual(
      BridgeAPI.shared.frameworkLoader as? DynamicFrameworkLoader,
      DynamicFrameworkLoader.shared(),
      "Should use the expected instance of dynamic framework loader"
    )
    XCTAssertTrue(
      BridgeAPI.shared.appURLSchemeProvider is InternalUtility,
      "Should use the expected internal utility type by default"
    )

    let factory = try XCTUnwrap(
      BridgeAPI.shared.errorFactory as? ErrorFactory,
      "Should create an error factory"
    )
    XCTAssertTrue(
      factory.reporter === ErrorReporter.shared,
      "Should use the shared error reporter by default"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      api.processInfo as? TestProcessInfo,
      processInfo,
      "Should be able to create a bridge api with a specific process info"
    )
    XCTAssertEqual(
      api.logger as? TestLogger,
      logger,
      "Should be able to create a bridge api with a specific logger"
    )
    XCTAssertEqual(
      api.urlOpener as? TestInternalURLOpener,
      urlOpener,
      "Should be able to create a bridge api with a specific url opener"
    )
    XCTAssertEqual(
      api.bridgeAPIResponseFactory as? TestBridgeAPIResponseFactory,
      responseFactory,
      "Should be able to create a bridge api with a specific response factory"
    )
    XCTAssertEqual(
      api.frameworkLoader as? TestDylibResolver,
      frameworkLoader,
      "Should be able to create a bridge api with a specific framework loader"
    )
    XCTAssertTrue(
      api.errorFactory === errorFactory,
      "Should be able to create a bridge API instance with an error factory"
    )
  }

  // MARK: - Lifecycle Methods

  // MARK: Will Resign Active

  func testWillResignActiveWithoutAuthSessionWithoutAuthSessionState() {
    api.applicationWillResignActive(UIApplication.shared)

    XCTAssertEqual(
      api.authenticationSessionState,
      .none,
      "Should not modify the auth session state if there is no auth session"
    )
  }

  func testWillResignActiveWithAuthSessionWithoutAuthSessionState() {
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()

    api.applicationWillResignActive(UIApplication.shared)

    XCTAssertEqual(
      api.authenticationSessionState,
      .none,
      "Should not modify the auth session state unless the current state is 'started'"
    )
  }

  func testWillResignActiveWithAuthSessionWithNonStartedAuthSessionState() {
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()

    [
      AuthenticationSession.none,
      .showAlert,
      .showWebBrowser,
      .canceledBySystem
    ]
      .shuffled()
      .forEach { state in
        api.authenticationSessionState = state
        api.applicationWillResignActive(UIApplication.shared)
        XCTAssertEqual(
          api.authenticationSessionState,
          state,
          "Should not modify the auth session state unless the current state is 'started'"
        )
      }
  }

  func testWillResignActiveWithAuthSessionWithStartedAuthSessionState() {
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()

    api.authenticationSessionState = .started
    api.applicationWillResignActive(UIApplication.shared)
    XCTAssertEqual(
      api.authenticationSessionState,
      .showAlert,
      "Should change the auth state from 'started' to 'alert' before resigning activity"
    )
  }

  // MARK: Did Become Active

  func testUpdatingShowAlertStateForDidBecomeActiveWithoutAuthSession() {
    [
      AuthenticationSession.none,
      .started,
      .showAlert,
      .showWebBrowser,
      .canceledBySystem
    ]
      .shuffled()
      .forEach { state in
        api.authenticationSessionState = state
        api.applicationDidBecomeActive(UIApplication.shared)
        XCTAssertEqual(
          api.authenticationSessionState,
          state,
          "Should not modify the auth session state if there is no auth session"
        )
      }
  }

  func testUpdatingShowAlertStateForDidBecomeActive() {
    let authSessionSpy = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSession = authSessionSpy
    api.authenticationSessionState = .showAlert

    api.applicationDidBecomeActive(UIApplication.shared)

    XCTAssertEqual(
      api.authenticationSessionState,
      .showWebBrowser,
      "Becoming active when the state is 'showAlert' should set the state to be 'showWebBrowser'"
    )
    XCTAssertEqual(
      authSessionSpy.cancelCallCount,
      0,
      "Becoming active when the state is 'showAlert' should not cancel the session"
    )
    XCTAssertNotNil(
      api.authenticationSession,
      "Becoming active when the state is 'showAlert' should not destroy the session"
    )
  }

  func testUpdatingCancelledBySystemStateForDidBecomeActive() {
    let authSessionSpy = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSession = authSessionSpy
    api.authenticationSessionState = .canceledBySystem

    api.applicationDidBecomeActive(UIApplication.shared)

    XCTAssertEqual(
      api.authenticationSessionState,
      .canceledBySystem,
      "Becoming active when the state is 'canceledBySystem' should not change the state"
    )
    XCTAssertNil(
      api.authenticationSession,
      "Becoming active when the state is 'canceledBySystem' should destroy the session"
    )
    XCTAssertEqual(
      authSessionSpy.cancelCallCount,
      1,
      "Becoming active when the state is 'canceledBySystem' should cancel the session"
    )
  }

  func testCompletingWithCancelledBySystemStateForDidBecomeActive() {
    let authSessionSpy = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSession = authSessionSpy
    api.authenticationSessionState = .canceledBySystem

    var capturedCallbackURL: URL?
    var capturedError: Error?
    api.authenticationSessionCompletionHandler = { callbackURL, error in
      capturedCallbackURL = callbackURL
      capturedError = error
    }

    api.applicationDidBecomeActive(UIApplication.shared)

    XCTAssertNil(
      capturedCallbackURL,
      "A completion triggered by becoming active in a canceled state should not have a callback URL"
    )
    XCTAssertEqual(
      (capturedError as NSError?)?.domain,
      "com.apple.AuthenticationServices.WebAuthenticationSession",
      "A completion triggered by becoming active in a canceled state should include an error"
    )
  }

  // MARK: Did Enter Background

  func testDidEnterBackgroundWithoutAuthSession() {
    api.setActive(true)
    api.expectingBackground = true

    [
      AuthenticationSession.none,
      .started,
      .showAlert,
      .showWebBrowser,
      .canceledBySystem
    ]
      .shuffled()
      .forEach { state in
        api.authenticationSessionState = state
        api.applicationDidEnterBackground(UIApplication.shared)
        XCTAssertFalse(
          api.isActive,
          "Should mark a bridge api inactive when entering the background"
        )
        XCTAssertFalse(
          api.expectingBackground,
          "Should mark a bridge api as not expecting backgrounding when entering the background"
        )
      }
  }

  func testDidEnterBackgroundInShowAlertState() {
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()
    api.authenticationSessionState = .showAlert

    api.applicationDidEnterBackground(UIApplication.shared)
    XCTAssertEqual(
      api.authenticationSessionState,
      .canceledBySystem,
      "Should cancel the session when entering the background while showing an alert"
    )
  }

  func testDidEnterBackgroundInNonShowAlertState() {
    api.authenticationSession = AuthenticationSessionSpy.makeDefaultSpy()

    [
      AuthenticationSession.none,
      .started,
      .showWebBrowser,
      .canceledBySystem
    ]
      .shuffled()
      .forEach { state in
        api.authenticationSessionState = state
        api.applicationDidEnterBackground(UIApplication.shared)
        XCTAssertEqual(
          api.authenticationSessionState,
          state,
          "Should only modify the auth session state on backgrounding if it is showing an alert"
        )
      }
  }

  // MARK: Did Finish Launching With Options

  func testDidFinishLaunchingWithoutLaunchedUrlWithoutSourceApplication() {
    XCTAssertFalse(
      api.application(UIApplication.shared, didFinishLaunchingWithOptions: [:]),
      "Should not consider it a successful launch if there is no launch url or source application"
    )
  }

  func testDidFinishLaunchingWithoutLaunchedUrlWithSourceApplication() {
    let options = [UIApplication.LaunchOptionsKey.sourceApplication: "com.example"]
    XCTAssertFalse(
      api.application(UIApplication.shared, didFinishLaunchingWithOptions: options),
      "Should not consider it a successful launch if there is no launch url"
    )
  }

  func testDidFinishLaunchingWithLaunchedUrlWithoutSourceApplication() {
    let options = [UIApplication.LaunchOptionsKey.url: sampleURL]
    XCTAssertFalse(
      api.application(UIApplication.shared, didFinishLaunchingWithOptions: options),
      "Should not consider it a successful launch if there is no source application"
    )
  }

  func testDidFinishLaunchingWithLaunchedUrlWithSourceApplication() {
    let options: [UIApplication.LaunchOptionsKey: Any] = [
      UIApplication.LaunchOptionsKey.url: self.sampleURL,
      UIApplication.LaunchOptionsKey.sourceApplication: sampleSource,
      UIApplication.LaunchOptionsKey.annotation: sampleAnnotation
    ]

    FBSDKLoginManager.stubbedOpenUrlSuccess = true

    XCTAssertTrue(
      api.application(UIApplication.shared, didFinishLaunchingWithOptions: options),
      "Should return the success value determined by the login manager's open url method"
    )

    XCTAssertEqual(
      FBSDKLoginManager.capturedOpenUrl,
      sampleURL,
      "Should pass the launch url to the login manager"
    )
    XCTAssertEqual(
      FBSDKLoginManager.capturedSourceApplication,
      sampleSource,
      "Should pass the source application to the login manager"
    )
    XCTAssertEqual(
      FBSDKLoginManager.capturedAnnotation,
      sampleAnnotation,
      "Should pass the annotation to the login manager"
    )
  }
}
