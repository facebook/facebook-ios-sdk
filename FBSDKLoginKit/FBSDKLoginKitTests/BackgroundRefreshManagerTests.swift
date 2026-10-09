/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import FBSDKCoreKit
import XCTest

final class BackgroundRefreshManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var notificationCenter: NotificationCenter!
  var dataStore: UserDefaults!
  var currentDate: Date!
  var hasSession: Bool!
  var refreshCompletions: [(Bool) -> Void]!
  var manager: BackgroundRefreshManager!
  // swiftlint:enable implicitly_unwrapped_optional

  let suiteName = "BackgroundRefreshManagerTests"
  let interval: TimeInterval = 24 * 60 * 60

  override func setUp() {
    super.setUp()

    notificationCenter = NotificationCenter()
    UserDefaults().removePersistentDomain(forName: suiteName)
    dataStore = UserDefaults(suiteName: suiteName)
    currentDate = Date()
    hasSession = true
    refreshCompletions = []
    manager = makeManager()
  }

  override func tearDown() {
    manager.stopAutoRefresh()
    UserDefaults().removePersistentDomain(forName: suiteName)
    notificationCenter = nil
    dataStore = nil
    currentDate = nil
    hasSession = nil
    refreshCompletions = nil
    manager = nil

    super.tearDown()
  }

  func makeManager() -> BackgroundRefreshManager {
    BackgroundRefreshManager(
      notificationCenter: notificationCenter,
      dataStore: dataStore,
      dateProvider: { [unowned self] in currentDate },
      intervalProvider: { [unowned self] in interval },
      hasLimitedLoginSession: { [unowned self] in hasSession },
      refresher: { [unowned self] completion in refreshCompletions.append(completion) }
    )
  }

  func postWillEnterForeground() {
    notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
  }

  // MARK: - Observing

  func testDoesNotRefreshOnForegroundBeforeStarting() {
    postWillEnterForeground()

    XCTAssertTrue(refreshCompletions.isEmpty, "Should not observe foregrounds until started")
  }

  func testRefreshesOnForegroundAfterStarting() {
    manager.startAutoRefresh()

    postWillEnterForeground()

    XCTAssertEqual(refreshCompletions.count, 1, "Should refresh when the app enters the foreground")
  }

  func testStartingTwiceObservesOnce() {
    manager.startAutoRefresh()
    manager.startAutoRefresh()

    postWillEnterForeground()

    XCTAssertEqual(refreshCompletions.count, 1, "Starting more than once should not register a second observer")
  }

  func testDoesNotRefreshOnForegroundAfterStopping() {
    manager.startAutoRefresh()
    manager.stopAutoRefresh()

    postWillEnterForeground()

    XCTAssertTrue(refreshCompletions.isEmpty, "Should stop observing foregrounds after stopping")
  }

  func testRestartingAfterStopObservesAgain() {
    manager.startAutoRefresh()
    manager.stopAutoRefresh()
    manager.startAutoRefresh()

    postWillEnterForeground()

    XCTAssertEqual(
      refreshCompletions.count,
      1,
      "Starting after a stop (for example, a new login after logout) should observe foregrounds again"
    )
  }

  // MARK: - Refresh conditions

  func testDoesNotRefreshWithoutLimitedLoginSession() {
    hasSession = false

    manager.attemptBackgroundRefresh()

    XCTAssertTrue(refreshCompletions.isEmpty, "Should not refresh without a Limited Login session")
  }

  func testDoesNotStartSecondRefreshWhileOneIsInFlight() {
    manager.attemptBackgroundRefresh()
    manager.attemptBackgroundRefresh()

    XCTAssertEqual(refreshCompletions.count, 1, "Should not start a refresh while another is in flight")
  }

  func testThrottlesRefreshWithinIntervalAfterSuccess() {
    manager.attemptBackgroundRefresh()
    refreshCompletions[0](true)

    currentDate = currentDate.addingTimeInterval(interval - 1)
    manager.attemptBackgroundRefresh()

    XCTAssertEqual(refreshCompletions.count, 1, "Should not refresh again within the interval")

    currentDate = currentDate.addingTimeInterval(2)
    manager.attemptBackgroundRefresh()

    XCTAssertEqual(refreshCompletions.count, 2, "Should refresh again once the interval has elapsed")
  }

  func testDoesNotThrottleAfterFailure() {
    manager.attemptBackgroundRefresh()
    refreshCompletions[0](false)

    manager.attemptBackgroundRefresh()

    XCTAssertEqual(refreshCompletions.count, 2, "A failed refresh should not start the interval")
  }

  // MARK: - Persistence

  func testThrottlePersistsAcrossInstances() {
    manager.attemptBackgroundRefresh()
    refreshCompletions[0](true)

    // Simulates a relaunch: a new instance reading the same store.
    let relaunchedManager = makeManager()
    currentDate = currentDate.addingTimeInterval(60)
    relaunchedManager.attemptBackgroundRefresh()

    XCTAssertEqual(
      refreshCompletions.count,
      1,
      "The time of the last refresh should survive a relaunch so the interval still applies"
    )
  }

  func testStoppingClearsPersistedRefreshTime() {
    manager.attemptBackgroundRefresh()
    refreshCompletions[0](true)

    manager.stopAutoRefresh()

    XCTAssertNil(
      dataStore.object(forKey: BackgroundRefreshManager.lastRefreshDefaultsKey),
      "Stopping (logout) should clear the persisted time of the last refresh"
    )
    manager.attemptBackgroundRefresh()
    XCTAssertEqual(refreshCompletions.count, 2, "A new session should not inherit the previous session's interval")
  }

  // MARK: - Restored sessions

  func testRestoredSessionObserverIsDiscoverableByObjectiveCName() {
    // ApplicationDelegate resolves this type by name, so the name is part of the contract.
    let observerType = NSClassFromString("FBSDKLimitedLoginRestoredSessionObserver")
      as? _RestoredAuthenticationSessionObserving.Type

    XCTAssertNotNil(observerType, "The restored-session observer should be resolvable by its Objective-C name")
  }

  func testRestoredSessionStartsAutoRefreshAndRefreshesOnce() {
    let originalManager = _LimitedLoginRestoredSessionObserver.refreshManager
    _LimitedLoginRestoredSessionObserver.refreshManager = manager
    defer { _LimitedLoginRestoredSessionObserver.refreshManager = originalManager }

    _LimitedLoginRestoredSessionObserver.didRestoreAuthenticationSession()

    XCTAssertEqual(refreshCompletions.count, 1, "Restoring a session at launch should refresh it")

    refreshCompletions[0](true)
    currentDate = currentDate.addingTimeInterval(interval + 1)
    postWillEnterForeground()

    XCTAssertEqual(refreshCompletions.count, 2, "Restoring a session at launch should also start auto-refresh")
  }
}
