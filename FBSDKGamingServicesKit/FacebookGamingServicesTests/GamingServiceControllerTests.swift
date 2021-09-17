// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FacebookGamingServices
import FBSDKCoreKit
import TestTools
import XCTest

class GamingServiceControllerTests: XCTestCase {

  let urlOpener = TestURLOpener()
  let settings = TestSettings()
  let url = URL(string: "fb123://community/")! // swiftlint:disable:this force_unwrapping
  var capturedSuccess = false
  var capturedResults = [Any]()
  var serviceError: Error?
  lazy var gamingService = GamingServiceController(
    serviceType: .community,
    completionHandler: { success, _, error in
      self.capturedSuccess = success
      self.serviceError = error
    },
    pendingResult: [:],
    urlOpener: urlOpener,
    settings: settings
  )

  override func setUp() {
    super.setUp()

    settings.appID = "123"
  }

  func testSuccessfullyOpeningURL() {
    gamingService.application(UIApplication.shared, open: url, sourceApplication: "", annotation: "")
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
      completionHandler: { success, _, error in
        self.capturedSuccess = success
        self.serviceError = error
      },
      pendingResult: [:],
      urlOpener: urlOpener,
      settings: settings
    )

    gamingService.application(UIApplication.shared, open: url, sourceApplication: "", annotation: "")
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
