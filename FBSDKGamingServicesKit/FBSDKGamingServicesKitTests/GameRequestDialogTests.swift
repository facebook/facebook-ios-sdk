/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import FBSDKShareKit
import TestTools
import XCTest

final class GameRequestDialogTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var dialog: GameRequestDialog!
  var content: GameRequestContent!
  var delegate: TestGameRequestDialogDelegate!
  var bridgeAPIRequestOpener: TestBridgeAPIRequestOpener!
  var errorFactory: TestErrorFactory!
  var gameRequestURLProvider: TestGameRequestURLProvider.Type!
  var internalUtility: TestInternalUtility!
  var logger: FBSDKGamingServicesKitTests.TestLogger.Type!
  var settings: TestSettings!
  var shareValidator: TestShareUtility.Type!
  var utility: TestGamingUtility.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    content = GameRequestContent()
    delegate = TestGameRequestDialogDelegate()
    dialog = GameRequestDialog(content: content, delegate: delegate)

    bridgeAPIRequestOpener = TestBridgeAPIRequestOpener()
    errorFactory = TestErrorFactory()
    gameRequestURLProvider = TestGameRequestURLProvider.self
    internalUtility = TestInternalUtility()
    logger = FBSDKGamingServicesKitTests.TestLogger.self
    settings = TestSettings()
    shareValidator = TestShareUtility.self
    utility = TestGamingUtility.self

    dialog.setDependencies(
      .init(
        bridgeAPIRequestOpener: bridgeAPIRequestOpener,
        errorFactory: errorFactory,
        gameRequestURLProvider: gameRequestURLProvider,
        internalUtility: internalUtility,
        logger: logger,
        settings: settings,
        shareValidator: shareValidator,
        utility: utility
      )
    )
  }

  override func tearDown() {
    content = nil
    delegate = nil

    errorFactory = nil
    gameRequestURLProvider = nil
    internalUtility = nil
    logger = nil
    settings = nil
    shareValidator = nil
    bridgeAPIRequestOpener = nil
    utility = nil

    TestGameRequestURLProvider.reset()
    TestLogger.reset()
    TestShareUtility.reset()
    TestGamingUtility.reset()

    dialog = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    dialog.resetDependencies()
    let dependencies = try dialog.getDependencies()

    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      BridgeAPI.shared,
      .Dependencies.defaultDependency("the shared BridgeAPI", for: "bridge API request opener")
    )
    XCTAssertTrue(
      dependencies.errorFactory is ErrorFactory,
      .Dependencies.defaultDependency("a concrete error factory", for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.gameRequestURLProvider as AnyObject,
      GameRequestURLProvider.self,
      .Dependencies.defaultDependency("GameRequestURLProvider", for: "game request URL provider")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      InternalUtility.shared,
      .Dependencies.defaultDependency("the shared InternalUtility", for: "internal utility")
    )
    XCTAssertIdentical(
      dependencies.logger as AnyObject,
      Logger.self,
      .Dependencies.defaultDependency("Logger", for: "logger")
    )
    XCTAssertIdentical(
      dependencies.settings,
      Settings.shared,
      .Dependencies.defaultDependency("the shared Settings", for: "settings")
    )
    XCTAssertTrue(
      dependencies.shareValidator is _ShareUtility.Type,
      .Dependencies.defaultDependency("_ShareUtility", for: "share validator")
    )
    XCTAssertIdentical(
      dependencies.utility as AnyObject,
      Utility.self,
      .Dependencies.defaultDependency("Utility", for: "utility")
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try dialog.getDependencies()

    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      bridgeAPIRequestOpener,
      .Dependencies.customDependency(for: "bridge API request opener")
    )
    XCTAssertIdentical(
      dependencies.errorFactory,
      errorFactory,
      .Dependencies.customDependency(for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.gameRequestURLProvider as AnyObject,
      gameRequestURLProvider,
      .Dependencies.customDependency(for: "game request URL provider")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      internalUtility,
      .Dependencies.customDependency(for: "internal utility")
    )
    XCTAssertIdentical(
      dependencies.logger as AnyObject,
      logger,
      .Dependencies.customDependency(for: "logger")
    )
    XCTAssertIdentical(
      dependencies.settings,
      settings,
      .Dependencies.customDependency(for: "settings")
    )
    XCTAssertIdentical(
      dependencies.shareValidator as AnyObject,
      shareValidator,
      .Dependencies.customDependency(for: "share validator")
    )
    XCTAssertIdentical(
      dependencies.utility as AnyObject,
      utility,
      .Dependencies.customDependency(for: "utility")
    )
  }

  // MARK: - Launching

  private func setValidLaunchConditions() {
    utility.stubbedGraphDomain = "gaming"
    internalUtility.isFacebookAppInstalled = true
    content.message = "foo"
    gameRequestURLProvider.stubbedDeepLinkURL = SampleURLs.valid(path: "launching")
  }

  func testShowingWithLaunchConditions() {
    setValidLaunchConditions()

    _ = GameRequestDialog.show(dialog: dialog)

    // how to show that launch was called?
    XCTAssertEqual(
      bridgeAPIRequestOpener.capturedURL,
      gameRequestURLProvider.stubbedDeepLinkURL,
      "Should utilize the bridge api request opener when the launch conditions support it"
    )
  }

  func testShowingWithoutLaunchConditionForGraphDomain() {
    setValidLaunchConditions()
    utility.stubbedGraphDomain = "facebook"

    _ = GameRequestDialog.show(dialog: dialog)

    XCTAssertNil(
      bridgeAPIRequestOpener.capturedURL,
      "Should not utilize the bridge api request opener when the graph domain is not `gaming`"
    )
  }

  func testShowingWithoutLaunchConditionForFacebookAppInstall() {
    setValidLaunchConditions()
    internalUtility.isFacebookAppInstalled = false

    _ = GameRequestDialog.show(dialog: dialog)

    XCTAssertNil(
      bridgeAPIRequestOpener.capturedURL,
      "Should not utilize the bridge api request opener when the facebook app is not installed"
    )
  }

  func testShowingWithoutLaunchConditionForNonEmptyContentMessage() {
    setValidLaunchConditions()
    content.message = ""

    _ = GameRequestDialog.show(dialog: dialog)

    XCTAssertNil(
      bridgeAPIRequestOpener.capturedURL,
      "Should not utilize the bridge api request opener when the content message is empty"
    )
  }

  func testShowingWithoutLaunchConditionForMissingURL() {
    setValidLaunchConditions()
    gameRequestURLProvider.stubbedDeepLinkURL = nil

    _ = GameRequestDialog.show(dialog: dialog)

    XCTAssertNil(
      bridgeAPIRequestOpener.capturedURL,
      "Should not utilize the bridge api request opener when there is no URL to open"
    )
  }

  func testCompletingLaunchWithFailure() {
    setValidLaunchConditions()

    _ = GameRequestDialog.show(dialog: dialog)

    bridgeAPIRequestOpener.capturedHandler?(false, nil)

    XCTAssertNil(delegate.failureDialog, "Should not invoke the failure delegate method when success is false")
  }

  func testCompletingLaunchWithError() throws {
    setValidLaunchConditions()
    _ = GameRequestDialog.show(dialog: dialog)

    let error = SampleError()
    bridgeAPIRequestOpener.capturedHandler?(true, error)

    let expectedError = TestSDKError(
      type: .general,
      code: CoreError.errorBridgeAPIInterruption.rawValue,
      message: "Error occured while interacting with Gaming Services, Failed to open bridge.",
      underlyingError: error
    )
    let capturedError = try XCTUnwrap(
      delegate.failureError as? TestSDKError,
      "Should use the error factory to create an error"
    )

    XCTAssertIdentical(delegate.failureDialog, dialog)
    XCTAssertEqual(
      capturedError,
      expectedError,
      "Should use the error factory to create an error with the expected inputs"
    )
  }

  // MARK: - Showing

  private func setValidShowConditions() {
    internalUtility.stubbedTopMostViewController = UIViewController()
    content.message = "foo"
  }

  func testShowingWithValidShowConditions() throws {
    setValidShowConditions()

    _ = GameRequestDialog.show(dialog: dialog)

    let capturedRequest = try XCTUnwrap(
      bridgeAPIRequestOpener.capturedRequest,
      "Should invoke the bridge api request opener with a bridge api request"
    )

    XCTAssertEqual(
      capturedRequest.scheme,
      URLScheme.https.rawValue,
      "Should use the expected scheme"
    )
    XCTAssertEqual(
      capturedRequest.protocolType,
      .web,
      "Should use the expected protocol type"
    )
    XCTAssertEqual(
      capturedRequest.methodName,
      "apprequests",
      "Should use the expected method name"
    )
    let downcastRequest = try XCTUnwrap(
      capturedRequest as? BridgeAPIRequest,
      "The request should be the expected type"
    )
    let parameters = try XCTUnwrap(
      downcastRequest.parameters as? [String: String],
      "The request should contain string to string parameters"
    )
    let expectedParameters = ["title": "", "object_id": "", "suggestions": "", "to": "", "message": "foo"]

    XCTAssertTrue(
      NSDictionary(dictionary: parameters).isEqual(to: expectedParameters),
      """
      Actual parameters should match the expected parameters. \n
      Actual parameters: \(parameters)
      Expected parameters: \(expectedParameters)
      """
    )
  }

  func testShowingWithMissingTopMostViewController() {
    setValidShowConditions()
    internalUtility.stubbedTopMostViewController = nil

    _ = GameRequestDialog.show(dialog: dialog)

    XCTAssertNil(
      bridgeAPIRequestOpener.capturedRequest,
      "Should not invoke the bridge api request opener without a topmost view controller"
    )
  }

  func testShowingWithEmptyContentMessage() {
    setValidShowConditions()
    content.message = ""

    _ = GameRequestDialog.show(dialog: dialog)

    XCTAssertNil(
      bridgeAPIRequestOpener.capturedRequest,
      "Should not invoke the bridge api request opener with an empty content message"
    )
  }

  // MARK: - URL Opening

  private func launchDialog() {
    setValidLaunchConditions()
    _ = GameRequestDialog.show(dialog: dialog)
  }

  private func createGamingURL(appID: String, queryItems: [URLQueryItem] = []) -> URL? {
    var components = URLComponents()
    components.scheme = "fb\(appID)"
    components.host = "game_requests"
    components.queryItems = queryItems

    return components.url
  }

  func testOpeningGamingURLWithParametersWhenAwaitingResult() throws {
    settings.appID = "123"
    let url = try XCTUnwrap(
      createGamingURL(
        appID: "123",
        queryItems: [
          .init(name: "request_id", value: "foo"),
          .init(name: "recipients", value: "1,2,3"),
        ]
      )
    )

    // Need to launch the dialog in order to set `isAwaitingResult`
    launchDialog()

    _ = dialog.application(nil, open: url, sourceApplication: nil, annotation: nil)

    XCTAssertNotNil(delegate.completionDialog, "Should open a url when the conditions are met")

    let results = try XCTUnwrap(delegate.completionResults)
    XCTAssertEqual(
      results["recipients"] as? [String],
      ["1", "2", "3"],
      "Should parse the recipients from a comma separated string"
    )
    XCTAssertEqual(
      results["request_id"] as? String,
      "foo",
      "Should parse the request ID from the url query parameters"
    )
  }

  func testOpeningGamingURLWithoutParametersWhenAwaitingResult() throws {
    settings.appID = "123"
    let url = try XCTUnwrap(createGamingURL(appID: "123"))

    // Need to launch the dialog in order to set `isAwaitingResult`
    launchDialog()

    _ = dialog.application(nil, open: url, sourceApplication: nil, annotation: nil)

    XCTAssertNil(
      delegate.completionDialog,
      "Should not invoke the completion delegate when there are no query items"
    )
    XCTAssertEqual(
      delegate.cancellationDialog,
      dialog,
      "Should invoke the cancellation delegate when opening a url and not awaiting a result"
    )
  }

  func testOpeningGamingURLWhenNotAwaitingResult() throws {
    settings.appID = "123"
    let url = try XCTUnwrap(createGamingURL(appID: "123"))

    _ = dialog.application(nil, open: url, sourceApplication: nil, annotation: nil)

    XCTAssertNil(
      delegate.completionDialog,
      "Should not invoke the completion delegate when not awaiting a result"
    )
    XCTAssertNil(
      delegate.cancellationDialog,
      "Should not invoke the cancellation delegate when not awaiting a result"
    )
  }

  func testOpeningNonGamingURL() {
    _ = dialog.application(
      nil,
      open: SampleURLs.valid,
      sourceApplication: nil,
      annotation: nil
    )

    XCTAssertNil(
      delegate.completionDialog,
      "Should not invoke the completion delegate"
    )
    XCTAssertNil(
      delegate.cancellationDialog,
      "Should not invoke the cancellation delegate"
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  enum Dependencies {
    static func defaultDependency(_ dependency: String, for type: String) -> String {
      "A GameRequestDialog instance uses \(dependency) as its \(type) dependency by default"
    }

    static func customDependency(for type: String) -> String {
      "A GameRequestDialog instance uses a custom \(type) dependency when provided"
    }
  }
}
