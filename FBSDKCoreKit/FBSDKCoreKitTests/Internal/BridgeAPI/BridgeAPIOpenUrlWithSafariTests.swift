/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class BridgeAPIOpenUrlWithSafariTests: XCTestCase {
  let loginManager = FBSDKLoginManager()

  let logger = TestLogger(loggingBehavior: .developerErrors)
  let urlOpener = TestInternalURLOpener(canOpenURL: true)
  let bridgeAPIResponseFactory = TestBridgeAPIResponseFactory()
  let frameworkLoader = TestDylibResolver()
  let appURLSchemeProvider = TestInternalUtility()
  let sampleUrl = SampleURLs.valid
  let errorFactory = TestErrorFactory()

  lazy var api = BridgeAPI(
    processInfo: TestProcessInfo(),
    logger: logger,
    urlOpener: urlOpener,
    bridgeAPIResponseFactory: bridgeAPIResponseFactory,
    frameworkLoader: frameworkLoader,
    appURLSchemeProvider: appURLSchemeProvider,
    errorFactory: errorFactory
  )

  override func setUp() {
    super.setUp()

    FBSDKLoginManager.resetTestEvidence()

    frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.self
  }

  // MARK: - Url Opening

  func testWithNonHttpUrlScheme() {
    api.expectingBackground = true // So we can check that it's unchanged
    let nonHTTPUrl = URL(string: "file://example.com")! // swiftlint:disable:this force_unwrapping
    api.openURLWithSafariViewController(
      url: nonHTTPUrl,
      sender: nil,
      from: nil,
      handler: uninvokedSuccessBlock()
    )

    XCTAssertEqual(
      urlOpener.capturedOpenURL,
      nonHTTPUrl,
      "Should try to open a url with a non http scheme"
    )
    XCTAssertTrue(
      api.expectingBackground,
      "Should not modify whether the background is expected to change"
    )
    XCTAssertNil(
      api.pendingURLOpen,
      "Should not set a pending url opener"
    )
  }

  func testWithAuthenticationURL() {
    loginManager.stubbedIsAuthenticationURL = true
    api.expectingBackground = true

    api.openURLWithSafariViewController(
      url: sampleUrl,
      sender: loginManager,
      from: nil,
      handler: uninvokedSuccessBlock()
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open an authentication url when safari controller is specified"
    )
    XCTAssertNotNil(api.authenticationSessionCompletionHandler)
    XCTAssertNotNil(api.authenticationSession)
    assertExpectingBackgroundAndPendingUrlOpener()
  }

  func testWithNonAuthenticationURLWithSafariControllerAvailable() {
    loginManager.stubbedIsAuthenticationURL = false
    api.expectingBackground = true

    api.openURLWithSafariViewController(
      url: sampleUrl,
      sender: loginManager,
      from: nil,
      handler: uninvokedSuccessBlock()
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open an authentication url when safari controller is specified"
    )
    XCTAssertNil(api.authenticationSessionCompletionHandler)
    XCTAssertNil(api.authenticationSession)
    assertExpectingBackgroundAndPendingUrlOpener()
  }

  func testWithoutSafariVcAvailable() {
    frameworkLoader.stubSafariViewControllerClass = nil
    loginManager.stubbedIsAuthenticationURL = false
    api.expectingBackground = true

    api.openURLWithSafariViewController(
      url: sampleUrl,
      sender: loginManager,
      from: nil,
      handler: uninvokedSuccessBlock()
    )

    XCTAssertEqual(
      urlOpener.capturedOpenURL,
      sampleUrl,
      "Should try to open a url when a safari controller is not available"
    )
    XCTAssertNil(api.authenticationSessionCompletionHandler)
    XCTAssertNil(api.authenticationSession)
    XCTAssertTrue(
      api.pendingURLOpen === loginManager,
      "Should set the pending url opener to the passed in sender"
    )
  }

  func testWithoutFromViewController() {
    loginManager.stubbedIsAuthenticationURL = false
    api.expectingBackground = true

    api.openURLWithSafariViewController(
      url: sampleUrl,
      sender: loginManager,
      from: nil,
      handler: uninvokedSuccessBlock()
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )
    XCTAssertNil(api.authenticationSessionCompletionHandler)
    XCTAssertNil(api.authenticationSession)
    XCTAssertEqual(
      logger.capturedContents,
      "There are no valid ViewController to present SafariViewController with"
    )
  }

  func testWithFromViewControllerMissingTransitionCoordinator() {
    let spy = ViewControllerSpy.makeDefaultSpy()
    loginManager.stubbedIsAuthenticationURL = false
    api.expectingBackground = true
    var didInvokeHandler = false
    let handler: SuccessBlock = { success, error in
      XCTAssertTrue(success, "Should call the handler with success")
      XCTAssertNil(error, "Should not call the handler with an error")
      didInvokeHandler = true
    }

    api.openURLWithSafariViewController(
      url: sampleUrl,
      sender: loginManager,
      from: spy,
      handler: handler
    )

    let safariVc = api.safariViewController

    XCTAssertNotNil(
      safariVc,
      "Should create and set a safari view controller for display"
    )
    XCTAssertEqual(
      safariVc?.modalPresentationStyle,
      .overFullScreen,
      "Should set the correct modal presentation style"
    )
    XCTAssertEqual(
      safariVc?.delegate as? BridgeAPI,
      api,
      "Should set the safari view controller delegate to the bridge api"
    )
    XCTAssertEqual(
      spy.capturedPresentViewController,
      safariVc?.parent,
      "Should present the view controller containing the safari view controller"
    )
    XCTAssertTrue(
      spy.capturedPresentViewControllerAnimated,
      "Should animate presenting the safari view controller"
    )
    XCTAssertNil(
      spy.capturedPresentViewControllerCompletion,
      "Should not pass a completion handler to the safari vc presentation"
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )
    XCTAssertNil(api.authenticationSessionCompletionHandler)
    XCTAssertNil(api.authenticationSession)
    assertExpectingBackgroundAndPendingUrlOpener()
    XCTAssertTrue(didInvokeHandler)
  }

  func testWithFromViewControllerWithTransitionCoordinator() {
    let spy = ViewControllerSpy.makeDefaultSpy()
    let coordinator = TestViewControllerTransitionCoordinator()
    spy.stubbedTransitionCoordinator = coordinator
    loginManager.stubbedIsAuthenticationURL = false
    api.expectingBackground = true
    var didInvokeHandler = false
    let handler: SuccessBlock = { success, error in
      XCTAssertTrue(success, "Should call the handler with success")
      XCTAssertNil(error, "Should not call the handler with an error")
      didInvokeHandler = true
    }
    api.openURLWithSafariViewController(
      url: sampleUrl,
      sender: loginManager,
      from: spy,
      handler: handler
    )
    // swiftlint:disable:next force_unwrapping
    coordinator.capturedAnimateAlongsideTransitionCompletion!(
      TestViewControllerTransitionCoordinator()
    )

    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )

    XCTAssertNil(api.authenticationSessionCompletionHandler)
    XCTAssertNil(api.authenticationSession)

    let safariVc = api.safariViewController

    XCTAssertNotNil(
      safariVc,
      "Should create and set a safari view controller for display"
    )
    XCTAssertEqual(
      safariVc?.modalPresentationStyle,
      .overFullScreen,
      "Should set the correct modal presentation style"
    )
    XCTAssertEqual(
      safariVc?.delegate as? BridgeAPI,
      api,
      "Should set the safari view controller delegate to the bridge api"
    )
    XCTAssertEqual(
      spy.capturedPresentViewController,
      safariVc?.parent,
      "Should present the view controller containing the safari view controller"
    )
    XCTAssertTrue(
      spy.capturedPresentViewControllerAnimated,
      "Should animate presenting the safari view controller"
    )
    XCTAssertNil(
      spy.capturedPresentViewControllerCompletion,
      "Should not pass a completion handler to the safari vc presentation"
    )
    assertExpectingBackgroundAndPendingUrlOpener()
    XCTAssertTrue(didInvokeHandler)
  }

  func assertExpectingBackgroundAndPendingUrlOpener(
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertFalse(
      api.expectingBackground,
      "Should set expecting background to false",
      file: file,
      line: line
    )

    XCTAssertTrue(
      api.pendingURLOpen === loginManager,
      "Should set the pending url opener to the passed in sender",
      file: file,
      line: line
    )
  }

  func uninvokedSuccessBlock() -> SuccessBlock {
    { _, _ in
      XCTFail("Should not invoke the completion handler")
    }
  }
}
