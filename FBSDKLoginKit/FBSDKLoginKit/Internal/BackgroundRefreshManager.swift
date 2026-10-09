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
/// Once started, this class observes `UIApplication.willEnterForegroundNotification` and triggers
/// a DPoP-bound refresh of the Limited Login session if:
/// - A Limited Login profile is active (Profile.current exists and is limited)
/// - An AuthenticationToken is present
/// - Enough time has elapsed since the last background refresh
///
/// It is started when a Limited Login session is established, when the app calls
/// `refreshLimitedLogin`, and at launch when the SDK restores a cached Limited Login session
/// (see `_LimitedLoginRestoredSessionObserver`). Starting is idempotent, and starting again after
/// `stopAutoRefresh()` (logout) re-registers the observer.
///
/// The refresh runs via `.directOnly` (a DPoP-bound HTTPS POST with no UI). Tokens
/// without a `cnf.jkt` binding fall through as `.notDPoPBound` and the manager
/// makes no further attempt for that foreground; the next interactive login will
/// mint a bound token and unblock subsequent foregrounds. The server-side feature
/// flag (`FBSDKFeatureLimitedLoginRefresh`) is the kill switch — when off, every
/// attempt returns `.featureDisabled` and is a no-op.
///
/// The time of the last successful refresh is persisted, so the minimum interval
/// (`Settings.shared.limitedLoginAutoRefreshInterval`) also applies across app launches.
///
/// On success, `Profile.current` and `AuthenticationToken.current` are updated,
/// which automatically posts `ProfileDidChange` via the Profile setter.
///
/// ## Thread Safety
/// All mutable state is protected by an `NSLock`.
final class BackgroundRefreshManager {

  typealias Refresher = (@escaping (Bool) -> Void) -> Void

  static let shared = BackgroundRefreshManager()

  static let lastRefreshDefaultsKey = "com.facebook.sdk:FBSDKLimitedLoginLastAutoRefresh"

  private let notificationCenter: NotificationCenter
  private let dataStore: UserDefaults
  private let dateProvider: () -> Date
  private let intervalProvider: () -> TimeInterval
  private let hasLimitedLoginSession: () -> Bool
  private let refresher: Refresher

  private var isObserving = false
  private var isRefreshing = false
  private let lock = NSLock()

  init(
    notificationCenter: NotificationCenter = .default,
    dataStore: UserDefaults = .standard,
    dateProvider: @escaping () -> Date = Date.init,
    intervalProvider: @escaping () -> TimeInterval = { Settings.shared.limitedLoginAutoRefreshInterval },
    hasLimitedLoginSession: @escaping () -> Bool = BackgroundRefreshManager.currentSessionIsLimitedLogin,
    refresher: @escaping Refresher = BackgroundRefreshManager.refreshDirectly
  ) {
    self.notificationCenter = notificationCenter
    self.dataStore = dataStore
    self.dateProvider = dateProvider
    self.intervalProvider = intervalProvider
    self.hasLimitedLoginSession = hasLimitedLoginSession
    self.refresher = refresher
  }

  // MARK: - Notification Observer

  /// Starts observing foreground notifications. Safe to call more than once.
  func startAutoRefresh() {
    lock.lock()
    defer { lock.unlock() }

    guard !isObserving else { return }

    notificationCenter.addObserver(
      self,
      selector: #selector(appWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    isObserving = true
  }

  @objc private func appWillEnterForeground() {
    attemptBackgroundRefresh()
  }

  // MARK: - Refresh Logic

  func attemptBackgroundRefresh() {
    // Must be a Limited Login session with an AuthenticationToken
    guard hasLimitedLoginSession() else { return }

    lock.lock()

    // Don't start another refresh if one is already in progress
    guard !isRefreshing else {
      lock.unlock()
      return
    }

    // Enforce minimum interval between background refreshes
    if let lastRefresh = lastBackgroundRefresh,
       dateProvider().timeIntervalSince(lastRefresh) < intervalProvider() {
      lock.unlock()
      return
    }

    isRefreshing = true
    lock.unlock()

    refresher { [weak self] succeeded in
      guard let self else { return }

      self.lock.lock()
      self.isRefreshing = false
      if succeeded {
        self.lastBackgroundRefresh = self.dateProvider()
      }
      self.lock.unlock()
    }
  }

  // MARK: - Lifecycle

  /// Resets all internal state, including the persisted time of the last refresh. Useful for logout and testing.
  func reset() {
    lock.lock()
    defer { lock.unlock() }

    lastBackgroundRefresh = nil
    isRefreshing = false
  }

  /// Stops observing foreground notifications and resets state.
  /// Call during logout cleanup to prevent refreshes for a logged-out user.
  func stopAutoRefresh() {
    lock.lock()
    notificationCenter.removeObserver(
      self,
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    isObserving = false
    lock.unlock()

    reset()
  }

  // MARK: - Persistence

  // Must be accessed while holding `lock`.
  private var lastBackgroundRefresh: Date? {
    get {
      guard let timestamp = dataStore.object(forKey: Self.lastRefreshDefaultsKey) as? TimeInterval else {
        return nil
      }
      return Date(timeIntervalSince1970: timestamp)
    }
    set {
      if let newValue {
        dataStore.set(newValue.timeIntervalSince1970, forKey: Self.lastRefreshDefaultsKey)
      } else {
        dataStore.removeObject(forKey: Self.lastRefreshDefaultsKey)
      }
    }
  }

  // MARK: - Production defaults

  static func currentSessionIsLimitedLogin() -> Bool {
    guard let profile = Profile.current else { return false }

    return profile.isLimited && AuthenticationToken.current != nil
  }

  static func refreshDirectly(completion: @escaping (Bool) -> Void) {
    LoginManager().refreshLimitedLogin(from: nil, fallbackPolicy: .directOnly) { result in
      switch result {
      case .success:
        completion(true)
      case .failure:
        completion(false)
      }
    }
  }
}

// MARK: - Restored sessions

/// Starts Limited Login auto-refresh for a session restored from the token cache at launch.
///
/// `ApplicationDelegate` (CoreKit) looks this type up by its Objective-C name, so the name must not change.
///
/// It lives in this file on purpose: CoreKit only reaches it by name, so nothing references it directly. When an app
/// links the SDK statically, the linker only loads object files that something references, and a type in a file of its
/// own would be left out. `LoginManager` always references this file.
@objc(FBSDKLimitedLoginRestoredSessionObserver)
final class _LimitedLoginRestoredSessionObserver: NSObject, _RestoredAuthenticationSessionObserving {

  static var refreshManager = BackgroundRefreshManager.shared

  static func didRestoreAuthenticationSession() {
    refreshManager.startAutoRefresh()
    // The launch itself counts as a foreground: no willEnterForeground notification is posted for it.
    refreshManager.attemptBackgroundRefresh()
  }
}
