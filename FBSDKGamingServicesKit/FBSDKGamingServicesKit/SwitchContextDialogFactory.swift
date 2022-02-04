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
    windowFinder: _WindowFinding,
    delegate: ContextDialogDelegate
  ) throws -> Showable? {
    guard tokenProvider.currentAccessToken != nil else {
      throw ContextDialogPresenterError.invalidAccessToken
    }

    return SwitchContextDialog(
      content: content,
      windowFinder: windowFinder,
      delegate: delegate
    )
  }
}
