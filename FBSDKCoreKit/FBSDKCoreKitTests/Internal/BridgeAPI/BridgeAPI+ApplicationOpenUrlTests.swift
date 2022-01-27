/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// swiftlint:disable:next swiftlint_disable_without_this_or_next
// swiftlint:disable line_length
extension BridgeAPITests {

  // MARK: - URL Opening

  func testOpenUrlShouldStopPropagationWithPendingURL() {
    let urlOpener = FBSDKLoginManager()
    urlOpener.stubShouldStopPropagationOfURL(sampleURL, withValue: true)
    urlOpener.stubbedCanOpenURL = true

    api.pendingURLOpen = urlOpener

    XCTAssertTrue(
      api.application(
        UIApplication.shared,
        open: sampleURL,
        sourceApplication: sampleSource,
        annotation: sampleAnnotation
      ),
      "Should early exit when the opener stops propagation"
    )

    XCTAssertNil(
      urlOpener.capturedCanOpenURL,
      "Should not check if a url can be opened when exiting early"
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: false,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: false,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: true,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      hasSafariViewController: false,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedAuthCancelCallCount: 1,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: true,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: false
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: true,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpen(
      pendingUrlCanOpenUrl: true,
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: true,
      expectedAuthSessionCompletionExists: true
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: false
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: false
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: true
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: true,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: false
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: true,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: true
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: false,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: false
    )
  }

  func testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse() {
    verifyOpenURLWithoutSafariVc(
      isDismissingSafariViewController: false,
      authSessionCompletionHandlerExists: true,
      canHandleBridgeApiResponse: false,
      expectedIsDismissingSafariVc: false,
      expectedAuthSessionCompletionExists: false,
      expectedReturnValue: false
    )
  }

  // MARK: - Helpers

  /// Assumes should not stop propagation of url
  func verifyOpen( // swiftlint:disable:this function_parameter_count
    pendingUrlCanOpenUrl: Bool,
    hasSafariViewController: Bool,
    isDismissingSafariViewController: Bool,
    authSessionCompletionHandlerExists: Bool,
    canHandleBridgeApiResponse: Bool,
    expectedAuthCancelCallCount: Int,
    expectedIsDismissingSafariVc: Bool,
    expectedAuthSessionCompletionExists: Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    verifyOpen(
      pendingUrlCanOpenUrl: pendingUrlCanOpenUrl,
      hasSafariViewController: hasSafariViewController,
      isDismissingSafariViewController: isDismissingSafariViewController,
      authSessionCompletionHandlerExists: authSessionCompletionHandlerExists,
      canHandleBridgeApiResponse: canHandleBridgeApiResponse,
      expectedAuthSessionCompletionHandlerUrl: nil,
      expectedAuthSessionCompletionHandlerError: nil,
      expectAuthSessionCompletionHandlerInvoked: false,
      expectedAuthCancelCallCount: expectedAuthCancelCallCount,
      expectedAuthSessionExists: false,
      expectedAuthSessionCompletionExists: expectedAuthSessionCompletionExists,
      expectedCanOpenUrlCalledWithUrl: createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectedCanOpenUrlSource: sampleSource,
      expectedCanOpenUrlAnnotation: sampleAnnotation,
      expectedOpenUrlUrl: createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectedOpenUrlSource: sampleSource,
      expectedOpenUrlAnnotation: sampleAnnotation,
      expectedPendingUrlOpenExists: false,
      expectedIsDismissingSafariVc: expectedIsDismissingSafariVc,
      expectedSafariVcExists: hasSafariViewController,
      expectedReturnValue: true,
      file: file,
      line: line
    )
  }

  /// Assumes should not stop propagation of url
  /// Assumes SafariViewController is not nil
  func verifyOpen( // swiftlint:disable:this function_parameter_count
    pendingUrlCanOpenUrl: Bool,
    isDismissingSafariViewController: Bool,
    authSessionCompletionHandlerExists: Bool,
    canHandleBridgeApiResponse: Bool,
    expectedIsDismissingSafariVc: Bool,
    expectedAuthSessionCompletionExists: Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    verifyOpen(
      pendingUrlCanOpenUrl: pendingUrlCanOpenUrl,
      hasSafariViewController: true,
      isDismissingSafariViewController: isDismissingSafariViewController,
      authSessionCompletionHandlerExists: authSessionCompletionHandlerExists,
      canHandleBridgeApiResponse: canHandleBridgeApiResponse,
      expectedAuthSessionCompletionHandlerUrl: nil,
      expectedAuthSessionCompletionHandlerError: nil,
      expectAuthSessionCompletionHandlerInvoked: false,
      expectedAuthCancelCallCount: 0,
      expectedAuthSessionExists: true,
      expectedAuthSessionCompletionExists: expectedAuthSessionCompletionExists,
      expectedCanOpenUrlCalledWithUrl: createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectedCanOpenUrlSource: sampleSource,
      expectedCanOpenUrlAnnotation: sampleAnnotation,
      expectedOpenUrlUrl: nil,
      expectedOpenUrlSource: nil,
      expectedOpenUrlAnnotation: nil,
      expectedPendingUrlOpenExists: true,
      expectedIsDismissingSafariVc: expectedIsDismissingSafariVc,
      expectedSafariVcExists: false,
      expectedReturnValue: true,
      file: file,
      line: line
    )
  }

  /// Assumes should not stop propagation of url
  /// Assumes Pending Url cannot open
  /// Assumes SafariViewController is nil
  func verifyOpenURLWithoutSafariVc( // swiftlint:disable:this function_parameter_count
    isDismissingSafariViewController: Bool,
    authSessionCompletionHandlerExists: Bool,
    canHandleBridgeApiResponse: Bool,
    expectedIsDismissingSafariVc: Bool,
    expectedAuthSessionCompletionExists: Bool,
    expectedReturnValue: Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    verifyOpen(
      pendingUrlCanOpenUrl: false,
      hasSafariViewController: false,
      isDismissingSafariViewController: isDismissingSafariViewController,
      authSessionCompletionHandlerExists: authSessionCompletionHandlerExists,
      canHandleBridgeApiResponse: canHandleBridgeApiResponse,
      expectedAuthSessionCompletionHandlerUrl: createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectedAuthSessionCompletionHandlerError: makeLoginInterruptionError(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectAuthSessionCompletionHandlerInvoked: true,
      expectedAuthCancelCallCount: 1,
      expectedAuthSessionExists: false,
      expectedAuthSessionCompletionExists: expectedAuthSessionCompletionExists,
      expectedCanOpenUrlCalledWithUrl: createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectedCanOpenUrlSource: sampleSource,
      expectedCanOpenUrlAnnotation: sampleAnnotation,
      expectedOpenUrlUrl: createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse),
      expectedOpenUrlSource: sampleSource,
      expectedOpenUrlAnnotation: sampleAnnotation,
      expectedPendingUrlOpenExists: false,
      expectedIsDismissingSafariVc: expectedIsDismissingSafariVc,
      expectedSafariVcExists: false,
      expectedReturnValue: expectedReturnValue,
      file: file,
      line: line
    )
  }

  // swiftlint:disable:next function_parameter_count
  func verifyOpen(
    pendingUrlCanOpenUrl: Bool,
    hasSafariViewController: Bool,
    isDismissingSafariViewController: Bool,
    authSessionCompletionHandlerExists: Bool,
    canHandleBridgeApiResponse: Bool,
    expectedAuthSessionCompletionHandlerUrl: URL?,
    expectedAuthSessionCompletionHandlerError: Error?,
    expectAuthSessionCompletionHandlerInvoked: Bool,
    expectedAuthCancelCallCount: Int,
    expectedAuthSessionExists: Bool,
    expectedAuthSessionCompletionExists: Bool,
    expectedCanOpenUrlCalledWithUrl: URL?,
    expectedCanOpenUrlSource: String?,
    expectedCanOpenUrlAnnotation: String?,
    expectedOpenUrlUrl: URL?,
    expectedOpenUrlSource: String?,
    expectedOpenUrlAnnotation: String?,
    expectedPendingUrlOpenExists: Bool,
    expectedIsDismissingSafariVc: Bool,
    expectedSafariVcExists: Bool,
    expectedReturnValue: Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let urlOpener = FBSDKLoginManager()
    let authSessionSpy = AuthenticationSessionSpy(
      url: sampleURL,
      callbackURLScheme: nil
    ) { _, _ in
      XCTFail(
        "Should not invoke the completion for the authentication session",
        file: file,
        line: line
      )
    }

    urlOpener.stubShouldStopPropagationOfURL(sampleURL, withValue: false)
    urlOpener.stubbedCanOpenURL = pendingUrlCanOpenUrl

    api.pendingURLOpen = urlOpener

    if hasSafariViewController {
      api.safariViewController = TestSafariViewController(url: sampleURL)
    }
    api.isDismissingSafariViewController = isDismissingSafariViewController
    api.authenticationSessionState = .none
    api.pendingRequest = makeSampleBridgeAPIRequest()
    api.authenticationSession = authSessionSpy

    var capturedAuthSessionCompletionHandlerURL: URL?
    var capturedAuthSessionCompletionHandlerError: Error?
    if authSessionCompletionHandlerExists {
      api.authenticationSessionCompletionHandler = { callbackURL, error in
        capturedAuthSessionCompletionHandlerURL = callbackURL
        capturedAuthSessionCompletionHandlerError = error
      }
    }

    api.pendingRequestCompletionBlock = { _ in
      XCTFail(
        "Should not invoke the pending request completion block",
        file: file,
        line: line
      )
    }

    if canHandleBridgeApiResponse {
      appURLSchemeProvider.appURLScheme = URLScheme.http.rawValue
      api.pendingRequestCompletionBlock = nil
    } else {
      appURLSchemeProvider.appURLScheme = "foo"
    }

    let urlToOpen = (canHandleBridgeApiResponse ? validBridgeResponseURL : sampleURL)
    let returnValue = api.application(
      UIApplication.shared,
      open: urlToOpen,
      sourceApplication: sampleSource,
      annotation: sampleAnnotation
    )
    XCTAssertEqual(
      returnValue,
      expectedReturnValue,
      "The return value for the overall method should be \(expectedReturnValue)",
      file: file,
      line: line
    )

    if authSessionCompletionHandlerExists && expectAuthSessionCompletionHandlerInvoked {
      XCTAssertEqual(
        capturedAuthSessionCompletionHandlerURL,
        expectedAuthSessionCompletionHandlerUrl,
        "Should invoke the authentication session completion handler with the expected URL",
        file: file,
        line: line
      )
      XCTAssertEqual(
        capturedAuthSessionCompletionHandlerError as NSError?,
        expectedAuthSessionCompletionHandlerError as NSError?,
        "Should invoke the authentication session completion handler with the expected error",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        capturedAuthSessionCompletionHandlerURL,
        "Should not invoke the authentication session completion handler",
        file: file,
        line: line
      )
      XCTAssertNil(
        capturedAuthSessionCompletionHandlerError,
        "Should not invoke the authentication session completion handler",
        file: file,
        line: line
      )
    }

    if expectedAuthSessionExists {
      XCTAssertNotNil(
        api.authenticationSession,
        "The authentication session should not be nil",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        api.authenticationSession,
        "The authentication session should be nil",
        file: file,
        line: line
      )
    }

    if expectedAuthSessionCompletionExists {
      XCTAssertNotNil(
        api.authenticationSessionCompletionHandler,
        "The authentication session completion handler should not be nil",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        api.authenticationSessionCompletionHandler,
        "The authentication session completion handler should be nil",
        file: file,
        line: line
      )
    }

    XCTAssertEqual(
      authSessionSpy.cancelCallCount,
      expectedAuthCancelCallCount,
      "The authentication session should be cancelled the expected number of times",
      file: file,
      line: line
    )
    XCTAssertEqual(
      api.authenticationSessionState,
      .none,
      "The authentication session state should not change",
      file: file,
      line: line
    )
    XCTAssertEqual(
      urlOpener.capturedCanOpenURL,
      expectedCanOpenUrlCalledWithUrl,
      "The url opener's can open url method should be called with the expected URL",
      file: file,
      line: line
    )
    XCTAssertEqual(
      urlOpener.capturedCanOpenSourceApplication,
      expectedCanOpenUrlSource,
      "The url opener's can open url method should be called with the expected source application",
      file: file,
      line: line
    )
    XCTAssertEqual(
      urlOpener.capturedCanOpenAnnotation,
      expectedCanOpenUrlAnnotation,
      "The url opener's can open url method should be called with the expected annotation",
      file: file,
      line: line
    )

    XCTAssertEqual(
      FBSDKLoginManager.capturedOpenURL,
      expectedOpenUrlUrl,
      "The url opener's open url method should be called with the expected URL",
      file: file,
      line: line
    )
    XCTAssertEqual(
      FBSDKLoginManager.capturedSourceApplication,
      expectedOpenUrlSource,
      "The url opener's open url method should be called with the expected source application",
      file: file,
      line: line
    )
    XCTAssertEqual(
      FBSDKLoginManager.capturedAnnotation,
      expectedOpenUrlAnnotation,
      "The url opener's open url method should be called with the expected annotation",
      file: file,
      line: line
    )

    if pendingUrlCanOpenUrl {
      XCTAssertNotNil(
        api.pendingRequest,
        "The pending request should be nil",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        api.pendingRequest,
        "The pending request should be nil",
        file: file,
        line: line
      )
      XCTAssertNil(
        api.pendingRequestCompletionBlock,
        "The pending request completion block should be nil",
        file: file,
        line: line
      )
    }

    if expectedPendingUrlOpenExists {
      XCTAssertNotNil(
        api.pendingURLOpen,
        "The reference to the url opener should not be nil",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        api.pendingURLOpen,
        "The reference to the url opener should be nil",
        file: file,
        line: line
      )
    }

    if expectedSafariVcExists {
      XCTAssertNotNil(
        api.safariViewController,
        "Safari view controller should not be nil",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        api.safariViewController,
        "Safari view controller should be nil",
        file: file,
        line: line
      )
    }

    XCTAssertEqual(
      api.isDismissingSafariViewController,
      expectedIsDismissingSafariVc,
      "Should set isDismissingSafariViewController to the expected value",
      file: file,
      line: line
    )
  }

  func createURL(canHandleBridgeApiResponse: Bool) -> URL {
    canHandleBridgeApiResponse ? validBridgeResponseURL : sampleURL
  }

  func makeSampleBridgeAPIRequest() -> BridgeAPIRequest {
    BridgeAPIRequest(
      protocolType: .web,
      scheme: .https,
      methodName: nil,
      parameters: nil,
      userInfo: nil
    )! // swiftlint:disable:this force_unwrapping
  }

  func makeLoginInterruptionError(canHandleBridgeApiResponse: Bool) -> Error {
    let url = createURL(canHandleBridgeApiResponse: canHandleBridgeApiResponse)
    let errorMessage = "Login attempt cancelled by alternate call to openURL from: \(url)"

    return errorFactory.error(
      code: CoreError.errorBridgeAPIInterruption.rawValue,
      userInfo: [ErrorLocalizedDescriptionKey: errorMessage],
      message: errorMessage,
      underlyingError: nil
    )
  }
}
