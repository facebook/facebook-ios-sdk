/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit

final class TestCreateContextDialogFactory: CreateContextDialogMaking {
  let dialog = TestShowable()
  var wasMakeCreateContextDialogCalled = false
  var capturedDelegate: ContextDialogDelegate?
  var shouldCreateDialog = true

  func makeCreateContextDialog(
    content: CreateContextContent,
    windowFinder: _WindowFinding,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    wasMakeCreateContextDialogCalled = true
    capturedDelegate = delegate

    return shouldCreateDialog ? dialog : nil
  }
}
