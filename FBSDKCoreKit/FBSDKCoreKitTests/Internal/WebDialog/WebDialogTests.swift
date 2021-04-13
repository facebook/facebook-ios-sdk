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

import FBSDKCoreKit
import XCTest

class WebDialogTests: XCTestCase, WebDialogDelegate {

  let windowFinder = TestWindowFinder()
  var webDialogDidCancelWasCalled = false
  var webDialogDidFailWasCalled = false
  var capturedDidCompleteResults: [String: String]?
  var capturedError: Error?
  var parameters = ["foo": "bar"]

  func testShowWithInvalidUrlFromParameters() {
    let dialog = createAndShowDialog(name: name, windowFinder: windowFinder)

    XCTAssertEqual(
      dialog.name,
      name,
      "Should create a dialog with the provided name"
    )
    XCTAssertEqual(
      dialog.parameters as? [String: String],
      parameters,
      "Should create a dialog with the provided parameters"
    )
    XCTAssertTrue(
      dialog.delegate === self,
      "Should create a dialog with the provided delegate"
    )
    XCTAssertTrue(
      self.webDialogDidFailWasCalled,
      "Should fail to show if it cannot parse a url from the parameters"
    )
  }

  func testShowWithValidUrlFromParametersWithoutWindow() {
    createAndShowDialog(windowFinder: windowFinder)

    XCTAssertTrue(
      self.webDialogDidFailWasCalled,
      "Should fail to show if it cannot locate a window to present in"
    )
  }

  func testShowWithValidUrlFromParametersWithWindow() {
    createAndShowDialog()

    XCTAssertFalse(
      self.webDialogDidFailWasCalled,
      "Should not fail to show if it can locate a window to present in"
    )
  }

  // MARK: - Delegate Methods

  func testDidCompleteWithResults() {
    guard let dialog = createAndShowDialog() as? WebDialogViewDelegate else {
      return XCTFail("Web dialog should be a web dialog view delegate")
    }
    let results = ["foo": name]

    dialog.webDialogView(nil, didCompleteWithResults: results)

    XCTAssertEqual(
      capturedDidCompleteResults,
      results,
      "Should call the web dialog delegate methods when the web dialog view delegate methods are called"
    )
  }

  func testDidFailWithError() {
    guard let dialog = createAndShowDialog() as? WebDialogViewDelegate else {
      return XCTFail("Web dialog should be a web dialog view delegate")
    }

    dialog.webDialogView(nil, didFailWithError: SampleError())

    XCTAssertTrue(
      capturedError is SampleError,
      "Should call the web dialog delegate methods when the web dialog view delegate methods are called"
    )
  }

  func testDidCancel() {
    guard let dialog = createAndShowDialog() as? WebDialogViewDelegate else {
      return XCTFail("Web dialog should be a web dialog view delegate")
    }

    dialog.webDialogViewDidCancel(nil)

    XCTAssertTrue(
      webDialogDidCancelWasCalled,
      "Should call the web dialog delegate methods when the web dialog view delegate methods are called"
    )
  }

  // MARK: - Helpers

  @discardableResult
  func createAndShowDialog(
    name: String = "example",
    parameters: [String: String]? = nil,
    windowFinder: TestWindowFinder = TestWindowFinder(stubbedWindow: UIWindow()),
    delegate: WebDialogDelegate? = nil
  ) -> WebDialog {
    return WebDialog.show(
      withName: name,
      parameters: parameters ?? self.parameters,
      windowFinder: windowFinder,
      delegate: delegate ?? self
    )
  }

  func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [AnyHashable: Any]) {
    capturedDidCompleteResults = results as? [String: String]
  }

  func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    capturedError = error
    webDialogDidFailWasCalled = true
  }

  func webDialogDidCancel(_ webDialog: WebDialog) {
    webDialogDidCancelWasCalled = true
  }
}
