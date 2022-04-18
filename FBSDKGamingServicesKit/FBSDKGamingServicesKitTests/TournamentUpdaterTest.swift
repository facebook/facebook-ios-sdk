/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit
import TestTools
import XCTest

final class TournamentUpdaterTest: XCTestCase {
  let factory = TestGraphRequestFactory()
  let score = 10
  lazy var updater = TournamentUpdater(graphRequestFactory: factory)
  lazy var tournament = Tournament(identifier: "12345", endTime: Date(), title: "test", payload: nil)

  override func setUp() {
    super.setUp()

    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "gaming")
    AccessToken.current = SampleAccessTokens.validToken
  }

  override func tearDown() {
    AuthenticationToken.current = nil
    AccessToken.current = nil

    super.tearDown()
  }

  func testDependencies() {
    XCTAssertTrue(
      TournamentUpdater().graphRequestFactory is GraphRequestFactory,
      "Should have a default GraphRequestFactory of the expected type"
    )
  }

  func testCustomDependencies() {
    XCTAssertEqual(
      updater.graphRequestFactory as? TestGraphRequestFactory,
      factory,
      "Should be able to create with a custom graph request factory"
    )
  }

  func testUpdate() throws {
    updater.update(tournament: tournament, score: score) { _ in
      XCTFail("Should not reach here")
    }

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the request to update tournaments"
    )
    XCTAssertEqual(
      factory.capturedGraphPath,
      "\(tournament.identifier)/update_score",
      "Should create a request with the expected graph path"
    )
    XCTAssertEqual(
      factory.capturedParameters as? [String: Int],
      ["score": score],
      "Should create a request with the expected parameters"
    )
  }

  func testUpdateWithoutGamingDomainAuthToken() throws {
    var completionWasInvoked = false
    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "notGaming")
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case let .failure(error):
        guard case .invalidAuthToken = error else {
          return XCTFail("Should fail with invalid auth token error but instead failed with: \(error)")
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateError() throws {
    var completionWasInvoked = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case let .failure(error):
        guard case let .server(serverError) = error else {
          return XCTFail("Should not be a decoding error")
        }

        XCTAssertTrue(serverError is SampleError)
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, nil, SampleError())

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateInvalidResult() throws {
    var completionWasInvoked = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case let .failure(error):
        guard case .decoding = error else {
          return XCTFail("Should fail with decoding error but instead failed with: \(error)")
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.invalid, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateSuccessFalse() throws {
    var completionWasInvoked = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case let .failure(error):
        guard case .decoding = error else {
          return XCTFail("Should fail with decoding error but instead failed with: \(error)")
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successFalse, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateSuccess() throws {
    var completionWasInvoked = false
    var didSucceed = false
    updater.update(tournament: tournament, score: score) { result in
      switch result {
      case let .failure(error):
        return XCTFail(
          "Expecting the request to succeed instead received: \(error)"
        )
      case .success:
        didSucceed = true
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successTrue, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertTrue(didSucceed)
  }

  // Update with Tournament ID

  func testHandlingUpdateWithInvalidTournamentID() throws {
    var completionWasInvoked = false
    updater.update(tournamentID: "", score: 1) { result in
      switch result {
      case let .failure(error):
        guard case .invalidTournamentID = error else {
          return XCTFail("Should receive invalidTournamentID error but instead received: \(error)")
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }

    XCTAssert(completionWasInvoked)
  }

  func testHandlingUpdateSuccessWithTournamentID() throws {
    var completionWasInvoked = false
    var didSucceed = false
    updater.update(tournamentID: "12345", score: score) { result in
      switch result {
      case let .failure(error):
        return XCTFail(
          "Expecting the request to succeed instead received: \(error)"
        )
      case .success:
        didSucceed = true
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successTrue, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertTrue(didSucceed)
  }

  enum TournamentUpdateGraphAPIResults {
    static let successTrue = ["success": 1]
    static let successFalse = ["success": 0]
    static let invalid = ["not_success": "value"]
  }
}
