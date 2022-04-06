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

final class FBSendButtonTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var button: FBSendButton!
  var content: ShareLinkContent!
  var testDialog: TestMessageDialog!
  var internalUtility: TestInternalUtility!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    button = FBSendButton()
    content = ShareLinkContent()
    testDialog = TestMessageDialog()
    internalUtility = TestInternalUtility()

    FBSendButton.setDependencies(.init(internalUtility: internalUtility))
  }

  override func tearDown() {
    button = nil
    content = nil
    testDialog = nil
    internalUtility = nil

    FBSendButton.resetDependencies()

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    FBSendButton.resetDependencies()

    let dependencies = try FBSendButton.getDependencies()
    XCTAssertIdentical(dependencies.internalUtility, InternalUtility.shared, .usesInternalUtilityByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try FBSendButton.getDependencies()
    XCTAssertIdentical(dependencies.internalUtility, internalUtility, .usesCustomInternalUtility)
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
    XCTAssertEqual(button.impressionTrackingEventName, .sendButtonImpression, .hasImpressionTrackingEventName)
    XCTAssertEqual(button.impressionTrackingIdentifier, "send", .hasImpressionTrackingIdentifier)
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
    XCTAssertEqual(button.title(for: .normal), "Send", .configuringSetsAppearance)
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
  static let usesInternalUtilityByDefault = "The default internal utility dependency should be the InternalUtility type"
  static let usesCustomInternalUtility = "The internal utility dependency should be configurable"

  static let hasNoDialogByDefault = "A send button does not have a message dialog by default"

  static let hasNoContentByDefault = "A send button does not have share content by default"
  static let contentComesFromDialog = "The share content should be derived from its dialog, if any"
  static let contentIsSetOnDialog = "Setting the share content should set it on its dialog, if any"
  static let settingContentUpdatesEnabledState = "Setting the share content should update the enabled state"

  static let hasNoAnalyticsParameters = "A send button has no analytics parameters"

  static let hasImpressionTrackingEventName = "A send button has a custom impression tracking event name"
  static let hasImpressionTrackingIdentifier = "A send button has a custom impression tracking identifier"

  static let isImplicitlyDisabledWithoutDialog = "A send button is implicitly disabled without a dialog"
  static let isImplicitlyDisabledWithoutShowableDialog = """
    A send button is implicitly disabled without a showable dialog
    """
  static let isImplicitlyDisabledWithoutValidatedDialog = """
    A send button is implicitly disabled without a validated dialog
    """
  static let isImplicitlyEnabledWithValidatedDialog = "A send button is implicitly enabled with a validated dialog"

  static let configuringSetsAppearance = "Configuring a button should set up its appearance"
  static let configuringSetsAction = "Configuring a button should set an action against itself calling the share method"
  static let configuringAddsDialog = "Configuring a button should create and set a message dialog"

  static let actionShowsDialog = "A button's action should show its dialog, if any"
}

// MARK: - Test Values

fileprivate extension URL {
  static let linkContent = URL(string: "https://facebook.com")! // swiftlint:disable:this force_unwrapping
}
