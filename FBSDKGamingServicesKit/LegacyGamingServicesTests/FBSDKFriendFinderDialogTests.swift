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

import TestTools

class FBSDKFriendFinderDialogTests: XCTestCase {
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
    Settings.appID = nil

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
    Settings.appID = "appID"

    var didInvokeCompletion = false
    dialog.launch { success, _ in
      XCTAssertTrue(success)
      didInvokeCompletion = true
    }
    XCTAssertEqual(
      factory.controller.capturedArgument,
      Settings.appID,
      "Should invoke the new controller with the app id in the sdk setting"
    )
    factory.capturedCompletion(true, nil, nil)
    XCTAssertTrue(didInvokeCompletion)
  }

  func testPresentationWhenTokenIsSetAndAppIDIsNil() {
    Settings.appID = nil

    var didInvokeCompletion = false
    dialog.launch { _, _ in
      didInvokeCompletion = true
    }

    XCTAssertEqual(
      factory.capturedServiceType,
      GamingServiceType.friendFinder,
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
      GamingServiceType.friendFinder,
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
