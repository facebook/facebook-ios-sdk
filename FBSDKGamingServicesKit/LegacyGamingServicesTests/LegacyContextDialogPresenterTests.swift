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

import LegacyGamingServices
import TestTools
import XCTest

class LegacyContextDialogPresenterTests: XCTestCase {

  let createContextContent = CreateContextContent(playerID: "playerID")
  let switchContextContent = SwitchContextContent(contextID: "contextID")
  let chooseContextContent = ChooseContextContent()
  let delegate = TestContextDialogDelegate()
  let createContextDialogFactory = TestCreateContextDialogFactory()
  let switchContextDialogFactory = TestSwitchContextDialogFactory()
  let chooseContextDialogFactory = TestChooseContextDialogFactory()

  lazy var presenter = LegacyContextDialogPresenter(
    createContextDialogFactory: createContextDialogFactory,
    switchContextDialogFactory: switchContextDialogFactory,
    chooseContextDialogFactory: chooseContextDialogFactory
  )

  override func tearDown() {
    AccessToken.current = nil

    super.tearDown()
  }

  func testDefaults() {
    let presenter = LegacyContextDialogPresenter.shared

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

  func testMakingCreateContextDialogWithoutAccessToken() {
    AccessToken.current = nil
    let dialog = presenter.makeCreateContextDialog(
      with: createContextContent,
      delegate: delegate
    )

    XCTAssertFalse(
      createContextDialogFactory.wasMakeCreateContextDialogCalled,
      "Should not use the factory to make a create context dialog when there is no access token available"
    )
    XCTAssertNil(dialog, "Should not create a dialog when there is no access token available")
  }

  func testMakingCreateContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    _ = presenter.makeCreateContextDialog(
        with: createContextContent,
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

  func testShowingCreateContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    XCTAssertNil(
      presenter.makeAndShowCreateContextDialog(
        with: createContextContent,
        delegate: delegate
      ),
      "Should not return an error if the dialog is created successfully"
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
    AccessToken.current = nil // will fail to create if this is nil
    let error = try XCTUnwrap(
      presenter.makeAndShowCreateContextDialog(
        with: createContextContent,
        delegate: delegate
      ) as NSError?,
      "Should return an error if the dialog is not created successfully"
    )

    XCTAssertEqual(
      error.code,
      CoreError.errorAccessTokenRequired.rawValue,
      "Should return an error with the expected code"
    )
    XCTAssertFalse(
      createContextDialogFactory.dialog.wasShowCalled,
      "Should not call show on the dialog"
    )
  }

  func testMakingSwitchContextDialogWithoutAccessToken() {
    AccessToken.current = nil
    let dialog = presenter.makeSwitchContextDialog(
      with: switchContextContent,
      delegate: delegate
    )

    XCTAssertFalse(
      switchContextDialogFactory.wasMakeSwitchContextDialogCalled,
      "Should not use the factory to make a switch context dialog when there is no access token available"
    )
    XCTAssertNil(dialog, "Should not create a dialog when there is no access token available")
  }

  func testMakingSwitchContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    _ = presenter.makeSwitchContextDialog(
        with: switchContextContent,
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

  func testShowingSwitchContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    XCTAssertNil(
      presenter.makeAndShowSwitchContextDialog(
        with: switchContextContent,
        delegate: delegate
      ),
      "Should not return an error if the dialog is created successfully"
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
    AccessToken.current = nil // will fail to create if this is nil
    let error = try XCTUnwrap(
      presenter.makeAndShowSwitchContextDialog(
        with: switchContextContent,
        delegate: delegate
      ) as NSError?,
      "Should return an error if the dialog is not created successfully"
    )

    XCTAssertEqual(
      error.code,
      CoreError.errorAccessTokenRequired.rawValue,
      "Should return an error with the expected code"
    )
    XCTAssertFalse(
      switchContextDialogFactory.dialog.wasShowCalled,
      "Should not call show on the dialog"
    )
  }

  func testMakingChooseContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    _ = presenter.makeChooseContextDialog(
        with: chooseContextContent,
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

  func testShowingChooseContextDialog() {
    AccessToken.current = SampleAccessTokens.validToken
    XCTAssertNotNil(
      presenter.makeAndShowChooseContextDialog(
        with: chooseContextContent,
        delegate: delegate
      ),
      "Should return a dialog if one is created successfully"
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
