/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
