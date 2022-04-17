/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

class TestCAPIReporter: CAPIReporter {

  var enabledWasCalled = false
  var capturedFactory: GraphRequestFactoryProtocol?
  var capturedSettings: SettingsProtocol?
  var capturedEvent: [String: Any]?

  func enable() {
    enabledWasCalled = true
  }

  func configure(factory: GraphRequestFactoryProtocol, settings: SettingsProtocol) {
    capturedFactory = factory
    capturedSettings = settings
  }

  func recordEvent(_ parameters: [String: Any]) {
    capturedEvent = parameters
  }
}
