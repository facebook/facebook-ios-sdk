/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Configuration for refresh rate limiting.
enum RateLimitConfig {

  /// Minimum interval between refresh attempts (60 seconds).
  /// Prevents rapid-fire refresh attempts that could overload the server.
  static let minimumInterval: TimeInterval = 60.0

  /// Cooldown period after a failure (5 minutes).
  /// Prevents retry storms when there are persistent server issues.
  static let failureCooldown: TimeInterval = 300.0

  /// Maximum refresh attempts per hour.
  /// Absolute cap to prevent abuse regardless of success/failure.
  static let maxAttemptsPerHour = 10
}

/// Rate limiter for Limited Login refresh operations.
///
/// This class implements client-side rate limiting to prevent abuse and protect
/// against excessive server load. It enforces:
/// - Minimum interval between any refresh attempts
/// - Extended cooldown after failures
/// - Maximum attempts per hour
///
/// ## Usage
/// ```swift
/// let rateLimiter = RefreshRateLimiter.shared
///
/// if rateLimiter.canAttemptRefresh() {
///     rateLimiter.recordAttempt()
///     performRefresh { result in
///         switch result {
///         case .success:
///             rateLimiter.recordSuccess()
///         case .failure:
///             rateLimiter.recordFailure()
///         }
///     }
/// } else {
///     let waitTime = rateLimiter.timeUntilNextAllowedAttempt()
///     print("Rate limited. Try again in \(waitTime) seconds.")
/// }
/// ```
///
/// ## Thread Safety
/// All public methods are thread-safe and can be called from any queue.
final class RefreshRateLimiter {

  /// Shared instance for app-wide rate limiting.
  static let shared = RefreshRateLimiter()

  /// Timestamp of the last refresh attempt (success or failure).
  private var lastRefreshAttempt: Date?

  /// Timestamp of the last failed refresh attempt.
  /// Used to enforce the extended failure cooldown.
  private var lastFailureTime: Date?

  /// Timestamps of all recent refresh attempts within the last hour.
  /// Used to enforce the hourly limit.
  private var attemptTimestamps: [Date] = []

  /// Lock for thread-safe access to mutable state.
  private let lock = NSLock()

  /// Provides the current date. Defaults to `Date.init`.
  /// Tests inject a controllable closure to avoid `sleep()`.
  let dateProvider: () -> Date

  /// Creates a new rate limiter instance.
  ///
  /// Use `RefreshRateLimiter.shared` for the app-wide singleton.
  /// Pass a custom `dateProvider` in tests for deterministic time control.
  init(dateProvider: @escaping () -> Date = Date.init) {
    self.dateProvider = dateProvider
  }

  /// Checks if a refresh attempt is allowed based on rate limits.
  ///
  /// This method checks all rate limiting conditions:
  /// 1. Minimum interval since last attempt (60 seconds)
  /// 2. Failure cooldown period (5 minutes after failure)
  /// 3. Hourly attempt limit (10 attempts per hour)
  ///
  /// - Returns: `true` if a refresh attempt is allowed, `false` if rate-limited.
  func canAttemptRefresh() -> Bool {
    lock.lock()
    defer { lock.unlock() }

    let now = dateProvider()

    // Check minimum interval between attempts
    if let lastAttempt = lastRefreshAttempt,
       now.timeIntervalSince(lastAttempt) < RateLimitConfig.minimumInterval {
      return false
    }

    // Check failure cooldown
    if let lastFailure = lastFailureTime,
       now.timeIntervalSince(lastFailure) < RateLimitConfig.failureCooldown {
      return false
    }

    // Check hourly limit - remove expired timestamps first
    let oneHourAgo = now.addingTimeInterval(-3600)
    attemptTimestamps = attemptTimestamps.filter { $0 > oneHourAgo }
    if attemptTimestamps.count >= RateLimitConfig.maxAttemptsPerHour {
      return false
    }

    return true
  }

  /// Returns the time remaining until the next refresh attempt is allowed.
  ///
  /// This considers all rate limiting conditions and returns the maximum
  /// wait time required to satisfy all of them.
  ///
  /// - Returns: Time interval in seconds until refresh is allowed, or 0 if allowed now.
  func timeUntilNextAllowedAttempt() -> TimeInterval {
    lock.lock()
    defer { lock.unlock() }

    let now = dateProvider()
    var maxWait: TimeInterval = 0

    // Check minimum interval
    if let lastAttempt = lastRefreshAttempt {
      let elapsed = now.timeIntervalSince(lastAttempt)
      if elapsed < RateLimitConfig.minimumInterval {
        maxWait = max(maxWait, RateLimitConfig.minimumInterval - elapsed)
      }
    }

    // Check failure cooldown
    if let lastFailure = lastFailureTime {
      let elapsed = now.timeIntervalSince(lastFailure)
      if elapsed < RateLimitConfig.failureCooldown {
        maxWait = max(maxWait, RateLimitConfig.failureCooldown - elapsed)
      }
    }

    // If hourly limit is reached, wait until the oldest attempt
    // falls outside the 1-hour window.
    let oneHourAgo = now.addingTimeInterval(-3600)
    let recentAttempts = attemptTimestamps.filter { $0 > oneHourAgo }
    if recentAttempts.count >= RateLimitConfig.maxAttemptsPerHour,
       let oldest = recentAttempts.min() {
      let waitForHourlyLimit = oldest.addingTimeInterval(3600).timeIntervalSince(now)
      maxWait = max(maxWait, waitForHourlyLimit)
    }

    return max(0, maxWait)
  }

  /// Records that a refresh attempt is starting.
  ///
  /// Call this method immediately before starting a refresh operation.
  /// This updates the last attempt timestamp and adds to the hourly count.
  func recordAttempt() {
    lock.lock()
    defer { lock.unlock() }

    let now = dateProvider()
    lastRefreshAttempt = now
    attemptTimestamps.append(now)

    // Clean up old timestamps to prevent unbounded growth
    let oneHourAgo = now.addingTimeInterval(-3600)
    attemptTimestamps = attemptTimestamps.filter { $0 > oneHourAgo }
  }

  /// Records that a refresh attempt failed.
  ///
  /// Call this method when a refresh operation fails. This triggers
  /// the extended failure cooldown period (5 minutes by default).
  func recordFailure() {
    lock.lock()
    defer { lock.unlock() }

    lastFailureTime = dateProvider()
  }

  /// Records that a refresh attempt succeeded.
  ///
  /// Call this method when a refresh operation succeeds. This clears
  /// the failure cooldown, allowing normal refresh intervals to resume.
  func recordSuccess() {
    lock.lock()
    defer { lock.unlock() }

    lastFailureTime = nil
  }

  /// Resets all rate limiting state.
  ///
  /// This is useful for:
  /// - Unit testing
  /// - User logout (new user should have fresh rate limits)
  /// - Debugging
  func reset() {
    lock.lock()
    defer { lock.unlock() }

    lastRefreshAttempt = nil
    lastFailureTime = nil
    attemptTimestamps.removeAll()
  }
}
