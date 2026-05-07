/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation
import UIKit

/// Centralized debug logging for Limited Login refresh operations.
/// Uses the SDK's existing _Logger infrastructure.
enum RefreshDebugLogger {
  static func logRefreshStarted() {
    _Logger.singleShotLogEntry(.informational, logEntry: "Starting Limited Login silent refresh")
  }

  static func logGateKeeperDisabled() {
    _Logger.singleShotLogEntry(.developerErrors, logEntry: "Silent refresh disabled via GK: platform_login_oidc_prompt_none")
  }

  static func logRateLimited(waitTime: TimeInterval) {
    _Logger.singleShotLogEntry(.developerErrors, logEntry: "Refresh rate limited. Wait \(Int(waitTime))s")
  }

  static func logUserMismatch(expected: String, actual: String) {
    _Logger.singleShotLogEntry(
      .developerErrors,
      logEntry: "SECURITY: User ID mismatch. Expected: \(expected), Got: \(actual)"
    )
  }

  static func logRefreshSucceeded() {
    _Logger.singleShotLogEntry(.informational, logEntry: "Limited Login refresh completed. Profile updated.")
  }

  static func logRefreshFailed(_ error: LimitedLoginRefreshError) {
    _Logger.singleShotLogEntry(.developerErrors, logEntry: "Limited Login refresh failed: \(error)")
  }

  static func logUnsupportedPlatform() {
    _Logger.singleShotLogEntry(
      .developerErrors,
      logEntry: "Silent refresh requires iOS 13+. Current: \(UIDevice.current.systemVersion)"
    )
  }
}
