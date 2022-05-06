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

  func testCreatingWithFactoryMethod() {
    let content = ShareModelTestUtility.linkContent
    dialog = MessageDialog.dialog(content: content, delegate: delegate)

    XCTAssertIdentical(dialog.shareContent, content, .factoryCreation)
    XCTAssertIdentical(dialog.delegate, delegate, .factoryCreation)
  }

  func testCreatingAndShowingWithFactoryMethod() {
    let content = ShareModelTestUtility.linkContent
    dialog = MessageDialog.show(content: content, delegate: delegate)

    XCTAssertIdentical(dialog.shareContent, content, .factoryCreation)
    XCTAssertIdentical(dialog.delegate, delegate, .factoryCreation)
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
    XCTAssertNoThrow(try dialog.validate(), .contentValidation)

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertNoThrow(try dialog.validate(), .contentValidation)

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertNoThrow(try dialog.validate(), .contentValidation)

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

  func testFailingToShowWithoutBridgeAPIRequest() {
    internalUtility.isMessengerAppInstalled = true
    shareDialogConfiguration.stubbedShouldUseNativeDialog = true
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertFalse(dialog.show(), .showingFailsWithoutBridgeAPIRequest)
  }

  func testShowingDialog() throws {
    shareDialogConfiguration.stubbedShouldUseNativeDialog = true
    shareDialogConfiguration.stubbedShouldUseSafariViewController = true
    internalUtility.isMessengerAppInstalled = true
    let parameters = ["key": "value"]
    TestShareUtility.stubbedBridgeParameters = parameters
    let request = TestBridgeAPIRequest()
    bridgeAPIRequestFactory.stubbedBridgeAPIRequest = request
    let content = ShareModelTestUtility.linkContent
    content.pageID = "foo"
    dialog.shareContent = content

    XCTAssertTrue(dialog.show(), .showingValidDialog)

    // Getting bridge parameters
    XCTAssertIdentical(shareUtility.capturedBridgeParametersShareContent, content, .showingValidDialog)
    let options = try XCTUnwrap(shareUtility.capturedBridgeParametersBridgeOptions, .showingValidDialog)
    XCTAssertTrue(options.isEmpty, .showingValidDialog)
    XCTAssertEqual(
      shareUtility.capturedBridgeParametersShouldFailOnDataError,
      dialog.shouldFailOnDataError,
      .showingValidDialog
    )

    // Creating bridge API request
    XCTAssertEqual(bridgeAPIRequestFactory.capturedProtocolType, .native, .showingValidDialog)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedScheme, URLScheme.messengerApp.rawValue, .showingValidDialog)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedMethodName, ShareBridgeAPI.MethodName.share, .showingValidDialog)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedParameters as? [String: String], parameters, .showingValidDialog)
    XCTAssertNil(bridgeAPIRequestFactory.capturedUserInfo, .showingValidDialog)

    // Opening bridge API request
    XCTAssertIdentical(bridgeAPIRequestOpener.capturedRequest, request, .showingValidDialog)
    XCTAssertEqual(
      bridgeAPIRequestOpener.capturedUseSafariViewController,
      shareDialogConfiguration.stubbedShouldUseSafariViewController,
      .showingValidDialog
    )
    XCTAssertNil(bridgeAPIRequestOpener.capturedFromViewController, .showingValidDialog)

    // Logging
    XCTAssertEqual(eventLogger.logInternalEventName, .shareDialogShow, .showingValidDialog)
    let expectedParameters: [AppEvents.ParameterName: String] = [
      .shareContentType: ShareAppEventsParameters.ContentTypeValue.status,
      .shareContentUUID: content.shareUUID!, // swiftlint:disable:this force_unwrapping
      .shareContentPageID: content.pageID!, // swiftlint:disable:this force_unwrapping
    ]
    XCTAssertEqual(
      eventLogger.logInternalEventParameters as? [AppEvents.ParameterName: String],
      expectedParameters,
      .showingValidDialog
    )
    XCTAssertTrue(eventLogger.logInternalEventIsImplicitlyLogged ?? false, .showingValidDialog)
    XCTAssertEqual(eventLogger.logInternalEventAccessToken, TestAccessTokenWallet.current, .showingValidDialog)

    // Completion
    let response = TestBridgeAPIResponse(request: request, error: nil)
    response.stubbedResponseParameters = parameters
    bridgeAPIRequestOpener.capturedCompletionBlock?(response)
    XCTAssertEqual(delegate?.sharerDidCompleteResults as? [String: String], parameters, .showingValidDialog)
    XCTAssertIdentical(internalUtility.unregisterTransientObjectObject as AnyObject, dialog, .showingValidDialog)
  }

  func testHandlingNormalCancellation() {
    let request = TestBridgeAPIRequest()
    let response = TestBridgeAPIResponse(cancelledWith: request)

    dialog.handleCompletion(dialogResults: [:], response: response)

    XCTAssertEqual(eventLogger.logInternalEventName, .messengerShareDialogResult, .cancellationIsHandled)
    XCTAssertEqual(
      eventLogger.logInternalEventParameters as? [AppEvents.ParameterName: String],
      [.outcome: ShareAppEventsParameters.DialogOutcomeValue.cancelled],
      .cancellationIsHandled
    )
    XCTAssertTrue(eventLogger.logInternalEventIsImplicitlyLogged ?? false, .cancellationIsHandled)
    XCTAssertIdentical(eventLogger.logInternalEventAccessToken, accessTokenWallet.current, .cancellationIsHandled)
    XCTAssertIdentical(delegate.sharerDidCancelSharer as AnyObject, dialog, .cancellationIsHandled)
  }

  func testHandlingCancellationViaGesture() {
    let request = TestBridgeAPIRequest()
    let response = TestBridgeAPIResponse(request: request, error: nil)
    let results = [ShareBridgeAPI.CompletionGesture.key: ShareBridgeAPI.CompletionGesture.cancelValue]
    dialog.handleCompletion(dialogResults: results, response: response)

    XCTAssertEqual(eventLogger.logInternalEventName, .messengerShareDialogResult, .cancellationIsHandled)
    XCTAssertEqual(
      eventLogger.logInternalEventParameters as? [AppEvents.ParameterName: String],
      [.outcome: ShareAppEventsParameters.DialogOutcomeValue.cancelled],
      .cancellationIsHandled
    )
    XCTAssertTrue(eventLogger.logInternalEventIsImplicitlyLogged ?? false, .cancellationIsHandled)
    XCTAssertIdentical(eventLogger.logInternalEventAccessToken, accessTokenWallet.current, .cancellationIsHandled)
    XCTAssertIdentical(delegate.sharerDidCancelSharer as AnyObject, dialog, .cancellationIsHandled)
  }

  func testHandlingFailure() {
    let request = TestBridgeAPIRequest()
    let error = SampleError()
    let response = TestBridgeAPIResponse(request: request, error: error)
    dialog.handleCompletion(dialogResults: [:], response: response)

    XCTAssertEqual(eventLogger.logInternalEventName, .shareDialogResult, .failureIsHandled)
    XCTAssertEqual(
      eventLogger.logInternalEventParameters as? [AppEvents.ParameterName: String],
      [
        .outcome: ShareAppEventsParameters.DialogOutcomeValue.failed,
        .errorMessage: String(describing: error),
      ],
      .failureIsHandled
    )
    XCTAssertTrue(eventLogger.logInternalEventIsImplicitlyLogged ?? false, .failureIsHandled)
    XCTAssertIdentical(eventLogger.logInternalEventAccessToken, accessTokenWallet.current, .failureIsHandled)
    XCTAssertIdentical(delegate.sharerDidFailSharer as AnyObject, dialog, .failureIsHandled)
    XCTAssertEqual(delegate.sharerDidFailError as? SampleError, error, .failureIsHandled)
  }

  func testHandlingSuccess() {
    let request = TestBridgeAPIRequest()
    let response = TestBridgeAPIResponse(request: request, error: nil)
    let results = ["key": "value"]
    dialog.handleCompletion(dialogResults: results, response: response)

    XCTAssertEqual(eventLogger.logInternalEventName, .messengerShareDialogResult, .successIsHandled)
    XCTAssertEqual(
      eventLogger.logInternalEventParameters as? [AppEvents.ParameterName: String],
      [.outcome: ShareAppEventsParameters.DialogOutcomeValue.completed],
      .successIsHandled
    )
    XCTAssertTrue(eventLogger.logInternalEventIsImplicitlyLogged ?? false, .successIsHandled)
    XCTAssertIdentical(eventLogger.logInternalEventAccessToken, accessTokenWallet.current, .successIsHandled)
    XCTAssertIdentical(delegate.sharerDidCompleteSharer as AnyObject, dialog, .successIsHandled)
    XCTAssertEqual(delegate.sharerDidCompleteResults as? [String: String], results, .successIsHandled)
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

  static let factoryCreation = "A dialog can be created using a factory method"

  static let contentValidation = """
    Known valid content passes validation without issue. \
    When this test fails then the criteria for the fixture may no longer be valid.
    """

  static let cancellationIsHandled = "Cancellation is sent to a dialog's delegate and logged"
  static let failureIsHandled = "Failure is sent to a dialog's delegate and logged"
  static let successIsHandled = "Success is sent to a dialog's delegate and logged"
  static let showingFailsWithoutBridgeAPIRequest = "A dialog does not show if a bridge API request cannot be created"
  static let showingValidDialog = "A dialog shows valid content by creating a bridge API request an opening it"
}
