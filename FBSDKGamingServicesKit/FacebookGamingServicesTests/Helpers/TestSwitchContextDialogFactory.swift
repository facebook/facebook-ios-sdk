/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices

class TestSwitchContextDialogFactory: SwitchContextDialogMaking {
  let dialog = TestShowable()
  var wasMakeSwitchContextDialogCalled = false
  var capturedDelegate: ContextDialogDelegate?
  var shouldCreateDialog = true

  func makeSwitchContextDialog(
    content: SwitchContextContent,
    windowFinder: WindowFinding,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    wasMakeSwitchContextDialogCalled = true
    capturedDelegate = delegate

    return shouldCreateDialog ? dialog : nil
  }
}
