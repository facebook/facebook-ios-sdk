/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class IAPDedupeProcessor: _IAPDedupeProcessing {
  private var isEnabled = false

  func enable() {
    guard !isEnabled else {
      return
    }
    isEnabled = true
  }

  func disable() {
    guard isEnabled else {
      return
    }
    isEnabled = false
  }
}
