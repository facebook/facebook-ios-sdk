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

@testable import FacebookGamingServices
import FBSDKCoreKit
import TestTools
import XCTest

class ContextDialogPresenterTests: XCTestCase {

  let createContextContent = CreateContextContent(playerID: "playerID")
  let switchContextContent = SwitchContextContent(contextID: "contextID")
  let chooseContextContent = ChooseContextContent()
  let delegate = TestContextDialogDelegate()
  let createContextDialogFactory = TestCreateContextDialogFactory()
  let switchContextDialogFactory = TestSwitchContextDialogFactory()
  let chooseContextDialogFactory = TestChooseContextDialogFactory()

  lazy var presenter = ContextDialogPresenter(
    createContextDialogFactory: createContextDialogFactory,
    switchContextDialogFactory: switchContextDialogFactory,
    chooseContextDialogFactory: chooseContextDialogFactory
  )

  func testDefaults() {
    let presenter = ContextDialogPresenter()

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

  func testMakingCreateContextDialog() {
    _ = presenter.makeCreateContextDialog(
      content: createContextContent,
      delegate: delegate
    )

    XCTAssertTrue(
      createContextDialogFactory.wasMakeCreateContextDialogCalled,
      "Should use the factory to make a create context dialog"
    )
    XCTAssertTrue(
      createContextDialogFactory.capturedDelegate === delegate,
      "Should create a dialog with the expected delegate"
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

  func testMakingSwitchContextDialog() {
    _ = presenter.makeSwitchContextDialog(
      content: switchContextContent,
      delegate: delegate
    )

    XCTAssertTrue(
      switchContextDialogFactory.wasMakeSwitchContextDialogCalled,
      "Should use the factory to make a switch context dialog"
    )
    XCTAssertTrue(
      switchContextDialogFactory.capturedDelegate === delegate,
      "Should create a dialog with the expected delegate"
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

  func testMakingChooseContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    _ = presenter.makeChooseContextDialog(
      content: chooseContextContent,
      delegate: delegate
    )

    XCTAssertTrue(
      chooseContextDialogFactory.wasMakeChooseContextDialogCalled,
      "Should use the factory to make a choose context dialog"
    )
    XCTAssertTrue(
      chooseContextDialogFactory.capturedDelegate === delegate,
      "Should create a dialog with the expected delegate"
    )
  }

  func testShowingChooseContextDialog() throws {
    AccessToken.current = SampleAccessTokens.validToken

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
