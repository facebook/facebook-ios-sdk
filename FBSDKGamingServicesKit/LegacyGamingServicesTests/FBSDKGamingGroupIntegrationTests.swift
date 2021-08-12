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

import XCTest

class FBSDKGamingGroupIntegrationTests: XCTestCase {

  let factory = TestGamingServiceControllerFactory()
  let settings = TestSettings()
  lazy var integration = GamingGroupIntegration(
    settings: settings,
    serviceControllerFactory: factory
  )

  func testDefaultDependencies() {
    XCTAssertTrue(
      GamingGroupIntegration().settings is Settings,
      "Should have a default settings of the expected type"
    )
    XCTAssertTrue(
      GamingGroupIntegration().serviceControllerFactory is GamingServiceControllerFactory,
      "Should have a default service controller factory of the expected type"
    )
  }

  func testCustomDependencies() {
    XCTAssertEqual(
      integration.serviceControllerFactory as? TestGamingServiceControllerFactory,
      factory,
      "Should be able to create with a custom service controller factory"
    )
  }

  func testOpeningPageWithMissingIdentifier() {
    settings.appID = nil
    integration.openGroupPage { _, _ in }

    XCTAssertEqual(
      factory.controller.capturedArgument,
      settings.appID,
      "Should call the controller with the app identifier from the settings"
    )
  }

  func testOpeningPageWithIdentifier() {
    settings.appID = name
    integration.openGroupPage { _, _ in }

    XCTAssertEqual(
      factory.controller.capturedArgument,
      settings.appID,
      "Should call the controller with the app identifier from the settings"
    )
  }

  func testOpeningPageWithErrorAndFailure() throws {
    var didInvokeCompletion = false
    integration.openGroupPage { success, error in
      XCTAssertFalse(
        success,
        "Should not be considered successful if there is a service controller error"
      )
      XCTAssertTrue(
        error is SampleError,
        "Should pass through the error from the service controller"
      )
      didInvokeCompletion = true
    }

    let completion = try XCTUnwrap(factory.capturedCompletion)
    completion(false, nil, SampleError())

    XCTAssertTrue(didInvokeCompletion)
  }

  func testOpeningPageWithSuccessOrFailureOnly() throws {
    try [true, false].forEach { didSucceed in
      var didInvokeCompletion = false
      integration.openGroupPage { success, error in
        XCTAssertEqual(
          success,
          didSucceed,
          "Should pass through the success response from the service controller"
        )
        XCTAssertNil(error)
        didInvokeCompletion = true
      }

      let completion = try XCTUnwrap(factory.capturedCompletion)
      completion(didSucceed, nil, nil)

      XCTAssertTrue(didInvokeCompletion)
    }
  }

  func testOpeningPageWithSuccessAndError() throws {
    var didInvokeCompletion = false
    integration.openGroupPage { success, error in
      XCTAssertTrue(
        success,
        "Should pass through the success response from the service controller even if there is an error"
      )
      XCTAssertTrue(
        error is SampleError,
        "Should pass through the error from the service controller"
      )
      didInvokeCompletion = true
    }

    let completion = try XCTUnwrap(factory.capturedCompletion)
    completion(true, nil, SampleError())

    XCTAssertTrue(didInvokeCompletion)
  }
}
