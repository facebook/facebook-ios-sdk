/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

struct SwitchContextDialogFactory: SwitchContextDialogMaking {

  let tokenProvider: AccessTokenProviding.Type

  init(tokenProvider: AccessTokenProviding.Type) {
    self.tokenProvider = tokenProvider
  }

  func makeSwitchContextDialog(
    content: SwitchContextContent,
    windowFinder: WindowFinding,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    guard tokenProvider.currentAccessToken != nil else {
      return nil
    }

    return SwitchContextDialog(
      content: content,
      windowFinder: windowFinder,
      delegate: delegate
    )
  }
}
