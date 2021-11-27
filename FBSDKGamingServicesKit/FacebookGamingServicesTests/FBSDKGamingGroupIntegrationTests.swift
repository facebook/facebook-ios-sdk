/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
      GamingGroupIntegration().serviceControllerFactory is _GamingServiceControllerFactory,
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
