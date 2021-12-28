/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKGamingServicesKit
import TestTools
import XCTest

class SwitchContextDialogTests: XCTestCase, ContextDialogDelegate {
  func testCreating() {
    let content = SwitchContextContent(contextID: "12345")
    let windowFinder = TestWindowFinder()

    let dialog = SwitchContextDialog(content: content, windowFinder: windowFinder, delegate: self)

    XCTAssertNotNil(
      dialog,
      "The existing objc interface for creating a dialog should be available"
    )
  }

  // MARK: - Delegate conformance

  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {}

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {}

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {}
}
