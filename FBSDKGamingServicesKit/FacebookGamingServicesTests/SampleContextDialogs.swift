/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

enum SampleContextDialogs {

  static func showCreateContextDialog(withDelegate delegate: ContextDialogDelegate) -> CreateContextDialog? {
    let content = CreateContextContent(playerID: "1234567890")
    let dialog = CreateContextDialog(
      content: content,
      windowFinder: TestWindowFinder(),
      delegate: delegate
    )
    dialog.show()
    return dialog
  }

  static func showChooseContextDialogWithInvalidSizes(delegate: ContextDialogDelegate) -> ChooseContextDialog? {
    Settings.shared.appID = "abc123"
    let content = ChooseContextContent()
    content.minParticipants = 2
    content.maxParticipants = 1
    let dialog = ChooseContextDialog(content: content, delegate: delegate)

    return dialog
  }

  static func chooseContextDialogWithoutContentValues(delegate: ContextDialogDelegate) -> ChooseContextDialog? {
    let content = ChooseContextContent()
    let dialog = ChooseContextDialog(content: content, delegate: delegate)

    return dialog
  }

  static func chooseContextDialog(
    utility: InternalUtilityProtocol,
    delegate: ContextDialogDelegate
  ) -> ChooseContextDialog? {
    let content = ChooseContextContent()
    let dialog = ChooseContextDialog(content: content, delegate: delegate, internalUtility: utility)

    return dialog
  }
}
