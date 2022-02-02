/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit
import TestTools
import XCTest

final class GamingServiceControllerTests: XCTestCase {

  let urlOpener = TestURLOpener()
  let settings = TestSettings()
  let url = URL(string: "fb123://community/")! // swiftlint:disable:this force_unwrapping
  var capturedSuccess = false
  var capturedResults = [Any]()
  var serviceError: Error?
  lazy var gamingService = GamingServiceController(
    serviceType: .community,
    pendingResult: [:],
    urlOpener: urlOpener,
    settings: settings
  ) { success, _, error in
    self.capturedSuccess = success
    self.serviceError = error
  }

  override func setUp() {
    super.setUp()

    settings.appID = "123"
  }

  func testSuccessfullyOpeningURL() {
    _ = gamingService.application(.shared, open: url, sourceApplication: "", annotation: "")
    XCTAssertTrue(
      capturedSuccess,
      "Should complete successfully if the url is formatted correctly."
    )
  }

  func testIsNotGamingURLFromParameters() {
    let url = URL(string: "f://c/")
    let isGamingURL = gamingService.application(UIApplication.shared, open: url, sourceApplication: "", annotation: "")
    XCTAssertFalse(
      capturedSuccess,
      "Should not complete successfully if the url is formatted incorrectly."
    )
    XCTAssertFalse(isGamingURL)
  }

  func testInvalidGamingURLWithValidTypeNotMatchingURLSource() {
    gamingService = GamingServiceController(
      serviceType: .friendFinder,
      pendingResult: [:],
      urlOpener: urlOpener,
      settings: settings
    ) { success, _, error in
      self.capturedSuccess = success
      self.serviceError = error
    }

    _ = gamingService.application(.shared, open: url, sourceApplication: "", annotation: "")
    XCTAssertFalse(
      capturedSuccess,
      "Should not call the completionHandler with invalid format in the URL"
    )
  }

  func testIsAuthenticationURL() {
    XCTAssertFalse(gamingService.isAuthenticationURL(url))
  }

  func testAddErrorToCompletionHandler() {
    gamingService.handleBridgeAPIError(SampleError())
    XCTAssertNotNil(
      serviceError,
      "Should have an error in completion handler if we pass one"
    )
  }

  func testHandleBridgeAPIErrorWithNullCompletionHandler() {
    // calling applicationDidBecomeActive to make completionHandler null
    gamingService.applicationDidBecomeActive(UIApplication.shared)
    gamingService.handleBridgeAPIError(SampleError())
    XCTAssertNil(
      serviceError,
      "Error should be nil if completion handler is nil"
    )
  }

  func testInValidCallbackURLWithImproperString() {
    XCTAssertFalse(
      gamingService.isValidCallbackURL(url, forService: "{}{}{}"),
      "Should return false if service parameter doesn't match the service type"
    )
  }

  func testInValidCallbackURLWithImproperURL() {
    let inValidURL = URL(string: "antsarecool.com")! // swiftlint:disable:this force_unwrapping
    XCTAssertFalse(
      gamingService.isValidCallbackURL(inValidURL, forService: ""),
      "Should return false if url parameter doesn't match the fb and appID prefix"
    )
  }

  func testCallWithArgumentSuccess() throws {
    gamingService.call(withArgument: "")
    let handler = try XCTUnwrap(urlOpener.capturedRequests.first)
    handler(true, nil)

    XCTAssertNil(serviceError, "Should not have an error if success is true")
  }

  func testCallWithArgumentNoSuccess() throws {
    gamingService.call(withArgument: "")
    let handler = try XCTUnwrap(urlOpener.capturedRequests.first)
    handler(false, nil)

    XCTAssertNotNil(serviceError, "Should have an error if success is false")
  }

  func testCallWithArgumentNoSuccessAndError() throws {
    gamingService.call(withArgument: "")
    let handler = try XCTUnwrap(urlOpener.capturedRequests.first)
    handler(false, SampleError())

    XCTAssertNotNil(serviceError, "Should have an error if success is false")
  }

  func testCallWithArgumentSuccessAndErrpr() throws {
    gamingService.call(withArgument: "")
    let handler = try XCTUnwrap(urlOpener.capturedRequests.first)
    handler(true, SampleError())

    XCTAssertNil(serviceError, "Should not have an error if success is true")
  }
}
