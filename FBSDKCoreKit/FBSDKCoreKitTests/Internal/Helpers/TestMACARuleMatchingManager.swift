/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

final class TestMACARuleMatchingManager: MACARuleMatching {

  var enabledWasCalled = false

  func enable() {
    enabledWasCalled = true
  }

  func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary? { params }
}
