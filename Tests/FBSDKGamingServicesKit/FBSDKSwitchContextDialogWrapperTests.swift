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

@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

struct SampleError: Error {}

class FBSDKSwitchContextDialogWrapperTests: XCTestCase, ContextDialogDelegate {

  let content = SwitchContextContent(contextID: "123")
  let windowFinder = TestWindowFinder()
  let wrappedDialog = TestSwitchContextDialog()
  lazy var dialog = FBSDKSwitchContextDialog(dialog: wrappedDialog)
  lazy var webDialog = WebDialog(name: name, delegate: dialog) // The delegate here does not matter

  func testCreatingWithFactoryMethod() {
    let dialog = FBSDKSwitchContextDialog.dialog(withContent: content, windowFinder: windowFinder, delegate: self)

    XCTAssertTrue(
      dialog.dialog is SwitchContextDialog,
      "The factory method should return the expected concrete dialog"
    )
  }

  func testCompletingWithResults() {
    dialog.webDialog(webDialog, didCompleteWithResults: ["foo": "bar"])

    XCTAssertTrue(
      wrappedDialog.wasDidCompleteWithResultsCalled,
      "Should call the delegate method on the underlying dialog"
    )
  }

  func testFailingWithError() {
    dialog.webDialog(webDialog, didFailWithError: SampleError())

    XCTAssertTrue(
      wrappedDialog.wasDidFailWithErrorCalled,
      "Should call the delegate method on the underlying dialog"
    )
  }

  func testCancelling() {
    dialog.webDialogDidCancel(webDialog)

    XCTAssertTrue(
      wrappedDialog.wasDidCancelCalled,
      "Should call the delegate method on the underlying dialog"
    )
  }

  func testDelegate() {
    dialog.delegate = self

    XCTAssertTrue(
      wrappedDialog.delegate === self,
      "Setting the delegate should set the delegate on the underlying dialog"
    )

    dialog.delegate = nil

    XCTAssertNil(
      wrappedDialog.delegate,
      "Setting the delegate should set the delegate on the underlying dialog"
    )
  }

  func testDialogContent() {
    dialog.dialogContent = content

    XCTAssertTrue(
      wrappedDialog.dialogContent === content,
      "Setting the delegate should set the dialog content on the underlying dialog"
    )

    dialog.dialogContent = nil

    XCTAssertNil(
      wrappedDialog.dialogContent,
      "Setting the delegate should set the dialog content on the underlying dialog"
    )
  }

  func testShowing() {
    _ = dialog.show()
    XCTAssertTrue(
      wrappedDialog.wasShowCalled,
      "Should call show on the underlying dialog"
    )
  }

  func testValidating() {
    try? dialog.validate()

    XCTAssertTrue(
      wrappedDialog.wasValidateCalled,
      "Should call validate on the underlying dialog"
    )
  }

  func testCurrentWebDialog() {
    dialog.currentWebDialog = webDialog

    XCTAssertTrue(
      wrappedDialog.currentWebDialog === webDialog,
      "Setting the current web dialog should set the web dialog on the underlying dialog"
    )

    dialog.currentWebDialog = nil

    XCTAssertNil(
      wrappedDialog.currentWebDialog,
      "Setting the current web dialog should set the web dialog on the underlying dialog"
    )
  }

  func testCreatingWebDialogFrame() {
    _ = dialog.createWebDialogFrame(width: 1, height: 1, windowFinder: windowFinder)

    XCTAssertTrue(
      wrappedDialog.wasCreateWebDialogCalled,
      "Should use the underlying dialog to create the web dialog"
    )
  }

  // MARK: - ContextDialogDelegate Conformance

  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {
    XCTFail("Should not be called")
  }

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {
    XCTFail("Should not be called")
  }

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {
    XCTFail("Should not be called")
  }
}
