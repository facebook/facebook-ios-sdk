/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

@objcMembers
final class TestAEMManager: _AutoSetup {

  var enabled = false

  func configure(swizzler: _Swizzling.Type, reporter aemReporter: FBSDKCoreKit._AEMReporterProtocol.Type) {}

  func enable() {
    enabled = true
  }
}
