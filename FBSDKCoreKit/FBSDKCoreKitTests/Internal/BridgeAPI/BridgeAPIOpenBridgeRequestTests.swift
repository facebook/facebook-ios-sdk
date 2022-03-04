/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import Foundation
import SafariServices
import XCTest

final class BridgeAPIOpenBridgeRequestTests: XCTestCase {

  let sampleUrl = URL(string: "http://example.com")
  let urlOpener = TestInternalURLOpener(canOpenURL: true)
  let bridgeAPIResponseFactory = TestBridgeAPIResponseFactory()
  let frameworkLoader = TestDylibResolver()
  let appURLSchemeProvider = TestInternalUtility()
  let logger = TestLogger(loggingBehavior: .developerErrors)
  lazy var api = BridgeAPI(
    processInfo: TestProcessInfo(),
    logger: logger,
    urlOpener: urlOpener,
    bridgeAPIResponseFactory: bridgeAPIResponseFactory,
    frameworkLoader: frameworkLoader,
    appURLSchemeProvider: appURLSchemeProvider,
    errorFactory: TestErrorFactory()
  )

  // MARK: - URL Opening

  func testOpeningBridgeRequestWithRequestUrlUsingSafariVcWithFromVc() {
    frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.self
    let spy = ViewControllerSpy.makeDefaultSpy()
    let request = TestBridgeAPIRequest(url: sampleUrl)
    api.open(
      request,
      useSafariViewController: true,
      from: spy,
      completionBlock: uninvokedCompletionHandler()
    )

    XCTAssertTrue(api.pendingRequest === request)
    XCTAssertNotNil(api.pendingRequestCompletionBlock)

    XCTAssertNil(
      bridgeAPIResponseFactory.capturedResponseURL,
      "Should not create a bridge response"
    )
    XCTAssertTrue(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should try and load the safari view controller class"
    )
    XCTAssertEqual(
      api.safariViewController?.delegate as? BridgeAPI,
      api,
      "Should create a safari controller with the bridge as its delegate"
    )
  }

  func testOpeningBridgeRequestWithRequestUrlUsingSafariVcWithoutFromVc() {
    frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.self
    let request = TestBridgeAPIRequest(url: sampleUrl)
    api.open(
      request,
      useSafariViewController: true,
      from: nil,
      completionBlock: uninvokedCompletionHandler()
    )

    XCTAssertTrue(api.pendingRequest === request)
    XCTAssertNotNil(api.pendingRequestCompletionBlock)

    XCTAssertTrue(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should try and load the safari view controller class"
    )
    XCTAssertEqual(
      api.logger.contents,
      "There are no valid ViewController to present SafariViewController with"
    )
  }

  func testOpeningBridgeRequestWithRequestUrlNotUsingSafariVcWithFromVc() {
    frameworkLoader.stubSafariViewControllerClass = SFSafariViewController.self
    let spy = ViewControllerSpy.makeDefaultSpy()
    let request = TestBridgeAPIRequest(url: sampleUrl)
    api.open(
      request,
      useSafariViewController: false,
      from: spy,
      completionBlock: uninvokedCompletionHandler()
    )

    XCTAssertTrue(api.pendingRequest === request)
    XCTAssertNotNil(api.pendingRequestCompletionBlock)

    XCTAssertFalse(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should not try and load the safari view controller class when safari is not requested"
    )
  }

  func testOpeningBridgeRequestWithRequestUrlNotUsingSafariVcWithoutFromVc() {
    let request = TestBridgeAPIRequest(url: sampleUrl)
    api.open(
      request,
      useSafariViewController: false,
      from: nil,
      completionBlock: uninvokedCompletionHandler()
    )

    XCTAssertTrue(api.pendingRequest === request)
    XCTAssertNotNil(api.pendingRequestCompletionBlock)

    XCTAssertFalse(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should not try and load the safari view controller class when safari is not requested"
    )
  }

