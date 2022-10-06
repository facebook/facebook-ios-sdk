/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

final class GamingWebDialogTests: XCTestCase {

  struct Success: GamingWebDialogSuccess {
    let payload: String?

    init(_ dict: [String: Any]) {
      payload = dict["payload"] as? String
    }
  }

  let payloadKey = "payload"
  let errorCodeKey = "error_code"
  let errorMessageKey = "error_message"

  // swiftlint:disable:next implicitly_unwrapped_optional
  var gamingWebDialog: GamingWebDialog<Success>!
  // swiftlint:disable:next implicitly_unwrapped_optional
  var webDialog: _WebDialog!

  var webDelegate: WebDialogDelegate { gamingWebDialog as WebDialogDelegate }
  var dialogCompleted = false
  var dialogFailed = false
  var error: Error?
  var payload: String?

  override func setUp() {
    super.setUp()
    error = nil
    payload = nil
    dialogCompleted = false
    dialogFailed = false

    gamingWebDialog = GamingWebDialog(name: "test")

    webDialog = _WebDialog(name: "Test")
    webDialog.delegate = webDelegate
    gamingWebDialog.dialog = webDialog
    gamingWebDialog.completion = { result in
      switch result {
      case let .success(success):
        self.dialogCompleted = true
        self.payload = success.payload
      case let .failure(error):
        self.dialogFailed = true
        self.error = error
      }
    }
  }

  func testDialogSucceedsWithPayload() throws {
    let testPayload = "test payload"

    gamingWebDialog.webDialog(webDialog, didCompleteWithResults: [payloadKey: testPayload])

    XCTAssertTrue(dialogCompleted)
    XCTAssertFalse(dialogFailed)
    XCTAssertNil(error)
    XCTAssertEqual(payload, testPayload)
  }

  func testDialogFailsWithError() throws {
    let testErrorCode = 418
    let testErrorMessage = "I'm a teapot"

    gamingWebDialog.webDialog(
      webDialog,
      didCompleteWithResults: [errorCodeKey: testErrorCode, errorMessageKey: testErrorMessage]
    )
    let error = try XCTUnwrap(error) as NSError

    XCTAssertFalse(dialogCompleted)
    XCTAssertTrue(dialogFailed)
    XCTAssertNotNil(error)
    XCTAssertEqual(error.code, testErrorCode)
    XCTAssertEqual(error.userInfo.values.first as? String, testErrorMessage)
  }

  func testDialogFailsWithUnknownError() throws {
    gamingWebDialog.webDialog(
      _WebDialog(name: "wrong dialog"),
      didCompleteWithResults: [:]
    )
    gamingWebDialog.show { _ in }
    let error = try XCTUnwrap(error) as NSError

    XCTAssertFalse(dialogCompleted)
    XCTAssertTrue(dialogFailed)
    XCTAssertNotNil(error)
  }

  func testDialogSucceedsEmptyWhenCanceled() throws {
    gamingWebDialog.webDialogDidCancel(webDialog)

    XCTAssertTrue(dialogCompleted)
    XCTAssertFalse(dialogFailed)
    XCTAssertNil(payload)
    XCTAssertNil(error)
  }
}
