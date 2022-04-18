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

final class _TournamentUpdaterTests: XCTestCase {
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

  func testWrapperHandlingUpdateSuccess() throws {
    var completionWasInvoked = false
    var didSucceed = false
    let nsobject = _FBSDKTournament(tournament: tournament)
    _TournamentUpdater(graphRequestFactory: factory).update(tournament: nsobject, score: score) { success, error in
      if let error = error {
        return XCTFail("Expecting the request to succeed instead received: \(error)")
      }
      didSucceed = success
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successTrue, nil)

    XCTAssert(completionWasInvoked)
    XCTAssertTrue(didSucceed)
  }

  func testWrapperHandlingUpdateWithInvalidTournamentID() throws {
    var completionWasInvoked = false
    _TournamentUpdater(graphRequestFactory: factory).update(tournamentID: "", score: 1) { success, error in
      if success {
        return XCTFail("Should not succeed")
      }
      guard case .invalidTournamentID = error as? TournamentUpdaterError else {
        return XCTFail("Should receive invalidTournamentID error but instead received: \(error as Any)")
      }
      completionWasInvoked = true
    }

    XCTAssert(completionWasInvoked)
  }

  func testWrapperHandlingUpdateSuccessFalse() throws {
    var completionWasInvoked = false
    let nsobject = _FBSDKTournament(tournament: tournament)
    _TournamentUpdater(graphRequestFactory: factory).update(tournament: nsobject, score: score) { success, error in
      if success {
        return XCTFail("Should not succeed")
      }
      guard case .decoding = error as? TournamentUpdaterError else {
        return XCTFail("Should fail with decoding error but instead failed with: \(error as Any)")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, TournamentUpdateGraphAPIResults.successFalse, nil)

    XCTAssert(completionWasInvoked)
  }

  func testWrapperHandlingUpdateSuccessWithTournamentID() throws {
    var completionWasInvoked = false
    var didSucceed = false
    _TournamentUpdater(graphRequestFactory: factory).update(tournamentID: "12345", score: score) { success, error in
      if let error = error {
        return XCTFail("Expecting the request to succeed instead received: \(error)")
      }
      didSucceed = success
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
