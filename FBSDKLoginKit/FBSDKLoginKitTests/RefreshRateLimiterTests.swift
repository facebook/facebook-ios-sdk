/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit
import XCTest

final class RefreshRateLimiterTests: XCTestCase {

  func testCanRefreshWhenNoRecentAttempts() {
    let rateLimiter = RefreshRateLimiter(dateProvider: { Date() })

    XCTAssertTrue(rateLimiter.canAttemptRefresh())
  }

  func testBlocksRefreshWithinMinimumInterval() {
    var currentDate = Date()
    let rateLimiter = RefreshRateLimiter(dateProvider: { currentDate })

    rateLimiter.recordAttempt()

    // 30 seconds later — should still be blocked
    currentDate = currentDate.addingTimeInterval(30)
    XCTAssertFalse(rateLimiter.canAttemptRefresh())

    // 61 seconds after the attempt — should be allowed
    currentDate = currentDate.addingTimeInterval(31)
    XCTAssertTrue(rateLimiter.canAttemptRefresh())
  }

  func testBlocksRefreshDuringFailureCooldown() {
    var currentDate = Date()
    let rateLimiter = RefreshRateLimiter(dateProvider: { currentDate })

    rateLimiter.recordAttempt()
    rateLimiter.recordFailure()

    // 2 minutes later — still within 5-minute cooldown
    currentDate = currentDate.addingTimeInterval(120)
    XCTAssertFalse(rateLimiter.canAttemptRefresh())

    // 5 minutes + 1 second after failure — should be allowed
    currentDate = currentDate.addingTimeInterval(181)
    XCTAssertTrue(rateLimiter.canAttemptRefresh())
  }

  func testBlocksRefreshWhenHourlyLimitReached() {
    var currentDate = Date()
    let rateLimiter = RefreshRateLimiter(dateProvider: { currentDate })

    // Record 10 attempts, each 61 seconds apart to clear minimum interval
    for _ in 0 ..< 10 {
      rateLimiter.recordAttempt()
      currentDate = currentDate.addingTimeInterval(61)
    }

    // 11th attempt should be blocked (10 attempts within the hour)
    XCTAssertFalse(rateLimiter.canAttemptRefresh())

    // Advance past 1 hour from the first attempt so it expires
    // First attempt was at T=0, we're currently at T=610 (10*61).
    // Need to reach T=3601 so the first attempt falls outside the 1-hour window.
    currentDate = currentDate.addingTimeInterval(2991)
    XCTAssertTrue(rateLimiter.canAttemptRefresh())
  }

  func testSuccessResetsFailureCooldown() {
    var currentDate = Date()
    let rateLimiter = RefreshRateLimiter(dateProvider: { currentDate })

    rateLimiter.recordAttempt()
    rateLimiter.recordFailure()

    // Record success — should clear the failure cooldown
    rateLimiter.recordSuccess()

    // Advance past minimum interval only
    currentDate = currentDate.addingTimeInterval(61)
    XCTAssertTrue(rateLimiter.canAttemptRefresh())
  }

  func testResetClearsAllState() {
    let currentDate = Date()
    let rateLimiter = RefreshRateLimiter(dateProvider: { currentDate })

    // Accumulate state: attempts + failure
    rateLimiter.recordAttempt()
    rateLimiter.recordFailure()

    // Should be blocked right now
    XCTAssertFalse(rateLimiter.canAttemptRefresh())

    // Reset clears everything
    rateLimiter.reset()
    XCTAssertTrue(rateLimiter.canAttemptRefresh())
  }

  func testTimeUntilNextAllowedAttempt() {
    var currentDate = Date()
    let rateLimiter = RefreshRateLimiter(dateProvider: { currentDate })

    rateLimiter.recordAttempt()

    // Immediately after attempt, should report ~60 seconds remaining
    let waitTime = rateLimiter.timeUntilNextAllowedAttempt()
    XCTAssertEqual(waitTime, 60, accuracy: 1.0)

    // Advance 30 seconds — should report ~30 seconds remaining
    currentDate = currentDate.addingTimeInterval(30)
    let waitTimeAfter30s = rateLimiter.timeUntilNextAllowedAttempt()
    XCTAssertEqual(waitTimeAfter30s, 30, accuracy: 1.0)

    // Advance past the interval — should return 0
    currentDate = currentDate.addingTimeInterval(31)
    XCTAssertEqual(rateLimiter.timeUntilNextAllowedAttempt(), 0, accuracy: 0.01)
  }

  func testThreadSafety() {
    let rateLimiter = RefreshRateLimiter(dateProvider: { Date() })
    let concurrentQueue = DispatchQueue(label: "test.concurrency", attributes: .concurrent)
    let group = DispatchGroup()

    for _ in 0 ..< 100 {
      group.enter()
      concurrentQueue.async {
        _ = rateLimiter.canAttemptRefresh()
        rateLimiter.recordAttempt()
        group.leave()
      }
    }

    let expectation = expectation(description: "All concurrent operations complete without crashing")
    group.notify(queue: .main) {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)
  }
}
