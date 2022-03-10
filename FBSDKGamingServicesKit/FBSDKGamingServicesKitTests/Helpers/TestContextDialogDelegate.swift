/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKGamingServicesKit
import XCTest

final class TestContextDialogDelegate: NSObject, ContextDialogDelegate {
  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {}

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {}

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {}
}
