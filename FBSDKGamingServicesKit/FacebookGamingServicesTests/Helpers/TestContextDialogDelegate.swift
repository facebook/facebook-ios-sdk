/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import XCTest

class TestContextDialogDelegate: NSObject, ContextDialogDelegate {
  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {
    XCTFail("This should not be invoked")
  }

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {
    XCTFail("This should not be invoked")
  }

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {
    XCTFail("This should not be invoked")
  }
}
