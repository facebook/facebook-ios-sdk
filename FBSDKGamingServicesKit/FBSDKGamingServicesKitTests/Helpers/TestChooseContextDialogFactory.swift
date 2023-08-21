/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

final class TestChooseContextDialogFactory: ChooseContextDialogMaking {
  let dialog = TestShowable()
  var wasMakeChooseContextDialogCalled = false
  var capturedDelegate: ContextDialogDelegate?

  func makeChooseContextDialog(
    content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable {
    wasMakeChooseContextDialogCalled = true
    capturedDelegate = delegate

    return dialog
  }
}
