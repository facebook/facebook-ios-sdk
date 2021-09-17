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

import FacebookGamingServices
import TestTools
import XCTest

class CreateContextDialogTests: XCTestCase, ContextDialogDelegate {

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
    dialog.show()

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
    GamingContext.current = GamingContext.createContext(withIdentifier: "foo", size: 2)

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
