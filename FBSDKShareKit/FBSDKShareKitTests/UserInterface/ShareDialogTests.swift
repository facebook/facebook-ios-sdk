/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import TestTools
import UIKit
import XCTest

final class ShareDialogTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
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
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AccessToken.current = nil

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
        eventLogger: eventLogger
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

    ShareDialog.resetDependencies()
    TestShareUtility.reset()
    ShareCameraEffectContent.resetDependencies()
    AccessToken.current = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    ShareDialog.resetDependencies()

    let dependencies = try ShareDialog.getDependencies()
    XCTAssertIdentical(dependencies.internalURLOpener, ShareUIApplication.shared, .usesInternalURLOpenerByDefault)
    XCTAssertIdentical(dependencies.internalUtility, InternalUtility.shared, .usesInternalUtilityByDefault)
    XCTAssertIdentical(dependencies.settings, Settings.shared, .usesSettingsByDefault)
    XCTAssertTrue(dependencies.shareUtility is _ShareUtility.Type, .usesShareUtilityByDefault)
    XCTAssertTrue(
      dependencies.bridgeAPIRequestFactory is ShareBridgeAPIRequestFactory,
      .usesShareBridgeAPIRequestFactoryByDefault
    )
    XCTAssertIdentical(dependencies.bridgeAPIRequestOpener, BridgeAPI.shared, .usesBridgeAPIByDefault)
    XCTAssertTrue(
      dependencies.socialComposeViewControllerFactory is SocialComposeViewControllerFactory,
      .usesSocialComposeViewControllerFactoryByDefault
    )
    XCTAssertIdentical(dependencies.windowFinder, InternalUtility.shared, .usesInternalUtilityAsWindowFinderByDefault)
    XCTAssertTrue(dependencies.errorFactory is ErrorFactory, .usesErrorFactoryByDefault)
    XCTAssertIdentical(dependencies.eventLogger as AnyObject, AppEvents.shared, .usesAppEventsByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try ShareDialog.getDependencies()

    XCTAssertIdentical(dependencies.internalURLOpener, internalURLOpener, .usesCustomInternalURLOpener)
    XCTAssertIdentical(dependencies.internalUtility, internalUtility, .usesCustomInternalUtility)
    XCTAssertIdentical(dependencies.settings, settings, .usesCustomSettings)
    XCTAssertTrue(dependencies.shareUtility is TestShareUtility.Type, .usesCustomShareUtility)
    XCTAssertIdentical(
      dependencies.bridgeAPIRequestFactory,
      bridgeAPIRequestFactory,
      .usesCustomShareBridgeAPIRequestFactory
    )
    XCTAssertIdentical(dependencies.bridgeAPIRequestOpener, bridgeAPIRequestOpener, .usesCustomBridgeAPIRequestOpener)
    XCTAssertIdentical(
      dependencies.socialComposeViewControllerFactory as AnyObject,
      socialComposeViewControllerFactory,
      .usesCustomSocialComposeViewControllerFactory
    )
    XCTAssertIdentical(dependencies.windowFinder, windowFinder, .usesCustomWindowFinder)
    XCTAssertIdentical(dependencies.errorFactory, errorFactory, .usesCustomErrorFactory)
    XCTAssertIdentical(dependencies.eventLogger as AnyObject, eventLogger, .usesCustomEventLogger)
  }

  func testCanShowNativeDialogWithoutShareContent() {
    let dialog = createEmptyDialog()
    dialog.mode = .native
    internalURLOpener.canOpenURL = true
    internalUtility.isFacebookAppInstalled = true

    XCTAssertTrue(
      dialog.canShow,
      "A dialog without share content should be showable on a native dialog"
    )
  }

  func testCanShowNativeLinkContent() {
    let dialog = createEmptyDialog()
    dialog.mode = .native
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertTrue(
      dialog.canShow,
      "A dialog with valid link content should be showable on a native dialog"
    )
  }

  func testCanShowNativePhotoContent() {
    let dialog = createEmptyDialog()
    dialog.mode = .native
    dialog.shareContent = ShareModelTestUtility.photoContent
    TestShareUtility.stubbedValidateShareShouldThrow = true

    XCTAssertFalse(
      dialog.canShow,
      "Photo content with photos that have web urls should not be showable on a native dialog"
    )
  }

  func testCanShowNativePhotoContentWithFileURL() {
    let dialog = createEmptyDialog()
    dialog.mode = .native
    dialog.shareContent = ShareModelTestUtility.photoContentWithFileURLs
    XCTAssertTrue(
      dialog.canShow,
      "Photo content with photos that have file urls should be showable on a native dialog"
    )
  }

  func testCanShowNativeVideoContentWithoutPreviewPhoto() {
    let dialog = createEmptyDialog()
    dialog.mode = .native
    internalURLOpener.canOpenURL = true
    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto

    XCTAssertTrue(
      dialog.canShow,
      "Video content without a preview photo should be showable on a native dialog"
    )
  }

  func testCanShowNative() {
    let dialog = createEmptyDialog()
    dialog.mode = .native

    XCTAssertFalse(
      dialog.canShow,
      "A native dialog should not be showable if the application is unable to open a url, this can also occur if the api scheme is not whitelisted in the third party app or if the application cannot handle the share API scheme" // swiftlint:disable:this line_length
    )
  }

  func testShowNativeDoesValidate() {
    let dialog = createEmptyDialog()
    dialog.mode = .native
    dialog.shareContent = ShareModelTestUtility.photoContent
    internalURLOpener.canOpenURL = true

    XCTAssertFalse(dialog.show())
  }

  func testValidateShareSheet() throws {
    let dialog = createEmptyDialog()
    dialog.mode = .shareSheet

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

  func testCanShowBrowser() {
    let dialog = createEmptyDialog()
    dialog.mode = .browser
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
    let dialog = createEmptyDialog()
    dialog.mode = .browser

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

  func testCanShowWeb() {
    let dialog = createEmptyDialog()
    dialog.mode = .web
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
    TestShareUtility.stubbedValidateShareShouldThrow = true
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
    let dialog = createEmptyDialog()
    dialog.mode = .web

    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    AccessToken.current = SampleAccessTokens.validToken
    dialog.shareContent = ShareModelTestUtility.photoContent
    TestShareUtility.stubbedValidateShareShouldThrow = true
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

  func testCanShowFeedBrowser() {
    let dialog = createEmptyDialog()

    dialog.mode = .feedBrowser
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
    let dialog = createEmptyDialog()
    dialog.mode = .feedBrowser
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertThrowsError(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertThrowsError(try dialog.validate())
  }

  func testCanShowFeedWeb() {
    let dialog = createEmptyDialog()

    dialog.mode = .feedWeb
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
    let dialog = createEmptyDialog()
    dialog.mode = .feedWeb
    dialog.shareContent = ShareModelTestUtility.linkContent
    XCTAssertNoThrow(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.photoContentWithImages
    XCTAssertThrowsError(try dialog.validate())

    dialog.shareContent = ShareModelTestUtility.videoContentWithoutPreviewPhoto
    XCTAssertThrowsError(try dialog.validate())
  }

  func testThatInitialTextIsSetCorrectlyWhenShareExtensionIsAvailable() throws {
    let dialog = createEmptyDialog()
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
    dialog.mode = .shareSheet
    XCTAssertTrue(dialog.show())

    try validateInitialText(
      capturedText: socialComposeViewController.capturedInitialText,
      expectedAppID: "appID",
      expectedHashtag: "#hashtag",
      expectedQuotes: ["a quote"]
    )
  }

  func testCameraShareModesWhenNativeAvailable() throws {
    let dialog = createEmptyDialog()
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

  func testCameraShareModesWhenNativeUnavailable() {
    let dialog = createEmptyDialog()
    dialog.shareContent = ShareModelTestUtility.cameraEffectContent

    dialog.mode = .automatic
    XCTAssertThrowsError(try dialog.validate())
  }

  func testPassingValidationForLinkQuoteWithValidShareExtensionVersion() {
    internalUtility.isFacebookAppInstalled = true

    validate(
      shareContent: ShareModelTestUtility.linkContent,
      expectValid: true,
      expectShow: true,
      mode: .shareSheet,
      nonSupportedScheme: nil
    )
  }

  func testValidateWithErrorReturnsFalseForMMPIfAValidShareExtensionVersionIsNotAvailable() {
    TestShareUtility.stubbedValidateShareShouldThrow = true

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
      mode: .shareSheet,
      nonSupportedScheme: nil
    )
  }

  func testThatValidateWithErrorReturnsFalseForMMPWithMoreThan1Video() {
    validate(
      shareContent: ShareModelTestUtility.multiVideoMediaContent,
      expectValid: false,
      expectShow: false,
      mode: .shareSheet,
      nonSupportedScheme: nil
    )
  }

  // MARK: - Helpers

  func createEmptyDialog() -> ShareDialog {
    ShareDialog(viewController: nil, content: nil, delegate: nil)
  }

  func showAndValidate(
    nativeDialog dialog: ShareDialog,
    nonSupportedScheme: String?,
    expectRequestScheme scheme: String?,
    methodName: String,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    internalURLOpener.computeCanOpenURL = { url in
      url.absoluteString != nonSupportedScheme
    }
    settings.appID = "AppID"
    let stubbedRequest = TestBridgeAPIRequest(
      url: nil,
      protocolType: .native,
      scheme: "1"
    )
    bridgeAPIRequestFactory.stubbedBridgeAPIRequest = stubbedRequest

    let viewController = UIViewController()
    dialog.fromViewController = viewController
    XCTAssertTrue(
      dialog.show(),
      "Should be able to show the dialog",
      file: file,
      line: line
    )

    XCTAssertEqual(
      bridgeAPIRequestFactory.capturedMethodName,
      methodName,
      "Should create the request with the expected method name",
      file: file,
      line: line
    )

    if let expectedScheme = scheme {
      XCTAssertEqual(
        bridgeAPIRequestFactory.capturedScheme,
        expectedScheme,
        "Should create the request with the expected scheme",
        file: file,
        line: line
      )
    } else {
      XCTAssertNil(
        bridgeAPIRequestFactory.capturedScheme,
        "Should not create the request with a scheme",
        file: file,
        line: line
      )
    }

    XCTAssertTrue(
      bridgeAPIRequestOpener.capturedRequest === stubbedRequest,
      "Should pass the created request to the opener",
      file: file,
      line: line
    )
  }

  func validate(
    shareContent: SharingContent,
    expectValid: Bool,
    expectShow: Bool,
    mode: ShareDialog.Mode,
    nonSupportedScheme: String?,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    internalURLOpener.computeCanOpenURL = { url in
      url.absoluteString != nonSupportedScheme
    }

    let viewController = UIViewController()
    let dialog = createEmptyDialog()
    dialog.shareContent = shareContent
    dialog.mode = mode
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
      expectShow,
      dialog.show(),
      "Showing the dialog should return \(expectShow)",
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

  static let usesCustomInternalURLOpener = "The internal URL opening dependency should be configurable"
  static let usesCustomInternalUtility = "The internal utility dependency should be configurable"
  static let usesCustomSettings = "The settings dependency should be configurable"
  static let usesCustomShareUtility = "The share utility dependency should be configurable"
  static let usesCustomShareBridgeAPIRequestFactory = "The bridge API request factory dependency should be configurable"
  static let usesCustomBridgeAPIRequestOpener = "The bridge API request opening dependency should be configurable"
  static let usesCustomSocialComposeViewControllerFactory = """
    The social compose view controller factory dependency should be configurable
    """
  static let usesCustomWindowFinder = "The window finding dependency should be configurable"
  static let usesCustomErrorFactory = "The error factory dependency should be configurable"
  static let usesCustomEventLogger = "The event logging dependency should be configurable"
}
