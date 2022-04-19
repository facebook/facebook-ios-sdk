/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import Photos
import TestTools
import UIKit
import XCTest

final class ShareDialogTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var dialog: ShareDialog!
  var delegate: TestSharingDelegate!
  var internalURLOpener: TestInternalURLOpener!
  var internalUtility: TestInternalUtility!
  var settings: TestSettings!
  var bridgeAPIRequestFactory: TestBridgeAPIRequestFactory!
  var bridgeAPIRequestOpener: TestBridgeAPIRequestOpener!
  var socialComposeViewController: TestSocialComposeViewController!
  var socialComposeViewControllerFactory: TestSocialComposeViewControllerFactory!
  var windowFinder: TestWindowFinder!
  var errorFactory: TestErrorFactory!
  var eventLogger: TestShareEventLogger!
  var mediaLibrarySearcher: TestMediaLibrarySearcher!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AccessToken.current = nil
    TestShareUtility.reset()

    delegate = TestSharingDelegate()
    internalURLOpener = TestInternalURLOpener()
    internalUtility = TestInternalUtility()
    settings = TestSettings()
    bridgeAPIRequestFactory = TestBridgeAPIRequestFactory()
    bridgeAPIRequestOpener = TestBridgeAPIRequestOpener()
    socialComposeViewController = TestSocialComposeViewController()
    socialComposeViewControllerFactory = TestSocialComposeViewControllerFactory()
    socialComposeViewControllerFactory.stubbedSocialComposeViewController = socialComposeViewController
    windowFinder = TestWindowFinder()
    errorFactory = TestErrorFactory()
    eventLogger = TestShareEventLogger()
    mediaLibrarySearcher = TestMediaLibrarySearcher()

    ShareDialog.setDependencies(
      .init(
        internalURLOpener: internalURLOpener,
        internalUtility: internalUtility,
        settings: settings,
        shareUtility: TestShareUtility.self,
        bridgeAPIRequestFactory: bridgeAPIRequestFactory,
        bridgeAPIRequestOpener: bridgeAPIRequestOpener,
        socialComposeViewControllerFactory: socialComposeViewControllerFactory,
        windowFinder: windowFinder,
        errorFactory: errorFactory,
        eventLogger: eventLogger,
        mediaLibrarySearcher: mediaLibrarySearcher
      )
    )

    ShareCameraEffectContent.setDependencies(
      .init(
        internalUtility: internalUtility,
        errorFactory: errorFactory
      )
    )
  }

  override func tearDown() {
    dialog = nil
    internalURLOpener = nil
    internalUtility = nil
    settings = nil
    bridgeAPIRequestFactory = nil
    bridgeAPIRequestOpener = nil
    socialComposeViewController = nil
    socialComposeViewControllerFactory = nil
    windowFinder = nil
    errorFactory = nil
    eventLogger = nil
    mediaLibrarySearcher = nil

    ShareDialog.resetDependencies()
    TestShareUtility.reset()
    ShareCameraEffectContent.resetDependencies()
    AccessToken.current = nil

    super.tearDown()
  }

  // MARK: - Type Dependencies

  func testDefaultDependencies() throws {
    ShareDialog.resetDependencies()

    let dependencies = try ShareDialog.getDependencies()
    XCTAssertIdentical(
      dependencies.internalURLOpener,
      ShareUIApplication.shared,
      .DefaultDependencies.usesInternalURLOpenerByDefault
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      InternalUtility.shared,
      .DefaultDependencies.usesInternalUtilityByDefault
    )
    XCTAssertIdentical(dependencies.settings, Settings.shared, .DefaultDependencies.usesSettingsByDefault)
    XCTAssertTrue(dependencies.shareUtility is _ShareUtility.Type, .DefaultDependencies.usesShareUtilityByDefault)
    XCTAssertTrue(
      dependencies.bridgeAPIRequestFactory is ShareBridgeAPIRequestFactory,
      .DefaultDependencies.usesShareBridgeAPIRequestFactoryByDefault
    )
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      BridgeAPI.shared,
      .DefaultDependencies.usesBridgeAPIByDefault
    )
    XCTAssertTrue(
      dependencies.socialComposeViewControllerFactory is SocialComposeViewControllerFactory,
      .DefaultDependencies.usesSocialComposeViewControllerFactoryByDefault
    )
    XCTAssertIdentical(
      dependencies.windowFinder,
      InternalUtility.shared,
      .DefaultDependencies.usesInternalUtilityAsWindowFinderByDefault
    )
    XCTAssertTrue(dependencies.errorFactory is ErrorFactory, .DefaultDependencies.usesErrorFactoryByDefault)
    XCTAssertIdentical(
      dependencies.eventLogger as AnyObject,
      AppEvents.shared,
      .DefaultDependencies.usesAppEventsByDefault
    )
    XCTAssertIdentical(
      dependencies.mediaLibrarySearcher as AnyObject,
      PHImageManager.default(),
      .DefaultDependencies.usesPHImageManagerAsMediaLibrarySearcherByDefault
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try ShareDialog.getDependencies()

    XCTAssertIdentical(
      dependencies.internalURLOpener,
      internalURLOpener,
      .CustomDependencies.usesCustomInternalURLOpener
    )
    XCTAssertIdentical(dependencies.internalUtility, internalUtility, .CustomDependencies.usesCustomInternalUtility)
    XCTAssertIdentical(dependencies.settings, settings, .CustomDependencies.usesCustomSettings)
    XCTAssertTrue(dependencies.shareUtility is TestShareUtility.Type, .CustomDependencies.usesCustomShareUtility)
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestFactory,
      bridgeAPIRequestFactory,
      .CustomDependencies.usesCustomShareBridgeAPIRequestFactory
    )
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      bridgeAPIRequestOpener,
      .CustomDependencies.usesCustomBridgeAPIRequestOpener
    )
    XCTAssertIdentical(
      dependencies.socialComposeViewControllerFactory as AnyObject,
      socialComposeViewControllerFactory,
      .CustomDependencies.usesCustomSocialComposeViewControllerFactory
    )
    XCTAssertIdentical(dependencies.windowFinder, windowFinder, .CustomDependencies.usesCustomWindowFinder)
    XCTAssertIdentical(dependencies.errorFactory, errorFactory, .CustomDependencies.usesCustomErrorFactory)
    XCTAssertIdentical(dependencies.eventLogger as AnyObject, eventLogger, .CustomDependencies.usesCustomEventLogger)
    XCTAssertIdentical(
      dependencies.mediaLibrarySearcher as AnyObject,
      mediaLibrarySearcher,
      .CustomDependencies.usesCustomMediaLibrarySearcher
    )
  }

  // MARK: - Construction

  func testInitializer() {
    let controller = UIViewController()
    let content = ShareModelTestUtility.linkContent
    let delegate = TestSharingDelegate()
    dialog = ShareDialog(viewController: controller, content: content, delegate: delegate)

    XCTAssertIdentical(dialog.fromViewController, controller, .Construction.createViaClassFactoryMethod)
    XCTAssertIdentical(dialog.shareContent, content, .Construction.createViaClassFactoryMethod)
    XCTAssertIdentical(dialog.delegate, delegate, .Construction.createViaClassFactoryMethod)
  }

  func testClassFactoryMethod() {
    let controller = UIViewController()
    let content = ShareModelTestUtility.linkContent
    let delegate = TestSharingDelegate()
    dialog = ShareDialog.dialog(viewController: controller, content: content, delegate: delegate)

    XCTAssertIdentical(dialog.fromViewController, controller, .Construction.createViaClassFactoryMethod)
    XCTAssertIdentical(dialog.shareContent, content, .Construction.createViaClassFactoryMethod)
    XCTAssertIdentical(dialog.delegate, delegate, .Construction.createViaClassFactoryMethod)
  }

  func testClassShowMethod() {
    let controller = UIViewController()
    let content = ShareModelTestUtility.linkContent
    let delegate = TestSharingDelegate()
    dialog = ShareDialog.show(viewController: controller, content: content, delegate: delegate)

    XCTAssertIdentical(dialog.fromViewController, controller, .Construction.createViaClassShowMethod)
    XCTAssertIdentical(dialog.shareContent, content, .Construction.createViaClassShowMethod)
    XCTAssertIdentical(dialog.delegate, delegate, .Construction.createViaClassShowMethod)
  }

  // MARK: - Native mode

  func testCanShowNativeDialogWithoutShareContent() {
    dialog = createEmptyDialog(mode: .native)
    internalURLOpener.canOpenURL = true
    internalUtility.isFacebookAppInstalled = true

    XCTAssertTrue(
      dialog.canShow,
      "A dialog without share content should be showable on a native dialog"
    )
  }

  func testCanShowNativeLinkContent() {
    dialog = createEmptyDialog(mode: .native)
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with valid link content should be showable on a native dialog"
    )
  }

  func testCanShowNativePhotoContent() {
    dialog = createEmptyDialog(mode: .native)
    dialog.shareContent = ShareModelTestUtility.photoContent
    TestShareUtility.validateShareContentShouldThrow = true

    XCTAssertFalse(
      dialog.canShow,
      "Photo content with photos that have web urls should not be showable on a native dialog"
    )
  }

  func testCanShowNativePhotoContentWithFileURL() {
    dialog = createEmptyDialog(mode: .native)
    dialog.shareContent = ShareModelTestUtility.photoContentWithFileURLs
    XCTAssertTrue(
      dialog.canShow,
      "Photo content with photos that have file urls should be showable on a native dialog"
    )
  }

  func testCanShowNativeVideoContentWithoutPreviewPhoto() {
    dialog = createEmptyDialog(mode: .native)
    internalURLOpener.canOpenURL = true
    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto

    XCTAssertTrue(
      dialog.canShow,
      "Video content without a preview photo should be showable on a native dialog"
    )
  }

  func testCanShowNative() {
    dialog = createEmptyDialog(mode: .native)

    XCTAssertFalse(
      dialog.canShow,
      "A native dialog should not be showable if the application is unable to open a url, this can also occur if the api scheme is not whitelisted in the third party app or if the application cannot handle the share API scheme" // swiftlint:disable:this line_length
    )
  }

  func testShowNativeDoesValidate() {
    dialog = createEmptyDialog(mode: .native)
    dialog.shareContent = ShareModelTestUtility.photoContent
    internalURLOpener.canOpenURL = true

    XCTAssertFalse(dialog.show())
  }

  // MARK: - Browser mode

  func testCanShowBrowser() {
    dialog = createEmptyDialog(mode: .browser)
    XCTAssertTrue(
      dialog.canShow,
      "A dialog without share content should be showable in a browser"
    )

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with link content should be showable in a browser"
    )

    AccessToken.current = SampleAccessTokens.validToken
    dialog.shareContent = ShareModelTestUtility.photoContentWithFileURLs
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with photo content with file urls should be showable in a browser when there is a current access token"
    )

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with video content without a preview photo should be showable in a browser when there is a current access token" // swiftlint:disable:this line_length
    )
  }

  func testValidateBrowser() throws {
    dialog = createEmptyDialog(mode: .browser)

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    AccessToken.current = SampleAccessTokens.validToken
    XCTAssertNoThrow(try dialog.validate())
    AccessToken.current = nil

    TestShareUtility.stubbedTestShareContainsPhotos = true
    AccessToken.current = nil
    XCTAssertThrowsError(try dialog.validate())
    TestShareUtility.reset()

    TestShareUtility.stubbedTestShareContainsVideos = true
    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertThrowsError(try dialog.validate())
  }

  func testSharingViaBrowserWithoutContent() {
    bridgeAPIRequestFactory.stubbedBridgeAPIRequest = TestBridgeAPIRequest()
    dialog = createEmptyDialog(mode: .browser)
    XCTAssertFalse(dialog.show(), .Showing.showingRequiresValidContent)
    XCTAssertTrue(delegate.sharerDidFailCalled, .Showing.showingRequiresValidContent)
  }

  func testSharingViaBrowserWithInvalidLinkContent() {
    bridgeAPIRequestFactory.stubbedBridgeAPIRequest = TestBridgeAPIRequest()
    dialog = createEmptyDialog(mode: .browser)
    let content = ShareModelTestUtility.linkContent
    content.contentURL = nil
    dialog.shareContent = content
    XCTAssertFalse(dialog.show(), .Showing.showingRequiresValidContent)
    XCTAssertTrue(delegate.sharerDidFailCalled, .Showing.showingRequiresValidContent)
  }

  func testSharingViaBrowserWithValidLinkContent() {
    let request = TestBridgeAPIRequest()
    bridgeAPIRequestFactory.stubbedBridgeAPIRequest = request
    let components = WebShareBridgeComponents(methodName: "test", parameters: ["key": "value"])
    TestShareUtility.stubbedWebShareBridgeComponents = components
    let content = ShareModelTestUtility.linkContent

    validate(
      shareContent: content,
      expectValid: true,
      expectShow: true,
      mode: .browser
    )

    XCTAssertIdentical(
      TestShareUtility.capturedWebShareBridgeComponentsContent,
      content,
      .Showing.webShareBridgeComponents
    )

    XCTAssertEqual(bridgeAPIRequestFactory.capturedProtocolType, .web, .Showing.bridgeAPIRequest)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedScheme, URLScheme.https.rawValue, .Showing.bridgeAPIRequest)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedMethodName, components.methodName, .Showing.bridgeAPIRequest)
    XCTAssertEqual(
      bridgeAPIRequestFactory.capturedParameters as? [String: String],
      components.parameters as? [String: String],
      .Showing.bridgeAPIRequest
    )
    XCTAssertNil(bridgeAPIRequestFactory.capturedUserInfo, .Showing.bridgeAPIRequest)

    let response = BridgeAPIResponse(request: request, error: nil)
    bridgeAPIRequestOpener.capturedCompletionBlock?(response)

    XCTAssertTrue(delegate.sharerDidCompleteCalled, .WebDialogDelegate.didCompleteCalled)
    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  func testSharingViaBrowserWithValidPhotoContent() {
    let request = TestBridgeAPIRequest()
    bridgeAPIRequestFactory.stubbedBridgeAPIRequest = request
    let components = WebShareBridgeComponents(methodName: "test", parameters: ["key": "value"])
    TestShareUtility.stubbedWebShareBridgeComponents = components
    let content = ShareModelTestUtility.photoContentWithImages

    validate(
      shareContent: content,
      expectValid: true,
      expectShow: true,
      mode: .browser
    )

    XCTAssertIdentical(
      TestShareUtility.capturedAsyncWebPhotoContentContent,
      content,
      .Showing.webPhotoContent
    )

    let parameters = ["key": "value"]
    TestShareUtility.capturedAsyncWebPhotoContentCompletion?(true, "test", parameters)

    XCTAssertEqual(bridgeAPIRequestFactory.capturedProtocolType, .web, .Showing.bridgeAPIRequest)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedScheme, URLScheme.https.rawValue, .Showing.bridgeAPIRequest)
    XCTAssertEqual(bridgeAPIRequestFactory.capturedMethodName, "test", .Showing.bridgeAPIRequest)
    XCTAssertEqual(
      bridgeAPIRequestFactory.capturedParameters as? [String: String],
      parameters,
      .Showing.bridgeAPIRequest
    )
    XCTAssertNil(bridgeAPIRequestFactory.capturedUserInfo, .Showing.bridgeAPIRequest)

    let response = BridgeAPIResponse(request: request, error: nil)
    bridgeAPIRequestOpener.capturedCompletionBlock?(response)

    XCTAssertTrue(delegate.sharerDidCompleteCalled, .WebDialogDelegate.didCompleteCalled)
    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  // MARK: - Web mode

  func testCanShowWeb() {
    dialog = createEmptyDialog(mode: .web)
    XCTAssertTrue(
      dialog.canShow,
      "A dialog without share content should be showable on web"
    )

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with link content should be showable on web"
    )

    AccessToken.current = SampleAccessTokens.validToken
    TestShareUtility.stubbedTestShareContainsPhotos = true
    TestShareUtility.validateShareContentShouldThrow = true
    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertFalse(
      dialog.canShow,
      "A dialog with photos should not be showable on web"
    )
    TestShareUtility.reset()

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    TestShareUtility.stubbedTestShareContainsMedia = true
    XCTAssertFalse(
      dialog.canShow,
      "A dialog with content that contains local media should not be showable on web"
    )
  }

  func testValidateWeb() throws {
    dialog = createEmptyDialog(mode: .web)

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    AccessToken.current = SampleAccessTokens.validToken
    dialog.shareContent = ShareModelTestUtility.photoContent
    TestShareUtility.validateShareContentShouldThrow = true
    XCTAssertThrowsError(
      try dialog.validate(),
      "A dialog with photo content that points to remote urls should not be considered valid on web"
    )
    TestShareUtility.reset()

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    TestShareUtility.stubbedTestShareContainsPhotos = true
    XCTAssertThrowsError(
      try dialog.validate(),
      "A dialog with photo content that is already loaded should not be considered valid on web"
    )
    TestShareUtility.reset()

    dialog.shareContent = ShareModelTestUtility.photoContentWithFileURLs
    TestShareUtility.stubbedTestShareContainsPhotos = true
    XCTAssertThrowsError(
      try dialog.validate(),
      "A dialog with photo content that points to file urls should not be considered valid on web"
    )
    TestShareUtility.reset()

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    TestShareUtility.stubbedTestShareContainsMedia = true
    XCTAssertThrowsError(
      try dialog.validate(),
      "A dialog that includes local media should not be considered valid on web"
    )
    TestShareUtility.reset()

    AccessToken.current = nil
    TestShareUtility.stubbedTestShareContainsVideos = true
    XCTAssertThrowsError(
      try dialog.validate(),
      "A dialog with content but no access token should not be considered valid on web"
    )
  }

  // MARK: - Feed browser mode

  func testCanShowFeedBrowser() {
    dialog = createEmptyDialog(mode: .feedBrowser)

    XCTAssertTrue(
      dialog.canShow,
      "A dialog without content should be showable in a browser feed"
    )

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with link content should be showable in a browser feed"
    )

    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertFalse(
      dialog.canShow,
      "A dialog with photo content should not be showable in a browser feed"
    )

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertFalse(
      dialog.canShow,
      "A dialog with video content that has no preview photo should not be showable in a browser feed"
    )
  }

  func testValidateFeedBrowser() throws {
    dialog = createEmptyDialog(mode: .feedBrowser)
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertThrowsError(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertThrowsError(try dialog.validate())
  }

  // MARK: - Share sheet mode

  func testValidateShareSheet() throws {
    dialog = createEmptyDialog(mode: .shareSheet)

    dialog.shareContent = ShareModelTestUtility.linkContentWithoutQuote
    XCTAssertNoThrow(
      try dialog.validate(),
      "Should not throw an error when validating link content without quotes"
    )

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertNoThrow(
      try dialog.validate(),
      "Should not throw an error when validating photo content with images"
    )

    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertThrowsError(
      try dialog.validate(),
      "Should throw an error when validating photo content on a share sheet"
    )

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertThrowsError(
      try dialog.validate(),
      "Should throw an error when validating video content without a preview photo on a share sheet"
    )
  }

  func testThatInitialTextIsSetCorrectlyWhenShareExtensionIsAvailable() throws {
    dialog = createEmptyDialog(mode: .shareSheet)
    let content = ShareModelTestUtility.linkContent
    content.hashtag = Hashtag("#hashtag")
    TestShareUtility.stubbedHashtagString = "#hashtag"
    content.quote = "a quote"
    dialog.shareContent = content
    internalUtility.isFacebookAppInstalled = true

    internalURLOpener.canOpenURL = true
    settings.appID = "appID"

    let viewController = UIViewController()
    dialog.fromViewController = viewController
    XCTAssertTrue(dialog.show())

    try validateInitialText(
      capturedText: socialComposeViewController.capturedInitialText,
      expectedAppID: "appID",
      expectedHashtag: "#hashtag",
      expectedQuotes: ["a quote"]
    )
  }

  func testPassingValidationForLinkQuoteWithValidShareExtensionVersion() {
    internalUtility.isFacebookAppInstalled = true

    validate(
      shareContent: ShareModelTestUtility.linkContent,
      expectValid: true,
      expectShow: true,
      mode: .shareSheet
    )
  }

  func testValidateWithErrorReturnsFalseForMMPIfAValidShareExtensionVersionIsNotAvailable() {
    TestShareUtility.validateShareContentShouldThrow = true

    validate(
      shareContent: ShareModelTestUtility.mediaContent,
      expectValid: false,
      expectShow: false,
      mode: .shareSheet,
      nonSupportedScheme: "fbapi20160328:/"
    )
  }

  func testThatValidateWithErrorReturnsTrueForMMPIfAValidShareExtensionVersionIsAvailable() {
    internalUtility.isFacebookAppInstalled = true

    validate(
      shareContent: ShareModelTestUtility.mediaContent,
      expectValid: true,
      expectShow: true,
      mode: .shareSheet
    )
  }

  func testThatValidateWithErrorReturnsFalseForMMPWithMoreThan1Video() {
    validate(
      shareContent: ShareModelTestUtility.multiVideoMediaContent,
      expectValid: false,
      expectShow: false,
      mode: .shareSheet
    )
  }

  // MARK: - Feed web mode

  func testCanShowFeedWeb() {
    dialog = createEmptyDialog(mode: .feedWeb)

    XCTAssertTrue(
      dialog.canShow,
      "A dialog without content should be showable in a web feed"
    )

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with link content should be showable in a web feed"
    )

    dialog.shareContent = ShareModelTestUtility.photoContent
    XCTAssertFalse(
      dialog.canShow,
      "A dialog with photo content should not be showable in a web feed"
    )

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertFalse(
      dialog.canShow,
      "A dialog with video content and no preview photo should not be showable in a web feed"
    )
  }

  func testValidateFeedWeb() throws {
    dialog = createEmptyDialog(mode: .feedWeb)
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertThrowsError(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertThrowsError(try dialog.validate())
  }

  // MARK: - Automatic mode

  func testCameraShareModesWhenNativeUnavailable() {
    dialog = createEmptyDialog(mode: .automatic)
    dialog.shareContent = ShareModelTestUtility.cameraEffectContent

    XCTAssertThrowsError(try dialog.validate())
  }

  // MARK: - Multiple modes

  func testCameraShareModesWhenNativeAvailable() throws {
    dialog = createEmptyDialog(mode: .automatic)
    dialog.shareContent = ShareModelTestUtility.cameraEffectContent
    internalURLOpener.canOpenURL = true
    internalUtility.isFacebookAppInstalled = true

    // Check supported modes
    dialog.mode = .automatic
    XCTAssertNoThrow(try dialog.validate())

    dialog.mode = .native
    XCTAssertNoThrow(try dialog.validate())

    // Check unsupported modes
    dialog.mode = .web
    XCTAssertThrowsError(try dialog.validate())

    dialog.mode = .browser
    XCTAssertThrowsError(try dialog.validate())

    dialog.mode = .shareSheet
    XCTAssertThrowsError(try dialog.validate())

    dialog.mode = .feedWeb
    XCTAssertThrowsError(try dialog.validate())

    dialog.mode = .feedBrowser
    XCTAssertThrowsError(try dialog.validate())
  }

  // MARK: - WebDialogDelegate

  func testWebDialogDelegateCancellation() {
    dialog = createEmptyDialog(mode: .web)
    let webDialog = WebDialog(name: "test", delegate: dialog)
    dialog.webDialog = webDialog
    dialog.webDialogDidCancel(webDialog)

    XCTAssertNil(dialog.webDialog, .WebDialogDelegate.clearsWebDialog)

    XCTAssertTrue(delegate.sharerDidCancelCalled, .WebDialogDelegate.didCancelCalled)
    XCTAssertIdentical(delegate.sharerDidCancelSharer, dialog, .WebDialogDelegate.didCancelCalled)

    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  func testWebDialogDelegateFailure() throws {
    dialog = createEmptyDialog(mode: .web)
    let webDialog = WebDialog(name: "test", delegate: dialog)
    dialog.webDialog = webDialog
    let error = TestSDKError(type: .unknown)
    dialog.webDialog(webDialog, didFailWithError: error)

    XCTAssertNil(dialog.webDialog, .WebDialogDelegate.clearsWebDialog)

    XCTAssertTrue(delegate.sharerDidFailCalled, .WebDialogDelegate.didFailCalled)
    XCTAssertIdentical(delegate.sharerDidFailSharer, dialog, .WebDialogDelegate.didFailCalled)
    XCTAssertIdentical(delegate.sharerDidFailError as AnyObject, error, .WebDialogDelegate.didFailCalled)

    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  func testWebDialogDelegateCompletionWithCancelErrorCode() {
    dialog = createEmptyDialog(mode: .web)
    let webDialog = WebDialog(name: "test", delegate: dialog)
    dialog.webDialog = webDialog
    dialog.webDialog(webDialog, didCompleteWithResults: ["error_code": 4201])

    XCTAssertNil(dialog.webDialog, .WebDialogDelegate.clearsWebDialog)

    XCTAssertTrue(delegate.sharerDidCancelCalled, .WebDialogDelegate.didCancelCalled)
    XCTAssertIdentical(delegate.sharerDidCancelSharer, dialog, .WebDialogDelegate.didCancelCalled)

    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  func testWebDialogDelegateCompletionWithError() throws {
    dialog = createEmptyDialog(mode: .web)
    let webDialog = WebDialog(name: "test", delegate: dialog)
    dialog.webDialog = webDialog
    dialog.webDialog(
      webDialog,
      didCompleteWithResults: [
        "error_code": 123,
        "error_message": "message",
      ]
    )

    XCTAssertNil(dialog.webDialog, .WebDialogDelegate.clearsWebDialog)

    XCTAssertTrue(delegate.sharerDidFailCalled, .WebDialogDelegate.didFailCalled)
    XCTAssertIdentical(delegate.sharerDidFailSharer, dialog, .WebDialogDelegate.didFailCalled)
    let error = try XCTUnwrap(delegate.sharerDidFailError as? TestSDKError, .WebDialogDelegate.didFailCalled)
    XCTAssertEqual(error.domain, ShareErrorDomain, .WebDialogDelegate.didFailCalled)
    XCTAssertEqual(error.code, ShareError.unknown.rawValue, .WebDialogDelegate.didFailCalled)
    XCTAssertEqual(error.userInfo[GraphRequestErrorGraphErrorCodeKey] as? Int, 123, .WebDialogDelegate.didFailCalled)
    XCTAssertEqual(error.message, "message", .WebDialogDelegate.didFailCalled)
    XCTAssertNil(error.underlyingError, .WebDialogDelegate.didFailCalled)

    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  func testWebDialogDelegateCompletionWithCompletionGestureCancellation() {
    dialog = createEmptyDialog(mode: .web)
    let webDialog = WebDialog(name: "test", delegate: dialog)
    dialog.webDialog = webDialog
    dialog.webDialog(
      webDialog,
      didCompleteWithResults: [
        ShareBridgeAPI.CompletionGesture.key: ShareBridgeAPI.CompletionGesture.cancelValue,
        "error_code": 0,
      ]
    )

    XCTAssertNil(dialog.webDialog, .WebDialogDelegate.clearsWebDialog)

    XCTAssertTrue(delegate.sharerDidCancelCalled, .WebDialogDelegate.didCancelCalled)
    XCTAssertIdentical(delegate.sharerDidCancelSharer, dialog, .WebDialogDelegate.didCancelCalled)

    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  func testWebDialogDelegateCompletion() throws {
    dialog = createEmptyDialog(mode: .web)
    let webDialog = WebDialog(name: "test", delegate: dialog)
    dialog.webDialog = webDialog
    dialog.webDialog(
      webDialog,
      didCompleteWithResults: [
        ShareBridgeAPI.PostIDKey.webParameters: "my-post",
        "error_code": 0,
      ]
    )

    XCTAssertNil(dialog.webDialog, .WebDialogDelegate.clearsWebDialog)

    XCTAssertTrue(delegate.sharerDidCompleteCalled, .WebDialogDelegate.didCompleteCalled)
    XCTAssertIdentical(delegate.sharerDidCompleteSharer, dialog, .WebDialogDelegate.didCompleteCalled)
    let results = try XCTUnwrap(delegate.sharerDidCompleteResults, .WebDialogDelegate.didCompleteCalled)
    XCTAssertEqual(
      results[ShareBridgeAPI.PostIDKey.results] as? String,
      "my-post",
      .WebDialogDelegate.didCompleteCalled
    )

    XCTAssertIdentical(
      internalUtility.unregisterTransientObjectObject as AnyObject,
      dialog,
      .WebDialogDelegate.unregistersTransientObject
    )
  }

  // MARK: - Helpers

  func createEmptyDialog(mode: ShareDialog.Mode) -> ShareDialog {
    let dialog = ShareDialog(viewController: nil, content: nil, delegate: delegate)
    dialog.mode = mode
    return dialog
  }

  func validate(
    shareContent: SharingContent,
    expectValid: Bool,
    expectShow: Bool,
    mode: ShareDialog.Mode,
    nonSupportedScheme: String? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    internalURLOpener.computeCanOpenURL = { url in
      url.absoluteString != nonSupportedScheme
    }

    let viewController = UIViewController()
    dialog = createEmptyDialog(mode: mode)
    dialog.shareContent = shareContent
    dialog.fromViewController = viewController

    if expectValid {
      XCTAssertNoThrow(
        try dialog.validate(),
        "Should not throw an error when validating the dialog",
        file: file,
        line: line
      )
    } else {
      XCTAssertThrowsError(
        try dialog.validate(),
        "Should not throw an error when validating the dialog"
      )
    }
    XCTAssertEqual(
      dialog.show(),
      expectShow,
      "Showing the dialog should \(expectShow ? "succeed" : "fail")",
      file: file,
      line: line
    )
  }

  private func validateInitialText(
    capturedText: String?,
    expectedAppID: String,
    expectedHashtag: String,
    expectedQuotes: [String],
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    let capturedComponents = try XCTUnwrap(initialTextComponents(for: capturedText))

    XCTAssertEqual(
      capturedComponents.appID,
      "fb-app-id:\(expectedAppID)",
      file: file,
      line: line
    )
    XCTAssertEqual(
      capturedComponents.hashtag,
      expectedHashtag,
      file: file,
      line: line
    )
    XCTAssertEqual(
      capturedComponents.jsonObject.count,
      3,
      file: file,
      line: line
    )
    XCTAssertEqual(
      capturedComponents.jsonObject["quotes"] as? [String],
      expectedQuotes,
      file: file,
      line: line
    )
    XCTAssertEqual(
      capturedComponents.jsonObject["app_id"] as? String,
      expectedAppID,
      file: file,
      line: line
    )
    XCTAssertEqual(
      capturedComponents.jsonObject["hashtags"] as? [String],
      [expectedHashtag],
      file: file,
      line: line
    )
  }

  private typealias InitialTextComponents = (appID: String, hashtag: String, jsonObject: [String: Any])

  private func initialTextComponents(for potentialText: String?) -> InitialTextComponents? {
    guard
      let splitAtVerticalBar = potentialText?.split(separator: "|"),
      splitAtVerticalBar.count == 2,
      let beforeJSON = splitAtVerticalBar.first?.split(separator: " "),
      beforeJSON.count == 2,
      let appID = beforeJSON.first,
      let hashtag = beforeJSON.last,
      let json = splitAtVerticalBar.last,
      let data = String(json).data(using: .utf8),
      let jsonObject = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    else {
      return nil
    }

    return (
      appID: String(appID),
      hashtag: String(hashtag),
      jsonObject: jsonObject
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  enum DefaultDependencies {
    static let usesInternalURLOpenerByDefault = """
      The default internal URL opening dependency should be the shared UIApplication
      """
    static let usesInternalUtilityByDefault = """
      The default internal utility dependency should be the shared InternalUtility
      """
    static let usesSettingsByDefault = "The default settings dependency should be the shared Settings"
    static let usesShareUtilityByDefault = "The default share utility dependency should be the _ShareUtility class"
    static let usesShareBridgeAPIRequestFactoryByDefault = """
      The default bridge API request factory dependency should be a concrete ShareBridgeAPIRequestFactory
      """
    static let usesBridgeAPIByDefault = """
      The default bridge API request opening dependency should be the shared BridgeAPI for its default
      """
    static let usesSocialComposeViewControllerFactoryByDefault = """
      The default social compose view controller factory dependency should be a concrete \
      SocialComposeViewControllerFactory
      """
    static let usesInternalUtilityAsWindowFinderByDefault = """
      The default window finding dependency should be the shared InternalUtility
      """
    static let usesErrorFactoryByDefault = "The default error factory dependency should be a concrete ErrorFactory"
    static let usesAppEventsByDefault = "The default event logging dependency should be the shared AppEvents"
    static let usesPHImageManagerAsMediaLibrarySearcherByDefault = """
      The default media library searching dependency should be the default PHImageManager
      """
  }

  enum CustomDependencies {
    static let usesCustomInternalURLOpener = "The internal URL opening dependency should be configurable"
    static let usesCustomInternalUtility = "The internal utility dependency should be configurable"
    static let usesCustomSettings = "The settings dependency should be configurable"
    static let usesCustomShareUtility = "The share utility dependency should be configurable"
    static let usesCustomShareBridgeAPIRequestFactory = """
      The bridge API request factory dependency should be configurable
      """
    static let usesCustomBridgeAPIRequestOpener = "The bridge API request opening dependency should be configurable"
    static let usesCustomSocialComposeViewControllerFactory = """
      The social compose view roller factory dependency should be configurable
      """
    static let usesCustomWindowFinder = "The window finding dependency should be configurable"
    static let usesCustomErrorFactory = "The error factory dependency should be configurable"
    static let usesCustomEventLogger = "The event logging dependency should be configurable"
    static let usesCustomMediaLibrarySearcher = "The media library searching dependency should be configurable"
  }

  enum Construction {
    static let createViaClassFactoryMethod = "Can create a dialog with a class factory method"
    static let createViaClassShowMethod = "Can create and show a dialog with the class `show` method"
  }

  enum WebDialogDelegate {
    static let didCancelCalled = "A dialog invokes its delegate's cancellation method"
    static let didFailCalled = "A dialog invokes its delegate's failure method"
    static let didCompleteCalled = "A dialog invokes its delegate's completion method"
    static let clearsWebDialog = "A dialog clears its web dialog"
    static let unregistersTransientObject = "A dialog unregisters itself as a transient object"
  }

  enum Showing {
    static let showingRequiresValidContent = "A share dialog will only show with valid share content"
    static let showsWithValidContent = "A share dialog shows with valid content"
    static let bridgeAPIRequest = "A bridge API request is created with the appropriate values"
    static let webShareBridgeComponents = "A bridge API request needs components derived from its content"
    static let webPhotoContent = "A bridge API request needs values generated for web photo content"
  }
}
