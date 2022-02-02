/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

final class FriendFinderDialogTests: XCTestCase {
  let factory = TestGamingServiceControllerFactory()
  lazy var dialog = FriendFinderDialog(gamingServiceControllerFactory: factory)
  let bridgeAPIError = NSError(domain: ErrorDomain, code: CoreError.errorBridgeAPIInterruption.rawValue, userInfo: nil)

  override func setUp() {
    super.setUp()

    ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
    AccessToken.current = SampleAccessTokens.validToken
  }

  override func tearDown() {
    AccessToken.current = nil

    super.tearDown()
  }

  // MARK: - Dependencies

  func testDefaultDependencies() {
    XCTAssertTrue(
      FriendFinderDialog.shared.factory is GamingServiceControllerFactory,
      "Should use the expected default gaming service controller factory type by default"
    )
  }

  // MARK: - Launching Dialogs

  func testFailureWhenNoValidAccessTokenPresentAndAppIDIsNull() {
    AccessToken.current = nil
    Settings.shared.appID = nil

    var completionCalled = false
    dialog.launch { _, error in
      XCTAssertEqual(
        (error as NSError?)?.code,
        CoreError.errorAccessTokenRequired.rawValue,
        "Expected error requiring a valid access token"
      )
      completionCalled = true
    }

    XCTAssertTrue(completionCalled)
  }

  func testPresentationWhenTokenIsNilAndAppIDIsSet() {
    AccessToken.current = nil
    Settings.shared.appID = "appID"

    var didInvokeCompletion = false
    dialog.launch { success, _ in
      XCTAssertTrue(success)
      didInvokeCompletion = true
    }
    XCTAssertEqual(
      factory.controller.capturedArgument,
      Settings.shared.appID,
      "Should invoke the new controller with the app id in the sdk setting"
    )
    factory.capturedCompletion(true, nil, nil)
    XCTAssertTrue(didInvokeCompletion)
  }

  func testPresentationWhenTokenIsSetAndAppIDIsNil() {
    Settings.shared.appID = nil

    var didInvokeCompletion = false
    dialog.launch { _, _ in
      didInvokeCompletion = true
    }

    XCTAssertEqual(
      factory.capturedServiceType,
      .friendFinder,
      "Should create a controller with the expected service type"
    )
    XCTAssertNil(
      factory.capturedPendingResult,
      "Should not create a controller with a pending result"
    )
    XCTAssertEqual(
      factory.controller.capturedArgument,
      AccessToken.current?.appID,
      "Should invoke the new controller with the app id of the current access token"
    )
    XCTAssertNotNil(AccessToken.current?.appID)

    factory.capturedCompletion(true, nil, nil)

    XCTAssertTrue(didInvokeCompletion)
  }

  func testFailuresReturnAnError() {
    var didInvokeCompletion = false
    dialog.launch { success, error in
      XCTAssertFalse(success)
      XCTAssertEqual(
        (error as NSError?)?.code,
        CoreError.errorBridgeAPIInterruption.rawValue,
        "Expected errorBridgeAPIInterruption error"
      )
      didInvokeCompletion = true
    }

    XCTAssertEqual(
      factory.capturedServiceType,
      .friendFinder,
      "Should create a controller with the expected service type"
    )
    XCTAssertNil(
      factory.capturedPendingResult,
      "Should not create a controller with a pending result"
    )
    XCTAssertEqual(
      factory.controller.capturedArgument,
      AccessToken.current?.appID,
      "Should invoke the new controller with the app id of the current access token"
    )
    XCTAssertNotNil(AccessToken.current?.appID)

    factory.capturedCompletion(false, nil, bridgeAPIError)

    XCTAssertTrue(didInvokeCompletion)
  }

  func testHandlingOfCallbackURL() {
    var completionCalled = false
    dialog.launch { success, _ in
      XCTAssertTrue(success)
      completionCalled = true
    }

    factory.capturedCompletion(true, nil, nil)

    XCTAssertTrue(completionCalled)
  }
}
