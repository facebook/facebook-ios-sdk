/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestIAPDedupeProcessor: _IAPDedupeProcessing {
  var enableWasCalled = false
  var disableWasCalled = false

  func enable() {
    enableWasCalled = true
  }

  func disable() {
    disableWasCalled = true
  }
}
