/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

extension LoginManager {
  /// Cleans up Limited Login refresh state.
  /// Call this during logout to reset rate limiter and stop background refresh.
  func cleanupLimitedLoginRefreshState() {
    RefreshRateLimiter.shared.reset()
    BackgroundRefreshManager.shared.stopAutoRefresh()
  }
}
