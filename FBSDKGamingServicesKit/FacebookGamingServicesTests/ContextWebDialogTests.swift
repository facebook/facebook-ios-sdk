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

import TestTools
import XCTest

class ContextWebDialogTests: XCTestCase, ContextDialogDelegate {

  let contextIDKey = "context_id"
  let contextID = "123"
  let errorCodeKey = "error_code"
  let cancelErrorCode = 4201
  let errorCode = 404
  let errorMessageKey = "error_message"
  let errorMessage = "Dialog Error"

  lazy var contextWebDialog = ContextWebDialog(delegate: self)
  let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 600))
  var dialogCompleted = false
  var dialogCanceled = false
  var dialogError: Error?

  func testShow() throws {
    let dialog = try XCTUnwrap(contextWebDialog)

    XCTAssertFalse(
      dialog.show(),
      "Since ContextWebDialog is just a superclass, its show method should always return false"
    )
    XCTAssertFalse(dialogCompleted)
    XCTAssertFalse(dialogCanceled)
  }

  func testDialogCompletesAndUpdatesContext() throws {
    let dialog = try XCTUnwrap(contextWebDialog)
    let webDelegate = dialog as WebDialogDelegate
    let webDialog = WebDialog(name: "Test", delegate: webDelegate)
    dialog.currentWebDialog = webDialog

    dialog.webDialog(webDialog, didCompleteWithResults: [contextIDKey: contextID])

    XCTAssertTrue(dialogCompleted)
    XCTAssertFalse(dialogCanceled)
    XCTAssertNil(dialogError)
    XCTAssertEqual(GamingContext.current?.identifier, contextID)
  }

  func testDialogCancelsThroughErrorResults() throws {
    let dialog = try XCTUnwrap(contextWebDialog)
    let webDelegate = dialog as WebDialogDelegate
    let webDialog = WebDialog(name: "Test", delegate: webDelegate)
    dialog.currentWebDialog = webDialog

    dialog.webDialog(webDialog, didCompleteWithResults: [errorCodeKey: cancelErrorCode, errorMessageKey: errorMessage])

    XCTAssertFalse(dialogCompleted)
    XCTAssertTrue(dialogCanceled)
    XCTAssertNil(dialogError)
  }

  func testDialogReturnsError() throws {
    let dialog = try XCTUnwrap(contextWebDialog)
    let webDelegate = dialog as WebDialogDelegate
    let webDialog = WebDialog(name: "Test", delegate: webDelegate)
    dialog.currentWebDialog = webDialog

    dialog.webDialog(webDialog, didCompleteWithResults: [errorCodeKey: errorCode, errorMessageKey: errorMessage])
    let error: NSError = try XCTUnwrap(dialogError) as NSError

    XCTAssertFalse(dialogCompleted)
    XCTAssertFalse(dialogCanceled)
    XCTAssertNotNil(error)
    XCTAssertEqual(error.code, errorCode)
    XCTAssertEqual(error.userInfo.values.first as? String, errorMessage)
  }

  func testDialogCancelsWhenWebDialogReturnsEmptyResults() throws {
    let dialog = try XCTUnwrap(contextWebDialog)
    let delegate = dialog as WebDialogDelegate
    let webDialog = WebDialog(name: "Test", delegate: delegate)
    dialog.currentWebDialog = webDialog

    dialog.webDialog(webDialog, didCompleteWithResults: [:])

    XCTAssertFalse(dialogCompleted)
    XCTAssertTrue(dialogCanceled)
    XCTAssertNil(dialogError)
  }

  func testCreateWebDialogFrameWithValuesLessThanWindowFrame() throws {
    let dialog = try XCTUnwrap(contextWebDialog)
    let finder = TestWindowFinder(window: testWindow)
    let frame = dialog.createWebDialogFrame(withWidth: 200, height: 200, windowFinder: finder)

    XCTAssertEqual(frame, CGRect(x: 50, y: 200, width: 200, height: 200))
  }

  func testCreateWebDialogFrameWithValuesGreaterThanWindowFrame() throws {
    let dialog = try XCTUnwrap(contextWebDialog)
    let finder = TestWindowFinder(window: testWindow)
    let frame = dialog.createWebDialogFrame(withWidth: 301, height: 601, windowFinder: finder)
    let windowOrigin = testWindow.frame.origin
    let windowSize = testWindow.frame.size

    let expectedFrame = CGRect(x: windowOrigin.x, y: windowOrigin.y, width: windowSize.width, height: windowSize.height)
    XCTAssertEqual(frame, expectedFrame)
  }

  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {
    dialogCompleted = true
  }

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {
    dialogError = error
  }

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {
    dialogCanceled = true
  }
}
