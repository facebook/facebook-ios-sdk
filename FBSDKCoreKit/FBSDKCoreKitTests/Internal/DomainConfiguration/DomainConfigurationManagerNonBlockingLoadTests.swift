/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import TestTools
import XCTest

// Tests for the domain-configuration load path: `loadDomainConfiguration` completes from
// cached/default config without blocking on the network, and refreshes from the network
// off the main thread.
//
// Sections:
//   - Non-blocking completion: the completion fires from cache/default and is not gated on
//     the network response.
//   - Background refresh: the network request is still made, started off the main thread.
//   - Invariants: routing stays correct/ATT-safe while a fetch is pending, a valid cache
//     fast-paths without re-fetching, and overlapping loads never start duplicate requests.
//
// The completion fires via dispatch to the main queue, so tests use expectations and let the
// main run loop turn. `TestGraphRequestConnection(shouldExecuteCompletion: false)` simulates a
// slow/hung network so we can assert completion is independent of it.

final class DomainConfigurationManagerNonBlockingLoadTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var requestFactory: TestGraphRequestFactory!
  var connectionFactory: TestGraphRequestConnectionFactory!
  var manager: _DomainConfigurationManager!
  var settings: TestSettings!
  var dataStore: DataPersisting!
  // swiftlint:enable implicitly_unwrapped_optional

  let serverResult: [String: Any] = [
    "data": [[
      "endpoints": [
        ["key": "activities", "value": [
          "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
          "att_opt_out_domain_prefix": kEndpoint2URLPrefix,
        ]],
        ["key": "default_config", "value": [
          "default_domain_prefix": kEndpoint2URLPrefix,
          "default_alternative_domain_prefix": kEndpoint1URLPrefix,
          "enable_for_early_versions": false,
        ]],
      ],
    ]],
  ]

  override func setUp() {
    super.setUp()
    requestFactory = TestGraphRequestFactory()
    settings = TestSettings()
    settings.appID = "1234567890"
    dataStore = UserDefaultsSpy()
    manager = _DomainConfigurationManager.sharedInstance()
    manager.reset()
    _DomainConfiguration.setDefaultDomainInfo()
  }

  override func tearDown() {
    _DomainConfigurationManager.sharedInstance().reset()
    _DomainConfiguration.resetDefaultDomainInfo()
    connectionFactory = nil
    requestFactory = nil
    settings = nil
    dataStore = nil
    manager = nil
    super.tearDown()
  }

  private func configure(with connection: GraphRequestConnecting) {
    connectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: connection)
    manager.configure(
      settings: settings,
      dataStore: dataStore,
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
    )
  }

  // MARK: - Non-blocking completion (cache / default)

  func testCompletionFiresEvenWhenNetworkNeverResponds() {
    // Connection that never invokes its completion — simulates a slow/hung network.
    let hung = TestGraphRequestConnection(
      shouldExecuteCompletion: false,
      error: nil,
      requestConnectionResult: nil
    )
    configure(with: hung)

    let completed = expectation(description: "completion fires from cache, not gated on the network")
    manager.loadDomainConfiguration {
      completed.fulfill()
    }
    waitForExpectations(timeout: 1.0)
  }

  func testRequestStartIsDispatchedOffTheMainThread() {
    // The expensive request build+start must run off the main thread, not synchronously in the
    // caller's launch frame. Assert on the thread the request actually started on rather than on
    // timing (a synchronous `startCallCount == 0` check races the background dispatch).
    let connection = TestGraphRequestConnection(
      shouldExecuteCompletion: true,
      error: nil,
      requestConnectionResult: serverResult
    )
    configure(with: connection)

    manager.loadDomainConfiguration {}
    let started = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in connection.startCallCount == 1 },
      object: nil
    )
    wait(for: [started], timeout: 5.0)
    XCTAssertEqual(
      connection.startCalledOnMainThread, false,
      "The network request must be started off the main thread, not in the caller's launch frame"
    )
  }

  // MARK: - Background refresh (off the main thread)

  func testNetworkRefreshStillStartsInBackground() {
    let connection = TestGraphRequestConnection(
      shouldExecuteCompletion: true,
      error: nil,
      requestConnectionResult: serverResult
    )
    configure(with: connection)

    manager.loadDomainConfiguration {}
    let started = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in connection.startCallCount == 1 },
      object: nil
    )
    wait(for: [started], timeout: 5.0)
  }

  func testConfigIsRefreshedAfterBackgroundResponse() {
    let connection = TestGraphRequestConnection(
      shouldExecuteCompletion: true,
      error: nil,
      requestConnectionResult: serverResult
    )
    configure(with: connection)

    manager.loadDomainConfiguration {}
    let refreshed = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        _DomainConfigurationManager.sharedInstance().domainConfiguration != nil
      },
      object: nil
    )
    wait(for: [refreshed], timeout: 5.0)
    XCTAssertNotNil(
      manager.domainConfiguration,
      "The background refresh should populate the fetched domain configuration"
    )
  }

  // MARK: - Invariant: routing stays correct + ATT-safe while a fetch is pending

  func testRoutingUsesDefaultConfigBeforeAnyNetworkResponse() {
    let hung = TestGraphRequestConnection(
      shouldExecuteCompletion: false,
      error: nil,
      requestConnectionResult: nil
    )
    configure(with: hung)

    guard let cached = manager.cachedDomainConfiguration().domainInfo,
          let defaultInfo = _DomainConfiguration.default().domainInfo else {
      return XCTFail("cached and default domain info should be non-nil")
    }
    XCTAssertTrue(
      NSDictionary(dictionary: cached).isEqual(to: defaultInfo),
      "Routing must fall back to the ATT-safe default config while the fetch is pending"
    )
  }

  // MARK: - Invariant: a valid cache fast-paths without re-fetching

  func testValidCacheDoesNotTriggerASecondFetch() {
    let connection = TestGraphRequestConnection(
      shouldExecuteCompletion: true,
      error: nil,
      requestConnectionResult: serverResult
    )
    configure(with: connection)

    manager.loadDomainConfiguration {}
    let firstStart = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in connection.startCallCount == 1 },
      object: nil
    )
    wait(for: [firstStart], timeout: 5.0)

    let secondCompleted = expectation(description: "second load completes from the fresh cache")
    manager.loadDomainConfiguration { secondCompleted.fulfill() }
    waitForExpectations(timeout: 1.0)
    XCTAssertEqual(
      connection.startCallCount, 1,
      "A valid, fresh cached config must fast-path without a second network request"
    )
  }

  // MARK: - Invariant: overlapping loads never start duplicate requests

  func testConcurrentLoadsStartAtMostOneRequest() {
    let connection = TestGraphRequestConnection(
      shouldExecuteCompletion: false,
      error: nil,
      requestConnectionResult: nil
    )
    configure(with: connection)

    manager.loadDomainConfiguration {}
    manager.loadDomainConfiguration {}
    let started = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in connection.startCallCount >= 1 },
      object: nil
    )
    wait(for: [started], timeout: 5.0)
    XCTAssertEqual(
      connection.startCallCount, 1,
      "Overlapping loads while a fetch is in flight must not start duplicate requests"
    )
  }

  // MARK: - Concurrency: main-thread routing must not stall on the background refresh

  //
  // The manager guards its state with @synchronized(self); request routing on the main thread
  // reads it via cachedDomainConfiguration(). Starting the refresh off the main thread must not
  // let the background path hold that lock long enough to stall a main-thread routing read
  // (lock contention / priority inversion). This test guards against a hang/deadlock and gross
  // contention. The true main-thread *stall magnitude* needs Instruments/device — and the
  // implementation must keep @synchronized OFF the network start and OFF the config archive +
  // UserDefaults write so those never block a routing read.

  func testCachedConfigStaysResponsiveWhileRefreshInFlight() {
    // A refresh is kicked off but never completes (in flight for the whole test).
    let hung = TestGraphRequestConnection(
      shouldExecuteCompletion: false,
      error: nil,
      requestConnectionResult: nil
    )
    configure(with: hung)
    manager.loadDomainConfiguration {}

    // Hammer routing reads from a background queue while the main thread also reads, to surface
    // any lock contention or deadlock. Every read must return the ATT-safe default promptly.
    let done = expectation(description: "routing reads complete without stalling")
    DispatchQueue.global(qos: .userInitiated).async { [self] in
      for _ in 0 ..< 50 {
        XCTAssertNotNil(manager.cachedDomainConfiguration().domainInfo)
      }
      done.fulfill()
    }
    for _ in 0 ..< 50 {
      XCTAssertNotNil(manager.cachedDomainConfiguration().domainInfo)
    }
    waitForExpectations(timeout: 2.0)
  }
}

// MARK: - Skeleton: ApplicationDelegate-level ordering / early-signal usability

//
// Belongs in the ApplicationDelegate test target (needs the full CoreKitComponents doubles).
// These assert that an earlier domain-config completion still leaves the SDK correct on first
// use (no dropped early work) — outline only, to be fleshed out alongside the change:
//
//   func testEventLoggedBeforeSDKReadyIsNotDropped() {
//     // Given a token seeded in the token cache and a hung domain-config connection,
//     // when AppEvents.logEvent is called during init and later flushed,
//     // then the event is present in the flushed batch with the correct (user vs client) token.
//   }
//
//   func testRequestMadeBeforeSDKReadyFlushesWithCorrectRouting() {
//     // A graph request issued during init is queued, then flushed once the domain-config
//     // completion opens the gate, routed on cached/default domains.
//   }
//
//   func testAccessTokenAndProfileStillPopulatedAtInit() {
//     // Regression: token/profile eager population is unchanged, so AccessToken.current /
//     // Profile.current are set as before and their change notifications still fire at init.
//   }
