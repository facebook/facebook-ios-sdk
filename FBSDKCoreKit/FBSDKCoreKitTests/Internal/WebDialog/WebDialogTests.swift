/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import TestTools
import XCTest

class WebDialogTests: XCTestCase, WebDialogDelegate {

  let windowFinder = TestWindowFinder()
  let dialogView = FBWebDialogView()
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

  // MARK: - Delegate Methods

  func testDidCompleteWithResults() {
    guard let dialog = createAndShowDialog() as? WebDialogViewDelegate else {
      return XCTFail("Web dialog should be a web dialog view delegate")
    }
    let results = ["foo": name]

    dialog.webDialogView(dialogView, didCompleteWithResults: results)

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

    dialog.webDialogView(dialogView, didFailWithError: SampleError())

    XCTAssertTrue(
      capturedError is SampleError,
      "Should call the web dialog delegate methods when the web dialog view delegate methods are called"
    )
  }

  func testDidCancel() {
    guard let dialog = createAndShowDialog() as? WebDialogViewDelegate else {
      return XCTFail("Web dialog should be a web dialog view delegate")
    }

    dialog.webDialogViewDidCancel(dialogView)

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
    windowFinder: TestWindowFinder = TestWindowFinder(window: UIWindow()),
    delegate: WebDialogDelegate? = nil
  ) -> WebDialog {
    WebDialog.show(
      withName: name,
      parameters: parameters ?? self.parameters,
      delegate: delegate ?? self
    )
  }

  func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [String: Any]) {
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
