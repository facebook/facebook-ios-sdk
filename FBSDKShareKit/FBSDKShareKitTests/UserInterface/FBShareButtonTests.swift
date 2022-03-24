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

final class FBShareButtonTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var button: FBShareButton!
  var content: ShareLinkContent!
  var testDialog: TestShareDialog!
  var stringProvider: TestUserInterfaceStringProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    stringProvider = TestUserInterfaceStringProvider()
    FBShareButton.setDependencies(.init(stringProvider: stringProvider))

    content = ShareLinkContent()
    testDialog = TestShareDialog()
    button = FBShareButton()
  }

  override func tearDown() {
    button = nil
    content = nil
    testDialog = nil
    stringProvider = nil

    FBShareButton.resetDependencies()

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    FBShareButton.resetDependencies()

    let dependencies = try FBShareButton.getDependencies()
    XCTAssertIdentical(dependencies.stringProvider as AnyObject, InternalUtility.shared, .usesInternalUtilityByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try FBShareButton.getDependencies()
    XCTAssertIdentical(dependencies.stringProvider as AnyObject, stringProvider, .usesCustomStringProvider)
  }

  func testMissingDialogSetBySuperInitializer() {
    XCTAssertNotNil(button.dialog, .hasNoDialogByDefault)
  }

  func testHasNoContentByDefault() {
    XCTAssertNil(button.shareContent, .hasNoContentByDefault)
  }

  func testContentIsFromDialog() {
    button.dialog?.shareContent = content
    XCTAssertIdentical(button.shareContent, content, .contentComesFromDialog)
  }

  func testContentIsSetOnDialog() {
    button.isEnabled = true
    button.shareContent = content
    XCTAssertIdentical(button.dialog?.shareContent, content, .contentIsSetOnDialog)
    XCTAssertFalse(button.isEnabled, .settingContentUpdatesEnabledState)
  }

  func testHasNoAnalyticsParameters() {
    XCTAssertNil(button.analyticsParameters, .hasNoAnalyticsParameters)
  }

  func testHasImpressionTrackingValues() {
    XCTAssertEqual(button.impressionTrackingEventName, .shareButtonImpression, .hasImpressionTrackingEventName)
    XCTAssertEqual(button.impressionTrackingIdentifier, "share", .hasImpressionTrackingIdentifier)
  }

  func testImplicitlyDisabledWithoutDialog() {
    button.dialog = nil
    XCTAssertTrue(button.isImplicitlyDisabled, .isImplicitlyDisabledWithoutDialog)
  }

  func testImplicitlyDisabledWithoutShowableDialog() {
    button.dialog = testDialog
    testDialog.stubbedCanShow = false
    XCTAssertTrue(button.isImplicitlyDisabled, .isImplicitlyDisabledWithoutShowableDialog)
  }

  func testImplicitlyDisabledWithoutValidatedDialog() {
    button.dialog = testDialog
    testDialog.stubbedCanShow = true
    testDialog.stubbedValidationSucceeds = false
    XCTAssertTrue(button.isImplicitlyDisabled, .isImplicitlyDisabledWithoutValidatedDialog)
  }

  func testImplicitlyEnabledWithValidatedDialog() {
    button.dialog = testDialog
    testDialog.stubbedCanShow = true
    testDialog.stubbedValidationSucceeds = true
    XCTAssertFalse(button.isImplicitlyDisabled, .isImplicitlyEnabledWithValidatedDialog)
  }

  func testConfiguringSetsAppearance() throws {
    XCTAssertEqual(button.title(for: .normal), "Share", .configuringSetsAppearance)
  }

  func testConfiguringSetsAction() throws {
    let actions = try XCTUnwrap(button.actions(forTarget: button, forControlEvent: .touchUpInside))
    XCTAssertEqual(actions.count, 1, .configuringSetsAction)
    let action = try XCTUnwrap(actions.first, .configuringSetsAction)
    XCTAssertEqual(action, "share", .configuringSetsAction)
  }

  func testConfiguringAddsDialog() {
    button.dialog = nil
    button.configureButton()
    XCTAssertNotNil(button.dialog, .configuringAddsDialog)
  }

  func testAction() {
    button.dialog = testDialog
    button.share()
    XCTAssertTrue(testDialog.wasShowCalled, .actionShowsDialog)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesInternalUtilityByDefault = """
    The default string providing dependency should be the shared InternalUtility
    """
  static let usesCustomStringProvider = "The string providing dependency should be configurable"

  static let hasNoDialogByDefault = "A share button does not have a share dialog by default"

  static let hasNoContentByDefault = "A share button does not have share content by default"
  static let contentComesFromDialog = "The share content should be derived from its dialog, if any"
  static let contentIsSetOnDialog = "Setting the share content should set it on its dialog, if any"
  static let settingContentUpdatesEnabledState = "Setting the share content should update the enabled state"

  static let hasNoAnalyticsParameters = "A share button has no analytics parameters"

  static let hasImpressionTrackingEventName = "A share button has a custom impression tracking event name"
  static let hasImpressionTrackingIdentifier = "A share button has a custom impression tracking identifier"

  static let isImplicitlyDisabledWithoutDialog = "A share button is implicitly disabled without a dialog"
  static let isImplicitlyDisabledWithoutShowableDialog = """
    A share button is implicitly disabled without a showable dialog
    """
  static let isImplicitlyDisabledWithoutValidatedDialog = """
    A share button is implicitly disabled without a validated dialog
    """
  static let isImplicitlyEnabledWithValidatedDialog = "A share button is implicitly enabled with a validated dialog"

  static let configuringSetsAppearance = "Configuring a button should set up its appearance"
  static let configuringSetsAction = "Configuring a button should set an action against itself calling the share method"
  static let configuringAddsDialog = "Configuring a button should create and set a share dialog"

  static let actionShowsDialog = "A button's action should show its dialog, if any"
}
