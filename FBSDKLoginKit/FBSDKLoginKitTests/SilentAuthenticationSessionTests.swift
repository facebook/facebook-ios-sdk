/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit
import AuthenticationServices
import XCTest

// MARK: - Mock

@available(iOS 13.0, *)
final class MockAuthenticationSession: SilentAuthSessionProviding {
  var startHandler: (() -> Bool)?
  var cancelHandler: (() -> Void)?
  var completionHandler: SilentAuthCompletionHandler?
  var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
  private(set) var startCalled = false
  private(set) var cancelCalled = false

  required init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping SilentAuthCompletionHandler
  ) {
    self.completionHandler = completionHandler
  }

  func start() -> Bool {
    startCalled = true
    return startHandler?() ?? true
  }

  func cancel() {
    cancelCalled = true
    cancelHandler?()
  }
}

// MARK: - Tests

@available(iOS 13.0, *)
final class SilentAuthenticationSessionTests: XCTestCase {

  private let testURL = URL(string: "https://limited.facebook.com/v18.0/dialog/oauth")!
  private let callbackScheme = "fb123456789"
  private let successURL = URL(string: "fb123456789://authorize#id_token=abc123")!
  private var capturedSession: MockAuthenticationSession?

  private func makeSUT(startReturns: Bool = true) -> SilentAuthenticationSession {
    SilentAuthenticationSession { url, scheme, handler in
      let mock = MockAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: handler)
      mock.startHandler = { startReturns }
      self.capturedSession = mock
      return mock
    }
  }

  // MARK: - Success

  func testSuccessWithinTimeout() {
    let sut = makeSUT()
    let completionExpectation = expectation(description: "Completion called with success URL")

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { result in
      switch result {
      case let .success(url):
        XCTAssertEqual(url, self.successURL)
      case let .failure(error):
        XCTFail("Expected success but got error: \(error)")
      }
      completionExpectation.fulfill()
    }

    capturedSession?.completionHandler?(successURL, nil)
    wait(for: [completionExpectation], timeout: 2.0)
  }

  // MARK: - Timeout

  func testTimeoutReturnsTimeoutError() {
    let sut = makeSUT()
    let completionExpectation = expectation(description: "Completion called with timeout error")

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { result in
      switch result {
      case .success:
        XCTFail("Expected timeout error but got success")
      case let .failure(error):
        XCTAssertEqual(error, .timeout)
      }
      completionExpectation.fulfill()
    }

    // Do not trigger the mock callback — let the internal 30-second timeout fire
    wait(for: [completionExpectation], timeout: 35.0)
  }

  func testTimeoutCancelsSession() {
    let sut = makeSUT()
    let completionExpectation = expectation(description: "Timeout fires and cancels the underlying session")

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { _ in
      completionExpectation.fulfill()
    }

    // Wait for the 30-second internal timeout to fire
    wait(for: [completionExpectation], timeout: 35.0)
    XCTAssertTrue(capturedSession?.cancelCalled ?? false, "Timeout should cancel the underlying auth session")
  }

  // MARK: - Timer Cancellation

  func testTimeoutTimerCancelledOnSuccess() {
    let sut = makeSUT()
    let completionExpectation = expectation(description: "Completion called once")
    let noSecondCall = expectation(description: "No spurious second completion call")
    noSecondCall.isInverted = true
    var completionCount = 0

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { _ in
      completionCount += 1
      if completionCount == 1 {
        completionExpectation.fulfill()
      } else {
        noSecondCall.fulfill()
      }
    }

    capturedSession?.completionHandler?(successURL, nil)
    wait(for: [completionExpectation], timeout: 2.0)
    wait(for: [noSecondCall], timeout: 1.0)
    XCTAssertEqual(completionCount, 1, "Completion should be called exactly once after success")
  }

  func testTimeoutTimerCancelledOnFailure() {
    let sut = makeSUT()
    let completionExpectation = expectation(description: "Completion called once")
    let noSecondCall = expectation(description: "No spurious second completion call")
    noSecondCall.isInverted = true
    var completionCount = 0
    let sessionError = NSError(domain: "TestError", code: -1, userInfo: nil)

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { _ in
      completionCount += 1
      if completionCount == 1 {
        completionExpectation.fulfill()
      } else {
        noSecondCall.fulfill()
      }
    }

    capturedSession?.completionHandler?(nil, sessionError)
    wait(for: [completionExpectation], timeout: 2.0)
    wait(for: [noSecondCall], timeout: 1.0)
    XCTAssertEqual(completionCount, 1, "Completion should be called exactly once after failure")
  }

  // MARK: - Cancel

  func testManualCancelCleansUp() {
    let sut = makeSUT()
    let completionExpectation = expectation(description: "Completion called with cancelled error")

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { result in
      switch result {
      case .success:
        XCTFail("Expected cancelled error but got success")
      case let .failure(error):
        XCTAssertEqual(error, .cancelled)
      }
      completionExpectation.fulfill()
    }

    sut.cancel()

    XCTAssertTrue(capturedSession?.cancelCalled ?? false, "Cancel should forward to the underlying session")
    wait(for: [completionExpectation], timeout: 2.0)
  }

  // MARK: - Start Failure

  func testSessionStartFailureReturnsNetworkError() {
    let sut = makeSUT(startReturns: false)
    let completionExpectation = expectation(description: "Completion called with network error")

    sut.start(url: testURL, callbackURLScheme: callbackScheme) { result in
      switch result {
      case .success:
        XCTFail("Expected network error but got success")
      case let .failure(error):
        XCTAssertEqual(error, .networkError)
      }
      completionExpectation.fulfill()
    }

    wait(for: [completionExpectation], timeout: 2.0)
  }
}
