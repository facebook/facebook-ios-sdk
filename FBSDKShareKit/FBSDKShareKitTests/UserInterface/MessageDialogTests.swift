/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import TestTools
import XCTest

final class MessageDialogTests: XCTestCase {

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

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertTrue(dialog.canShow)

    appAvailabilityChecker.isMessengerAppInstalled = false
    XCTAssertFalse(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertFalse(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertFalse(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertFalse(dialog.canShow)
  }

  func testValidate() {
    dialog = MessageDialog()

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate(), Assumptions.contentValidation)

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertNoThrow(try dialog.validate(), Assumptions.contentValidation)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertNoThrow(try dialog.validate(), Assumptions.contentValidation)

    dialog.shareContent = ShareModelTestUtility.cameraEffectContent
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
    XCTAssertEqual(delegate.sharerDidFailError as NSError?, error)
  }

  func testShowInvokesDelegateWhenMissingContent() throws {
    shareDialogConfiguration.stubbedShouldUseNativeDialogCompletion = true
    appAvailabilityChecker.isMessengerAppInstalled = true
    dialog.show()

    let error = try XCTUnwrap(
      delegate.sharerDidFailError,
      "The delegate should receive a callback with an error"
    ) as NSError

    XCTAssertEqual(error.domain, ShareErrorDomain, "The share error domain should be used")
    XCTAssertEqual(error.code, CoreError.errorInvalidArgument.rawValue, "The invalid argument code should be included")

    XCTAssertEqual(
      error.userInfo[ErrorArgumentNameKey] as? String,
      "shareContent",
      "The argument name should be included"
    )
    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      "Value for shareContent is required.",
      "The invalid argument message should be used"
    )
  }

  func testShowInvokesDelegateWhenCannotValidate() throws {
    dialog = MessageDialog(
      content: ShareModelTestUtility.cameraEffectContent,
      delegate: delegate,
      appAvailabilityChecker: appAvailabilityChecker,
      shareDialogConfiguration: shareDialogConfiguration
    )

    shareDialogConfiguration.stubbedShouldUseNativeDialogCompletion = true
    appAvailabilityChecker.isMessengerAppInstalled = true

    dialog.show()

    let error = try XCTUnwrap(
      delegate.sharerDidFailError,
      "The delegate should receive a callback with an error"
    ) as NSError

    XCTAssertEqual(error.domain, ShareErrorDomain, "The share error domain should be used")
    XCTAssertEqual(error.code, CoreError.errorInvalidArgument.rawValue, "The invalid argument code should be included")

    XCTAssertEqual(
      error.userInfo[ErrorArgumentNameKey] as? String,
      "shareContent",
      "The argument name should be included"
    )
    XCTAssertEqual(
      error.userInfo[ErrorDeveloperMessageKey] as? String,
      "Message dialog does not support ShareCameraEffectContent.",
      "The invalid argument message should be used"
    )
  }
}
