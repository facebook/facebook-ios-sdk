/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

// swiftlint:disable implicitly_unwrapped_optional

final class WebDialogTests: XCTestCase, WebDialogDelegate {

  var windowFinder: _WindowFinding!
  var dialogView: FBWebDialogView!
  var errorFactory: ErrorCreating!
  var webDialogDidCancelWasCalled = false
  var webDialogDidFailWasCalled = false
  var capturedDidCompleteResults: [String: String]?
  var capturedError: Error?
  var parameters = ["foo": "bar"]

  override func setUp() {
    errorFactory = TestErrorFactory()
    windowFinder = TestWindowFinder(window: UIWindow())
    dialogView = FBWebDialogView()

    _WebDialog.setDependencies(.init(errorFactory: errorFactory, windowFinder: windowFinder))
    super.setUp()
  }

  override func tearDown() {
    windowFinder = nil
    dialogView = nil
    errorFactory = nil

    _WebDialog.resetDependencies()

    super.tearDown()
  }

  func testDefaultTypeDependencies() throws {
    _WebDialog.resetDependencies()
    let dependencies = try _WebDialog.getDependencies()

    XCTAssertTrue(
      dependencies.errorFactory is _ErrorFactory,
      .defaultDependency("the error factory", for: "creating errors")
    )

    XCTAssertIdentical(
      dependencies.windowFinder as AnyObject,
      InternalUtility.shared,
      .defaultDependency("the shared InternalUtility", for: "window finding")
    )
  }

  func testCustomTypeDependencies() throws {
    let dependencies = try _WebDialog.getDependencies()

    XCTAssertIdentical(
      dependencies.errorFactory as AnyObject,
      errorFactory,
      .customDependency(for: "error factoring")
    )

    XCTAssertIdentical(
      dependencies.windowFinder as AnyObject,
      windowFinder,
      .customDependency(for: "window finding")
    )
  }

  func testShowWithInvalidURLFromParameters() {
    let dialog = createAndShowDialog(name: name)

    XCTAssertEqual(
      dialog.name,
      name,
      "Should create a dialog with the provided name"
    )
    XCTAssertEqual(
      dialog.parameters,
      parameters,
      "Should create a dialog with the provided parameters"
    )
    XCTAssertTrue(
      dialog.delegate === self,
      "Should create a dialog with the provided delegate"
    )
    XCTAssertTrue(
      webDialogDidFailWasCalled,
      "Should fail to show if it cannot parse a url from the parameters"
    )
  }

  func testShowWithValidURLFromParametersWithoutWindow() {
    _WebDialog.resetDependencies()
    createAndShowDialog()

    XCTAssertTrue(
      webDialogDidFailWasCalled,
      "Should fail to show if it cannot locate a window to present in"
    )
  }

  // MARK: - Delegate Methods

  func testDidCompleteWithResults() {
    let dialog = createAndShowDialog()
    let results = ["foo": name]

    dialog.webDialogView(dialogView, didCompleteWithResults: results)

    XCTAssertEqual(
      capturedDidCompleteResults,
      results,
      "Should call the web dialog delegate methods when the web dialog view delegate methods are called"
    )
  }

  func testDidFailWithError() {
    let dialog = createAndShowDialog()

    dialog.webDialogView(dialogView, didFailWithError: SampleError())

    XCTAssertTrue(
      capturedError is SampleError,
      "Should call the web dialog delegate methods when the web dialog view delegate methods are called"
    )
  }

  func testDidCancel() {
    let dialog = createAndShowDialog()

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
    delegate: WebDialogDelegate? = nil
  ) -> _WebDialog {
    let webDialog = _WebDialog(name: name, parameters: parameters ?? self.parameters)
    webDialog.delegate = delegate ?? self
    webDialog.show()
    return webDialog
  }

  func webDialog(_ webDialog: _WebDialog, didCompleteWithResults results: [String: Any]) {
    capturedDidCompleteResults = results as? [String: String]
  }

  func webDialog(_ webDialog: _WebDialog, didFailWithError error: Error) {
    capturedError = error
    webDialogDidFailWasCalled = true
  }

  func webDialogDidCancel(_ webDialog: _WebDialog) {
    webDialogDidCancelWasCalled = true
  }
}

// swiftformat:disable extensionaccesscontrol

// MARK: - Assumptions

fileprivate extension String {
  static func defaultDependency(_ dependency: String, for type: String) -> String {
    "The _WebDialog type uses \(dependency) as its \(type) dependency by default"
  }

  static func customDependency(for type: String) -> String {
    "The _WebDialog type uses a custom \(type) dependency when provided"
  }
}
