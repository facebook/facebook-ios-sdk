/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit
import TestTools
import XCTest

final class ContextDialogPresenterTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var createContextContent: CreateContextContent!
  var switchContextContent: SwitchContextContent!
  var chooseContextContent: ChooseContextContent!
  var delegate: TestContextDialogDelegate!
  var createContextDialogFactory: TestCreateContextDialogFactory!
  var switchContextDialogFactory: TestSwitchContextDialogFactory!
  var chooseContextDialogFactory: TestChooseContextDialogFactory!
  var presenter: ContextDialogPresenter!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    AccessToken.current = nil

    createContextContent = CreateContextContent(playerID: "playerID")
    switchContextContent = SwitchContextContent(contextID: "contextID")
    chooseContextContent = ChooseContextContent()
    delegate = TestContextDialogDelegate()
    createContextDialogFactory = TestCreateContextDialogFactory()
    switchContextDialogFactory = TestSwitchContextDialogFactory()
    chooseContextDialogFactory = TestChooseContextDialogFactory()
    presenter = ContextDialogPresenter(
      createContextDialogFactory: createContextDialogFactory,
      switchContextDialogFactory: switchContextDialogFactory,
      chooseContextDialogFactory: chooseContextDialogFactory
    )
  }

  override func tearDown() {
    createContextContent = nil
    switchContextContent = nil
    chooseContextContent = nil
    delegate = nil
    createContextDialogFactory = nil
    switchContextDialogFactory = nil
    chooseContextDialogFactory = nil
    presenter = nil

    AccessToken.current = nil

    super.tearDown()
  }

  private func setSampleAccessToken() {
    AccessToken.current = SampleAccessTokens.validToken
  }

  func testDefaults() {
    presenter = ContextDialogPresenter()

    XCTAssertTrue(
      presenter.createContextDialogFactory is CreateContextDialogFactory,
      "Should have a create context dialog factory of the expected concrete type"
    )
    XCTAssertTrue(
      presenter.chooseContextDialogFactory is ChooseContextDialogFactory,
      "Should have a choose context dialog factory of the expected concrete type"
    )
    XCTAssertTrue(
      presenter.switchContextDialogFactory is SwitchContextDialogFactory,
      "Should have a switch context dialog factory of the expected concrete type"
    )
  }

  func testCreatingWithCustomDependencies() {
    XCTAssertTrue(
      presenter.createContextDialogFactory is TestCreateContextDialogFactory,
      "Should be able to make a presenter with a custom create context dialog factory"
    )
    XCTAssertTrue(
      presenter.chooseContextDialogFactory is TestChooseContextDialogFactory,
      "Should be able to make a presenter with a custom choose context dialog factory"
    )
    XCTAssertTrue(
      presenter.switchContextDialogFactory is TestSwitchContextDialogFactory,
      "Should be able to make a presenter with a custom switch context dialog factory"
    )
  }

  func testShowingCreateContextDialog() throws {
    _ = try XCTUnwrap(
      presenter.makeAndShowCreateContextDialog(
        content: createContextContent,
        delegate: delegate
      ),
      "Should not throw an error if the dialog is created successfully"
    )

    XCTAssertTrue(
      createContextDialogFactory.wasMakeCreateContextDialogCalled,
      "Should use the factory to make a create context dialog"
    )
    XCTAssertTrue(
      createContextDialogFactory.dialog.wasShowCalled,
      "Should call show on the dialog"
    )
  }

  func testShowingCreateContextDialogWithFailedDialogCreation() throws {
    createContextDialogFactory.shouldCreateDialog = false

    do {
      try presenter.makeAndShowCreateContextDialog(
        content: createContextContent,
        delegate: delegate
      )
      XCTFail("Should not create a dialog with a missing access token")
    } catch {
      let error = try XCTUnwrap(
        error as? ContextDialogPresenterError,
        "Unexpected error: \(error)"
      )
      XCTAssertEqual(error, .showCreateContext)
    }

    XCTAssertFalse(
      createContextDialogFactory.dialog.wasShowCalled,
      "Should not call show on the dialog"
    )
  }

  func testShowingSwitchContextDialog() throws {
    _ = try XCTUnwrap(
      presenter.makeAndShowSwitchContextDialog(
        content: switchContextContent,
        delegate: delegate
      ),
      "Should not create a dialog with a missing access token"
    )

    XCTAssertTrue(
      switchContextDialogFactory.wasMakeSwitchContextDialogCalled,
      "Should use the factory to make a switch context dialog"
    )
    XCTAssertTrue(
      switchContextDialogFactory.dialog.wasShowCalled,
      "Should call show on the dialog"
    )
  }

  func testShowingSwitchContextDialogWithFailedDialogCreation() throws {
    switchContextDialogFactory.shouldCreateDialog = false

    do {
      try
        presenter.makeAndShowSwitchContextDialog(
          content: switchContextContent,
          delegate: delegate
        )
      XCTFail("Should not create a dialog with a missing access token")
    } catch {
      let error = try XCTUnwrap(
        error as? ContextDialogPresenterError,
        "Unexpected error: \(error)"
      )
      XCTAssertEqual(error, .showSwitchContext)
    }

    XCTAssertFalse(
      switchContextDialogFactory.dialog.wasShowCalled,
      "Should not call show on the dialog"
    )
  }

  func testShowingChooseContextDialog() throws {
    presenter.makeAndShowChooseContextDialog(
      content: chooseContextContent,
      delegate: delegate
    )

    XCTAssertTrue(
      chooseContextDialogFactory.wasMakeChooseContextDialogCalled,
      "Should use the factory to make a choose context dialog"
    )
    XCTAssertTrue(
      chooseContextDialogFactory.dialog.wasShowCalled,
      "Should call show on the dialog"
    )
  }
}
