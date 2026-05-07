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

/// Manages automatic background refresh of Limited Login sessions.
///
/// When enabled, this class observes `UIApplication.willEnterForegroundNotification`
/// and automatically triggers a silent Limited Login refresh if:
/// - A Limited Login profile is active (Profile.current exists, AccessToken.current is nil)
/// - An AuthenticationToken is present
/// - Enough time has elapsed since the last background refresh
///
/// The refresh runs silently (`.silentOnly`) and fails without user-facing errors.
/// On success, `Profile.current` and `AuthenticationToken.current` are updated,
/// which automatically posts `ProfileDidChange` via the Profile setter.
///
/// ## Thread Safety
/// All mutable state is protected by an `NSLock`.
final class BackgroundRefreshManager {

  static let shared = BackgroundRefreshManager()

  // TODO: Replace with Settings.shared.limitedLoginAutoRefreshInterval when the property is added to FBSDKCoreKit.
  private static let defaultAutoRefreshInterval: TimeInterval = 86_400.0

  private var lastBackgroundRefresh: Date?
  private var isRefreshing = false
  private let lock = NSLock()

  private init() {
    setupNotificationObserver()
  }

  // MARK: - Notification Observer

  private func setupNotificationObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
  }

  @objc private func appWillEnterForeground() {
    attemptBackgroundRefresh()
  }

  // MARK: - Refresh Logic

  func attemptBackgroundRefresh() {
    // TODO: Check Settings.shared.isLimitedLoginAutoRefreshEnabled when the property is added to FBSDKCoreKit.

    // Must be a Limited Login session with an AuthenticationToken
    guard let profile = Profile.current,
          profile.isLimited,
          AuthenticationToken.current != nil else {
      return
    }

    lock.lock()

    // Don't start another refresh if one is already in progress
    guard !isRefreshing else {
      lock.unlock()
      return
    }

    // Enforce minimum interval between background refreshes
    if let lastRefresh = lastBackgroundRefresh,
       Date().timeIntervalSince(lastRefresh) < Self.defaultAutoRefreshInterval {
      lock.unlock()
      return
    }

    isRefreshing = true
    lock.unlock()

    LoginManager().refreshLimitedLogin(from: nil, fallbackPolicy: .silentOnly) { [weak self] result in
      guard let self else { return }

      self.lock.lock()
      self.isRefreshing = false
      switch result {
      case .success:
        self.lastBackgroundRefresh = Date()
      case .failure:
        break
      }
      self.lock.unlock()
    }
  }

  // MARK: - Lifecycle

  /// Resets all internal state. Useful for logout and testing.
  func reset() {
    lock.lock()
    defer { lock.unlock() }

    lastBackgroundRefresh = nil
    isRefreshing = false
  }

  /// Stops observing foreground notifications and resets state.
  /// Call during logout cleanup to prevent refreshes for a logged-out user.
  func stopAutoRefresh() {
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    reset()
  }
}
