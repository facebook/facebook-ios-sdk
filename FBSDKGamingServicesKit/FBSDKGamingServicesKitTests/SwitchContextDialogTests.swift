/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

final class SwitchContextDialogTests: XCTestCase, ContextDialogDelegate {

  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: NSError?
  let windowFinder = TestWindowFinder()
  let content = SwitchContextContent(contextID: "1234567890")
  lazy var dialog = SwitchContextDialog(
    content: content,
    windowFinder: windowFinder,
    delegate: self
  )

  override func setUp() {
    super.setUp()

    dialogDidCompleteSuccessfully = false
    dialogDidCancel = false
    dialogError = nil
  }

  override func tearDown() {
    GamingContext.current = nil

    super.tearDown()
  }

  func testShowDialogWithInvalidContent() {
    let content = SwitchContextContent(contextID: "")
    let dialog = SwitchContextDialog(content: content, windowFinder: windowFinder, delegate: self)
    _ = dialog.show()
    XCTAssertNotNil(dialog)
    XCTAssertNotNil(dialogError)
    XCTAssertNil(dialog.currentWebDialog)
  }

  func testShowingDialogWithInvalidContentType() throws {
    let invalidContent = ChooseContextContent()
    let dialog = SwitchContextDialog(content: content, windowFinder: windowFinder, delegate: self)
    dialog.dialogContent = invalidContent
    _ = dialog.show()
    XCTAssertNotNil(dialog)
    let error = try XCTUnwrap(dialogError as? GamingServicesDialogError)
    XCTAssertEqual(error, .invalidContentType)
    XCTAssertNil(dialog.currentWebDialog)
  }

  func testShowDialogWithValidContent() {
    _ = dialog.show()

    XCTAssertNotNil(dialog)
    XCTAssertNil(dialogError)
    XCTAssertNotNil(dialog.currentWebDialog)
  }

  func testDialogCancelsWhenResultDoesNotContainContextID() {
    _ = dialog.show()

    guard let webDialogDelegate = dialog.currentWebDialog as? WebDialogViewDelegate else {
      return XCTFail("Web dialog should be a web dialog view delegate")
    }

    let results = ["foo": name]
    webDialogDelegate.webDialogView(FBWebDialogView(), didCompleteWithResults: results)

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertTrue(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogSuccessfullyCreatesGamingContext() throws {
    XCTAssertNil(GamingContext.current, "Should not have a context by default")

    _ = dialog.show()

    let webDialogDelegate = try XCTUnwrap(dialog.currentWebDialog as? WebDialogViewDelegate)
    let resultContextIDKey = "context_id"
    let resultContextID = "1234"
    let results = [resultContextIDKey: resultContextID]
    webDialogDelegate.webDialogView(FBWebDialogView(), didCompleteWithResults: results)

    XCTAssertEqual(
      resultContextID,
      GamingContext.current?.identifier,
      "Should create a gaming context using the identifier from the web dialog result"
    )
    XCTAssertNotNil(webDialogDelegate)
    XCTAssertNotNil(GamingContext.current?.identifier)
    XCTAssertTrue(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogSuccessfullyUpdatesGamingContext() throws {
    GamingContext.current = GamingContext(identifier: "foo", size: 2)

    _ = dialog.show()

    let webDialogDelegate = try XCTUnwrap(dialog.currentWebDialog as? WebDialogViewDelegate)
    let resultContextIDKey = "context_id"
    let resultContextID = "1234"
    let results = [resultContextIDKey: resultContextID]
    webDialogDelegate.webDialogView(FBWebDialogView(), didCompleteWithResults: results)

    XCTAssertEqual(
      resultContextID,
      GamingContext.current?.identifier,
      "Should update the current gaming context to use the identifer from the web dialog result"
    )
    XCTAssertNotNil(webDialogDelegate)
    XCTAssertNotNil(GamingContext.current?.identifier)
    XCTAssertTrue(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogCompletesWithServerError() throws {
    _ = dialog.show()

    let webDialogDelegate = try XCTUnwrap(dialog.currentWebDialog as? WebDialogViewDelegate)
    let resultErrorCodeKey = "error_code"
    let resultErrorCode = 1234
    let resultErrorMessageKey = "error_message"
    let resultErrorMessage = "Webview error"
    let results = [resultErrorCodeKey: resultErrorCode, resultErrorMessageKey: resultErrorMessage] as [String: Any]
    webDialogDelegate.webDialogView(FBWebDialogView(), didCompleteWithResults: results)
    let error = try XCTUnwrap(dialogError)

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertEqual(resultErrorCode, error.code)
    XCTAssertEqual(resultErrorMessage, error.userInfo.values.first as? String)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
  }

  func testDialogCancels() throws {
    _ = dialog.show()
    let webDialogDelegate = try XCTUnwrap(dialog.currentWebDialog as? WebDialogViewDelegate)

    webDialogDelegate.webDialogViewDidCancel(FBWebDialogView())

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertTrue(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogFailsWithError() throws {
    _ = dialog.show()
    let webDialogDelegate = try XCTUnwrap(dialog.currentWebDialog as? WebDialogViewDelegate)

    let error = NSError(domain: "Test", code: 1, userInfo: nil)
    webDialogDelegate.webDialogView(FBWebDialogView(), didFailWithError: error)

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNotNil(dialogError)
  }

  // MARK: - Delegate Methods

  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {
    dialogDidCompleteSuccessfully = true
  }

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {
    dialogError = error as NSError
  }

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {
    dialogDidCancel = true
  }
}
