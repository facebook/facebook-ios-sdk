/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Provides diagnostic information about the Limited Login Refresh system.
///
/// This struct exposes internal SDK state for debugging and testing purposes,
/// such as GateKeeper status and rate limiter state, without making the
/// underlying internal types public.
public struct LimitedLoginRefreshDiagnostics {
  /// Whether silent refresh is enabled via GateKeeper.
  public let isGateKeeperEnabled: Bool

  /// Whether a refresh attempt is currently allowed by the rate limiter.
  public let canAttemptRefresh: Bool

  /// Seconds until the next refresh attempt is allowed (0 if allowed now).
  public let timeUntilNextRefresh: TimeInterval

  /// Returns a snapshot of the current diagnostic state.
  public static func current() -> LimitedLoginRefreshDiagnostics {
    LimitedLoginRefreshDiagnostics(
      isGateKeeperEnabled: RefreshGateKeeperCheck.isSilentRefreshEnabled(),
      canAttemptRefresh: RefreshRateLimiter.shared.canAttemptRefresh(),
      timeUntilNextRefresh: RefreshRateLimiter.shared.timeUntilNextAllowedAttempt()
    )
  }

  /// Resets the rate limiter state. Useful for testing.
  public static func resetRateLimiter() {
    RefreshRateLimiter.shared.reset()
  }
}