  func testOpeningBridgeRequestWithoutRequestUrlUsingSafariVcWithFromVc() {
    let spy = ViewControllerSpy.makeDefaultSpy()
    let request = TestBridgeAPIRequest(url: nil)

    let completionHandler: BridgeAPIResponseBlock = { response in
      XCTAssertEqual(
        response.request as? TestBridgeAPIRequest,
        request,
        "Should call the completion with a response that includes the original request"
      )
      XCTAssertTrue(
        response.error is FakeBridgeAPIRequestError,
        "Should call the completion with an error if the request cannot provide a url"
      )
    }

    api.open(
      request,
      useSafariViewController: true,
      from: spy,
      completionBlock: completionHandler
    )

    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )
    XCTAssertFalse(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should not try and load the safari view controller class when the request cannot provide a url"
    )
    assertPendingPropertiesNotSet()
  }

  func testOpeningBridgeRequestWithoutRequestUrlUsingSafariVcWithoutFromVc() {
    let request = TestBridgeAPIRequest(url: nil)

    let completionHandler: BridgeAPIResponseBlock = { response in
      XCTAssertEqual(
        response.request as? TestBridgeAPIRequest,
        request,
        "Should call the completion with a response that includes the original request"
      )
      XCTAssertTrue(
        response.error is FakeBridgeAPIRequestError,
        "Should call the completion with an error if the request cannot provide a url"
      )
    }
    api.open(
      request,
      useSafariViewController: true,
      from: nil,
      completionBlock: completionHandler
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )
    XCTAssertFalse(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should not try and load the safari view controller class when the request cannot provide a url"
    )
    assertPendingPropertiesNotSet()
  }

  func testOpeningBridgeRequestWithoutRequestUrlNotUsingSafariVcWithFromVc() {
    let spy = ViewControllerSpy.makeDefaultSpy()
    let request = TestBridgeAPIRequest(url: nil)

    let completionHandler: BridgeAPIResponseBlock = { response in
      XCTAssertEqual(
        response.request as? TestBridgeAPIRequest,
        request,
        "Should call the completion with a response that includes the original request"
      )
      XCTAssertTrue(
        response.error is FakeBridgeAPIRequestError,
        "Should call the completion with an error if the request cannot provide a url"
      )
    }

    api.open(
      request,
      useSafariViewController: false,
      from: spy,
      completionBlock: completionHandler
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )
    XCTAssertFalse(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should not try and load the safari view controller class when the request cannot provide a url"
    )
    assertPendingPropertiesNotSet()
  }

  func testOpeningBridgeRequestWithoutRequestUrlNotUsingSafariVcWithoutFromVc() {
    let request = TestBridgeAPIRequest(url: nil)

    let completionHandler: BridgeAPIResponseBlock = { response in
      XCTAssertEqual(
        response.request as? TestBridgeAPIRequest,
        request,
        "Should call the completion with a response that includes the original request"
      )
      XCTAssertTrue(
        response.error is FakeBridgeAPIRequestError,
        "Should call the completion with an error if the request cannot provide a url"
      )
    }
    api.open(
      request,
      useSafariViewController: false,
      from: nil,
      completionBlock: completionHandler
    )
    XCTAssertNil(
      urlOpener.capturedOpenURL,
      "Should not try to open a url when the request cannot provide one"
    )
    XCTAssertFalse(
      frameworkLoader.didLoadSafariViewControllerClass,
      "Should not try and load the safari view controller class when the request cannot provide a url"
    )
    assertPendingPropertiesNotSet()
  }

  // MARK: - Helpers

  func assertPendingPropertiesNotSet() {
    XCTAssertNil(
      api.pendingRequest,
      "Should not set a pending request if the bridge request does not have a request url"
    )
    XCTAssertNil(
      api.pendingRequestCompletionBlock,
      "Should not set a pending request completion block if the bridge request does not have a request url"
    )
  }

  func uninvokedCompletionHandler() -> BridgeAPIResponseBlock {
    { _ in
      XCTFail("Should not invoke the completion handler")
    }
  }
}
