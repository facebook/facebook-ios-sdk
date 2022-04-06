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

final class CreateContextDialogTests: XCTestCase, ContextDialogDelegate {

  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: NSError?

  override func setUp() {
    super.setUp()

    dialogDidCompleteSuccessfully = false
    dialogDidCancel = false
    dialogError = nil
  }

  override func tearDown() {
    super.tearDown()

    GamingContext.current = nil
  }

  func testShowDialogWithInvalidContent() {
    let content = CreateContextContent(playerID: "")
    let dialog = CreateContextDialog(content: content, windowFinder: TestWindowFinder(), delegate: self)
    _ = dialog.show()

    XCTAssertNotNil(dialog)
    XCTAssertNotNil(dialogError)
    XCTAssertNil(dialog.currentWebDialog)
  }

  func testShowDialogWithValidContent() {
    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)

    XCTAssertNotNil(dialog)
    XCTAssertNil(dialogError)
    XCTAssertNotNil(dialog?.currentWebDialog)
  }

  func testDialogCancelsWhenResultDoesNotContainContextID() throws {
    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)

    let webDialogDelegate = try XCTUnwrap(dialog?.currentWebDialog as? WebDialogViewDelegate)
    let testWindowFinder = try XCTUnwrap(dialog?.currentWebDialog?.windowFinder as? TestWindowFinder)
    let results = ["foo": name]
    webDialogDelegate.webDialogView(FBWebDialogView(), didCompleteWithResults: results)

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertTrue(testWindowFinder.wasFindWindowCalled)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertTrue(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogSuccessfullyCreatesGamingContext() throws {
    XCTAssertNil(GamingContext.current, "Should not have a context by default")

    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)
    let webDialogDelegate = try XCTUnwrap(dialog?.currentWebDialog as? WebDialogViewDelegate)
    let testWindowFinder = try XCTUnwrap(dialog?.currentWebDialog?.windowFinder as? TestWindowFinder)
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
    XCTAssertTrue(testWindowFinder.wasFindWindowCalled)
    XCTAssertNotNil(GamingContext.current?.identifier)
    XCTAssertTrue(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogSuccessfullyUpdatesGamingContext() throws {
    GamingContext.current = GamingContext(identifier: "foo", size: 2)

    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)
    let webDialogDelegate = try XCTUnwrap(dialog?.currentWebDialog as? WebDialogViewDelegate)
    let testWindowFinder = try XCTUnwrap(dialog?.currentWebDialog?.windowFinder as? TestWindowFinder)
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
    XCTAssertTrue(testWindowFinder.wasFindWindowCalled)
    XCTAssertNotNil(GamingContext.current?.identifier)
    XCTAssertTrue(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogCompletesWithServerError() throws {
    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)
    let webDialogDelegate = try XCTUnwrap(dialog?.currentWebDialog as? WebDialogViewDelegate)
    let testWindowFinder = try XCTUnwrap(dialog?.currentWebDialog?.windowFinder as? TestWindowFinder)
    let resultErrorCodeKey = "error_code"
    let resultErrorCode = 1234
    let resultErrorMessageKey = "error_message"
    let resultErrorMessage = "Webview error"
    let results = [resultErrorCodeKey: resultErrorCode, resultErrorMessageKey: resultErrorMessage] as [String: Any]
    webDialogDelegate.webDialogView(FBWebDialogView(), didCompleteWithResults: results)
    let error = try XCTUnwrap(dialogError)

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertTrue(testWindowFinder.wasFindWindowCalled)
    XCTAssertNil(GamingContext.current?.identifier)
    XCTAssertEqual(resultErrorCode, error.code)
    XCTAssertEqual(resultErrorMessage, error.userInfo.values.first as? String)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNotNil(dialogError)
  }

  func testDialogCancels() throws {
    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)
    let webDialogDelegate = try XCTUnwrap(dialog?.currentWebDialog as? WebDialogViewDelegate)
    let testWindowFinder = try XCTUnwrap(dialog?.currentWebDialog?.windowFinder as? TestWindowFinder)

    webDialogDelegate.webDialogViewDidCancel(FBWebDialogView())

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertTrue(testWindowFinder.wasFindWindowCalled)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertTrue(dialogDidCancel)
    XCTAssertNil(dialogError)
  }

  func testDialogFailsWithError() throws {
    let dialog = SampleContextDialogs.showCreateContextDialog(withDelegate: self)
    let webDialogDelegate = try XCTUnwrap(dialog?.currentWebDialog as? WebDialogViewDelegate)
    let testWindowFinder = try XCTUnwrap(dialog?.currentWebDialog?.windowFinder as? TestWindowFinder)

    let error = NSError(domain: "Test", code: 1, userInfo: nil)
    webDialogDelegate.webDialogView(FBWebDialogView(), didFailWithError: error)

    XCTAssertNotNil(webDialogDelegate)
    XCTAssertTrue(testWindowFinder.wasFindWindowCalled)
    XCTAssertFalse(dialogDidCompleteSuccessfully)
    XCTAssertFalse(dialogDidCancel)
    XCTAssertNotNil(dialogError)
  }

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
