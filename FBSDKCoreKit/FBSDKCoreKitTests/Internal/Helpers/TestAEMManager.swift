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
  var proxyEnabled = false
  var autoSetupStatus = false
  var source: String?

  // swiftlint:disable:next function_parameter_count
  func configure(
    swizzler: _Swizzling.Type,
    reporter aemReporter: FBSDKCoreKit._AEMReporterProtocol.Type,
    eventLogger: EventLogging,
    crashHandler: CrashHandlerProtocol,
    featureChecker: _FeatureDisabling,
    appEventsUtility: _AppEventsUtilityProtocol
  ) {}

  func enable(_ proxyEnabled: Bool) {
    enabled = true
    self.proxyEnabled = proxyEnabled
  }

  func logAutoSetupStatus(_ optin: Bool, source: String) {
    autoSetupStatus = optin
    self.source = source
  }
}
