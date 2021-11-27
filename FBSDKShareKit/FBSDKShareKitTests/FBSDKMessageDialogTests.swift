/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class FBSDKMessageDialogTests: XCTestCase {

  enum Assumptions {
    static let contentValidation = """
      Known valid content should pass validation without issue. \
      If this test fails then the criteria for the fixture may no longer be valid
      """
  }

  // swiftlint:disable implicitly_unwrapped_optional
  var appAvailabilityChecker: TestInternalUtility!
  var shareDialogConfiguration: TestShareDialogConfiguration!
  var delegate: TestSharingDelegate!
  var dialog: MessageDialog!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    appAvailabilityChecker = TestInternalUtility()
    shareDialogConfiguration = TestShareDialogConfiguration()
    delegate = TestSharingDelegate()

    dialog = MessageDialog(
      content: nil,
      delegate: delegate,
      appAvailabilityChecker: appAvailabilityChecker,
      shareDialogConfiguration: shareDialogConfiguration
    )
  }

  override func tearDown() {
    appAvailabilityChecker = nil
    shareDialogConfiguration = nil
    delegate = nil
    dialog = nil

    super.tearDown()
  }

  func testCanShow() {
    shareDialogConfiguration.stubbedShouldUseNativeDialogCompletion = true
    appAvailabilityChecker.isMessengerAppInstalled = true
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.linkContent()
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.photoContent()
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto()
    XCTAssertTrue(dialog.canShow)

    appAvailabilityChecker.isMessengerAppInstalled = false
    XCTAssertFalse(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.linkContent()
    XCTAssertFalse(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.photoContent()
    XCTAssertFalse(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto()
    XCTAssertFalse(dialog.canShow)
  }

  func testValidate() {
    dialog = MessageDialog()

    dialog.shareContent = ShareModelTestUtility.linkContent()
    XCTAssertNoThrow(try dialog.validate(), Assumptions.contentValidation)

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages()
    XCTAssertNoThrow(try dialog.validate(), Assumptions.contentValidation)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto()
    XCTAssertNoThrow(try dialog.validate(), Assumptions.contentValidation)

    dialog.shareContent = ShareModelTestUtility.cameraEffectContent()
    XCTAssertNil(
      try? dialog.validate(),
      "Should not successfully validate share content that is known to be missing content"
    )
  }

  func testShowInvokesDelegateWhenCannotShow() {
    shareDialogConfiguration.stubbedShouldUseNativeDialogCompletion = true
    appAvailabilityChecker.isMessengerAppInstalled = false
    dialog.show()

    let error = NSError(
      domain: ShareErrorDomain,
      code: ShareError.dialogNotAvailable.rawValue,
      userInfo: [ErrorDeveloperMessageKey: "Message dialog is not available."]
    )
    XCTAssertEqual(delegate.capturedError as NSError?, error)
  }

  func testShowInvokesDelegateWhenMissingContent() {
    shareDialogConfiguration.stubbedShouldUseNativeDialogCompletion = true
    appAvailabilityChecker.isMessengerAppInstalled = true
    dialog.show()

    let error = NSError(
      domain: ShareErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      userInfo: [
        ErrorArgumentNameKey: "shareContent",
        ErrorDeveloperMessageKey: "Value for shareContent is required."]
    )
    XCTAssertEqual(delegate.capturedError as NSError?, error)
  }

  func testShowInvokesDelegateWhenCannotValidate() {
    dialog = MessageDialog(
      content: ShareModelTestUtility.cameraEffectContent(),
      delegate: delegate,
      appAvailabilityChecker: appAvailabilityChecker,
      shareDialogConfiguration: shareDialogConfiguration
    )

    shareDialogConfiguration.stubbedShouldUseNativeDialogCompletion = true
    appAvailabilityChecker.isMessengerAppInstalled = true

    dialog.show()

    let error = NSError(
      domain: ShareErrorDomain,
      code: CoreError.errorInvalidArgument.rawValue,
      userInfo: [
        ErrorArgumentNameKey: "shareContent",
        ErrorDeveloperMessageKey: "Message dialog does not support FBSDKShareCameraEffectContent."]
    )
    XCTAssertEqual(delegate.capturedError as NSError?, error)
  }
}
