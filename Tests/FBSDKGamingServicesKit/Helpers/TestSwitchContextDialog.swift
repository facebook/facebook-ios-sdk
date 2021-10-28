/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

class TestSwitchContextDialog: SwitchContextDialogProtocol {

  // MARK: Test Evidence
  var wasDidCompleteWithResultsCalled = false
  var wasDidFailWithErrorCalled = false
  var wasDidCancelCalled = false
  var wasShowCalled = false
  var wasValidateCalled = false
  var wasCreateWebDialogCalled = false

  // MARK: Protocol Conformance
  var delegate: ContextDialogDelegate?
  var dialogContent: ValidatableProtocol?
  var currentWebDialog: WebDialog?

  func createWebDialogFrame(
    withWidth: CGFloat,
    height: CGFloat,
    windowFinder: WindowFinding
  ) -> CGRect {
    wasCreateWebDialogCalled = true

    return .zero
  }

  func webDialogDidCancel(_ webDialog: WebDialog) {
    wasDidCancelCalled = true
  }

  func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    wasDidFailWithErrorCalled = true
  }

  func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [String: Any]) {
    wasDidCompleteWithResultsCalled = true
  }

  func show() -> Bool {
    wasShowCalled = true

    return false
  }

  func validate() throws {
    wasValidateCalled = true
  }
}
