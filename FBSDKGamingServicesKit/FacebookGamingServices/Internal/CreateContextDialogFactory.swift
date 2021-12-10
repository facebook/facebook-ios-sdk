/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

struct CreateContextDialogFactory: CreateContextDialogMaking {
  private var tokenProvider: AccessTokenProviding.Type

  init(tokenProvider: AccessTokenProviding.Type) {
    self.tokenProvider = tokenProvider
  }

  func makeCreateContextDialog(
    content: CreateContextContent,
    windowFinder: WindowFinding,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    guard tokenProvider.currentAccessToken != nil else {
      return nil
    }

    return CreateContextDialog(
      content: content,
      windowFinder: windowFinder,
      delegate: delegate
    )
  }
}
