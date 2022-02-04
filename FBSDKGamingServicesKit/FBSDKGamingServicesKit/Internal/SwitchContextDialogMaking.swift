/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

protocol SwitchContextDialogMaking {
  func makeSwitchContextDialog(
    content: SwitchContextContent,
    windowFinder: _WindowFinding,
    delegate: ContextDialogDelegate
  ) throws -> Showable?
}
