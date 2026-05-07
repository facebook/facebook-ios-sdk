/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit
import XCTest

final class RefreshRetryHandlerTests: XCTestCase {

  private var handler: RefreshRetryHandler!

  override func setUp() {
    super.setUp()
    handler = RefreshRetryHandler()
  }

  override func tearDown() {
    handler = nil
    super.tearDown()
  }

  private static func makeTestProfile(userID: String = "123") -> Profile {
    Profile(
      userID: userID,
      firstName: nil,
      middleName: nil,
      lastName: nil,
      name: "Test User",
      linkURL: nil,
      refreshDate: nil
    )
  }

  // MARK: - Success

  func testNoRetryOnSuccess() {
    let expectation = expectation(description: "Completion called")
    var operationCallCount = 0

    let profile = Self.makeTestProfile()

    handler.executeWithRetry(
      operation: { completion in
        operationCallCount += 1
        completion(.success(profile))
      },
      completion: { result in
        switch result {
        case let .success(returnedProfile):
          XCTAssertEqual(returnedProfile.userID, "123")
        case .failure:
          XCTFail("Expected success")
        }
        XCTAssertEqual(operationCallCount, 1)
        expectation.fulfill()
      }
    )

    wait(for: [expectation], timeout: 5.0)
  }

  // MARK: - Retryable Errors

  func testRetryOnNetworkError() {
    let expectation = expectation(description: "Completion called")
    var operationCallCount = 0

    let profile = Self.makeTestProfile()

    handler.executeWithRetry(
      operation: { completion in
        operationCallCount += 1
        if operationCallCount == 1 {
          completion(.failure(.networkError))
        } else {
          completion(.success(profile))
        }
      },
      completion: { result in
        switch result {
        case let .success(returnedProfile):
          XCTAssertEqual(returnedProfile.userID, "123")
        case .failure:
          XCTFail("Expected success after retry")
        }
        XCTAssertEqual(operationCallCount, 2)
        expectation.fulfill()
      }
    )

    wait(for: [expectation], timeout: 10.0)
  }

  func testRetryOnTimeout() {
    let expectation = expectation(description: "Completion called")
    var operationCallCount = 0

    let profile = Self.makeTestProfile(userID: "456")

    handler.executeWithRetry(
      operation: { completion in
        operationCallCount += 1
        if operationCallCount == 1 {
          completion(.failure(.timeout))
        } else {
          completion(.success(profile))
        }
      },
      completion: { result in
        switch result {
        case let .success(returnedProfile):
          XCTAssertEqual(returnedProfile.userID, "456")
        case .failure:
          XCTFail("Expected success after retry")
        }
        XCTAssertEqual(operationCallCount, 2)
        expectation.fulfill()
      }
    )

    wait(for: [expectation], timeout: 10.0)
  }

  // MARK: - Non-Retryable Errors

  func testNoRetryOnLoginRequired() {
    let expectation = expectation(description: "Completion called")
    var operationCallCount = 0

    handler.executeWithRetry(
      operation: { completion in
        operationCallCount += 1
        completion(.failure(.loginRequired))
      },
      completion: { result in
        switch result {
        case .success:
          XCTFail("Expected failure")
        case let .failure(error):
          XCTAssertEqual(error, .loginRequired)
        }
        XCTAssertEqual(operationCallCount, 1)
        expectation.fulfill()
      }
    )

    wait(for: [expectation], timeout: 5.0)
  }

  func testNoRetryOnUserMismatch() {
    let expectation = expectation(description: "Completion called")
    var operationCallCount = 0

    handler.executeWithRetry(
      operation: { completion in
        operationCallCount += 1
        completion(.failure(.userMismatch))
      },
      completion: { result in
        switch result {
        case .success:
          XCTFail("Expected failure")
        case let .failure(error):
          XCTAssertEqual(error, .userMismatch)
        }
        XCTAssertEqual(operationCallCount, 1)
        expectation.fulfill()
      }
    )

    wait(for: [expectation], timeout: 5.0)
  }

  // MARK: - Max Retries

  func testMaxRetriesRespected() {
    let expectation = expectation(description: "Completion called")
    var operationCallCount = 0

    handler.executeWithRetry(
      operation: { completion in
        operationCallCount += 1
        completion(.failure(.networkError))
      },
      completion: { result in
        switch result {
        case .success:
          XCTFail("Expected failure after max retries")
        case let .failure(error):
          XCTAssertEqual(error, .networkError)
        }
        XCTAssertEqual(operationCallCount, RetryConfig.maxRetries)
        expectation.fulfill()
      }
    )

    wait(for: [expectation], timeout: 30.0)
  }

  // MARK: - Delay Calculation

  func testExponentialDelayCalculation() {
    let tolerance = 0.2 // 20% jitter tolerance

    let delay1 = RetryConfig.delay(forAttempt: 1)
    XCTAssertGreaterThanOrEqual(delay1, 1.0 * (1.0 - tolerance))
    XCTAssertLessThanOrEqual(delay1, 1.0 * (1.0 + tolerance))

    let delay2 = RetryConfig.delay(forAttempt: 2)
    XCTAssertGreaterThanOrEqual(delay2, 2.0 * (1.0 - tolerance))
    XCTAssertLessThanOrEqual(delay2, 2.0 * (1.0 + tolerance))

    let delay3 = RetryConfig.delay(forAttempt: 3)
    XCTAssertGreaterThanOrEqual(delay3, 4.0 * (1.0 - tolerance))
    XCTAssertLessThanOrEqual(delay3, 4.0 * (1.0 + tolerance))
  }

  func testJitterApplied() {
    let sampleCount = 100
    var delays = Set<TimeInterval>()

    for _ in 0 ..< sampleCount {
      delays.insert(RetryConfig.delay(forAttempt: 1))
    }

    XCTAssertGreaterThan(delays.count, 1, "Jitter should produce varying delay values")
  }
}
