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
  var dialog: MessageDialog!
  var shareDialogConfiguration: TestShareDialogConfiguration!
  var delegate: TestSharingDelegate!

  // Type dependencies
  var accessTokenWallet: TestAccessTokenWallet.Type!
  var bridgeAPIRequestFactory: TestBridgeAPIRequestFactory!
  var bridgeAPIRequestOpener: TestBridgeAPIRequestOpener!
  var errorFactory: TestErrorFactory!
  var eventLogger: TestShareEventLogger!
  var internalUtility: TestInternalUtility!
  var shareUtility: TestShareUtility.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    accessTokenWallet = TestAccessTokenWallet.self
    accessTokenWallet.current = SampleAccessTokens.validToken
    bridgeAPIRequestFactory = TestBridgeAPIRequestFactory()
    bridgeAPIRequestOpener = TestBridgeAPIRequestOpener()
    errorFactory = TestErrorFactory()
    eventLogger = TestShareEventLogger()
    internalUtility = TestInternalUtility()
    shareUtility = TestShareUtility.self
    MessageDialog.setDependencies(
      .init(
        accessTokenWallet: accessTokenWallet,
        bridgeAPIRequestFactory: bridgeAPIRequestFactory,
        bridgeAPIRequestOpener: bridgeAPIRequestOpener,
        errorFactory: errorFactory,
        eventLogger: eventLogger,
        internalUtility: internalUtility,
        shareUtility: shareUtility
      )
    )

    shareDialogConfiguration = TestShareDialogConfiguration()
    delegate = TestSharingDelegate()
    dialog = MessageDialog(
      content: nil,
      delegate: delegate,
      shareDialogConfiguration: shareDialogConfiguration
    )
  }

  override func tearDown() {
    accessTokenWallet = nil
    TestAccessTokenWallet.reset()
    bridgeAPIRequestFactory = nil
    bridgeAPIRequestOpener = nil
    errorFactory = nil
    eventLogger = nil
    internalUtility = nil
    shareUtility = nil
    TestShareUtility.reset()
    MessageDialog.resetDependencies()

    shareDialogConfiguration = nil
    delegate = nil
    dialog = nil

    super.tearDown()
  }

  func testDefaultTypeDependencies() throws {
    MessageDialog.resetDependencies()
    let dependencies = try MessageDialog.getDependencies()

    XCTAssertTrue(
      dependencies.accessTokenWallet is AccessToken.Type,
      .defaultDependency("AccessToken", for: "access token wallet")
    )
    XCTAssertTrue(
      dependencies.bridgeAPIRequestFactory is ShareBridgeAPIRequestFactory,
      .defaultDependency("a bridge API request factory", for: "bridge API request factory")
    )
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      BridgeAPI.shared,
      .defaultDependency("the shared BridgeAPI", for: "bridge API request opening")
    )
    XCTAssertTrue(
      dependencies.errorFactory is ErrorFactory,
      .defaultDependency("a concrete error factory", for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      AppEvents.shared,
      .defaultDependency("the shared AppEvents", for: "event logging")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      InternalUtility.shared,
      .defaultDependency("the shared InternalUtility", for: "internal utility")
    )
    XCTAssertTrue(
      dependencies.shareUtility is _ShareUtility.Type,
      .defaultDependency("_ShareUtility", for: "share utility")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try MessageDialog.getDependencies()

    XCTAssertIdentical(
      dependencies.accessTokenWallet,
      accessTokenWallet,
      .customDependency(for: "access token wallet")
    )
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestFactory,
      bridgeAPIRequestFactory,
      .customDependency(for: "bridge API request factory")
    )
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      bridgeAPIRequestOpener,
      .customDependency(for: "bridge API request opening")
    )
    XCTAssertIdentical(
      dependencies.errorFactory,
      errorFactory,
      .customDependency(for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      eventLogger,
      .customDependency(for: "event logging")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      internalUtility,
      .customDependency(for: "internal utility")
    )
    XCTAssertTrue(
      dependencies.shareUtility is TestShareUtility.Type,
      .customDependency(for: "share utility")
    )
  }

  func testCanShow() {
    shareDialogConfiguration.stubbedShouldUseNativeDialog = true
    internalUtility.isMessengerAppInstalled = true
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertTrue(dialog.canShow)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertTrue(dialog.canShow)

    internalUtility.isMessengerAppInstalled = false
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

  func testShowInvokesDelegateWhenCannotShow() throws {
    shareDialogConfiguration.stubbedShouldUseNativeDialog = true
    internalUtility.isMessengerAppInstalled = false
    dialog.show()

    let error = try XCTUnwrap(delegate.sharerDidFailError as? TestSDKError, .failureIsHandled)
    XCTAssertEqual(error.type, .general, .failureIsHandled)
    XCTAssertEqual(error.domain, ShareErrorDomain, .failureIsHandled)
    XCTAssertEqual(error.code, ShareError.dialogNotAvailable.rawValue, .failureIsHandled)
    XCTAssertTrue(error.userInfo.isEmpty, .failureIsHandled)
    XCTAssertEqual(error.message, "Message dialog is not available.", .failureIsHandled)
    XCTAssertNil(error.underlyingError, .failureIsHandled)
  }

  func testShowInvokesDelegateWhenMissingContent() throws {
    shareDialogConfiguration.stubbedShouldUseNativeDialog = true
    internalUtility.isMessengerAppInstalled = true
    dialog.show()

    let error = try XCTUnwrap(delegate.sharerDidFailError as? TestSDKError, .failureIsHandled)
    XCTAssertEqual(error.type, .requiredArgument, .failureIsHandled)
    XCTAssertEqual(error.domain, ShareErrorDomain, .failureIsHandled)
    XCTAssertEqual(error.code, TestSDKError.testErrorCode, .failureIsHandled)
    XCTAssertTrue(error.userInfo.isEmpty, .failureIsHandled)
    XCTAssertNil(error.message, .failureIsHandled)
    XCTAssertEqual(error.name, "shareContent", .failureIsHandled)
    XCTAssertNil(error.underlyingError, .failureIsHandled)
  }

  func testShowInvokesDelegateWhenCannotValidate() throws {
    dialog = MessageDialog(
      content: ShareModelTestUtility.cameraEffectContent,
      delegate: delegate,
      shareDialogConfiguration: shareDialogConfiguration
    )

    shareDialogConfiguration.stubbedShouldUseNativeDialog = true
    internalUtility.isMessengerAppInstalled = true

    dialog.show()

    let error = try XCTUnwrap(delegate.sharerDidFailError as? TestSDKError, .failureIsHandled)
    XCTAssertEqual(error.type, .requiredArgument, .failureIsHandled)
    XCTAssertEqual(error.domain, ShareErrorDomain, .failureIsHandled)
    XCTAssertEqual(error.code, TestSDKError.testErrorCode, .failureIsHandled)
    XCTAssertTrue(error.userInfo.isEmpty, .failureIsHandled)
    XCTAssertEqual(error.message, "Message dialog does not support ShareCameraEffectContent.", .failureIsHandled)
    XCTAssertNil(error.underlyingError, .failureIsHandled)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The MessageDialog type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The MessageDialog type uses a custom \(type) dependency when provided"
  }

  static let failureIsHandled = "Failure is sent to a dialog's delegate and logged"
}
