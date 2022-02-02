/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import TestTools
import XCTest

class TournamentFetcherTests: XCTestCase {

  let factory = TestGraphRequestFactory()
  lazy var fetcher = TournamentFetcher(graphRequestFactory: factory)

  enum Keys {
    static let tournamentID = "id"
    static let tournamentEndTime = "tournament_end_time"
    static let tournamentTitle = "tournament_title"
    static let tournamentPayload = "tournament_payload"
  }

  enum Values {
    static let date = DateFormatter.format(ISODateString: "2021-09-24T18:03:47+0000")
    static let tournamentID = "4227416214015447"
    static let tournamentEndTime = "2021-09-24T18:03:47+0000"
    static let tournamentTitle = "test title"
    static let tournamentPayload = "test payload"
  }

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
    let fetcher = TournamentFetcher()
    XCTAssertTrue(
      fetcher.graphRequestFactory is GraphRequestFactory,
      "Should have a default GraphRequestFactory of the expected type"
    )
  }

  func testCustomDependencies() {
    XCTAssertEqual(
      fetcher.graphRequestFactory as? TestGraphRequestFactory,
      factory,
      "Should be able to create with a custom graph request factory"
    )
  }

  func testFetchTournaments() throws {
    fetcher.fetchTournaments { _ in
      XCTFail("Should not reach here")
    }

    let request = try XCTUnwrap(factory.capturedRequests.first)

    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the request to fetch tournaments"
    )
    XCTAssertEqual(
      factory.capturedGraphPath,
      "user123/tournaments",
      "Should create a request with the expected graph path"
    )
    XCTAssertEqual(
      factory.capturedParameters as? [String: String],
      [:],
      "Should create a request with the expected parameters"
    )
  }

  func testFetchTournamentsAuthTokenWithInvalidGraphDomain() throws {
    var completionWasInvoked = false

    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "notGaming")
    fetcher.fetchTournaments { result in
      switch result {
      case let .failure(error):
        guard case .invalidAuthToken = error else {
          return XCTFail("Was expecting invalid auth token error, instead recieved:\(error)")
        }

      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }

    XCTAssert(completionWasInvoked)
  }

  func testFetchTournamentsWithoutAccessToken() throws {
    var completionWasInvoked = false

    AccessToken.current = nil
    fetcher.fetchTournaments { result in
      switch result {
      case let .failure(error):
        guard case .invalidAccessToken = error else {
          return XCTFail("Was expecting invalid access token error, instead recieved:\(error)")
        }

      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }

    XCTAssert(completionWasInvoked)
  }

  func testHandlingTournamentFetchError() throws {
    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
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

  func testHandlingTournamentFetchInvalidGraphResponse() throws {
    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
      switch result {
      case let .failure(error):
        guard case .decoding = error else {
          return XCTFail(
            "An graph response should complete with a decoding error, instead received: \(error)"
          )
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleTournamentResults.invalidGraphAPIResponse, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingTournamentFetchResultAndError() throws {
    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
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

    completion(nil, SampleTournamentResults.validPartial, SampleError())

    XCTAssert(completionWasInvoked)
  }

  func testHandlingTournamentFetchInvalidResult() throws {
    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
      switch result {
      case let .failure(error):
        guard case .decoding = error else {
          return XCTFail(
            "An invalid result should complete with a decoding error, instead received: \(error)"
          )
        }
      case .success:
        XCTFail("Should not succeed")
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleTournamentResults.missingIdentifier, nil)

    XCTAssert(completionWasInvoked)
  }

  func testHandlingTournamentFetchValidResult() throws {
    let date = try XCTUnwrap(Values.date)
    let expectedTournament = Tournament(
      identifier: Values.tournamentID,
      endTime: date,
      title: Values.tournamentTitle,
      payload: Values.tournamentPayload
    )

    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
      switch result {
      case let .failure(error):
        XCTFail("Unexpected error received: \(error)")
      case let .success(tournaments):
        guard let tournament = tournaments.first else {
          return XCTFail("Tournaments array was empty")
        }
        guard let expiration = tournament.endTime?.timeIntervalSince1970 else {
          return XCTFail("Tournament missing expiration")
        }

        XCTAssertEqual(tournament.identifier, expectedTournament.identifier)
        XCTAssertEqual(
          expiration,
          date.timeIntervalSince1970
        )
        XCTAssertEqual(tournament.title, expectedTournament.title)
        XCTAssertEqual(tournament.payload, expectedTournament.payload)
      }
      completionWasInvoked = true
    }
    let completion = try XCTUnwrap(factory.capturedRequests.first?.capturedCompletionHandler)

    completion(nil, SampleTournamentResults.validFull, nil)

    XCTAssert(completionWasInvoked)
  }

  enum SampleTournamentResults {

    static let validPartial = [
      "data": [
        [
          Keys.tournamentTitle: Values.tournamentTitle,
          Keys.tournamentEndTime: Values.tournamentEndTime,
          Keys.tournamentID: Values.tournamentID
        ]
      ]
    ]

    static let validFull = [
      "data": [
        [
          Keys.tournamentTitle: Values.tournamentTitle,
          Keys.tournamentEndTime: Values.tournamentEndTime,
          Keys.tournamentID: Values.tournamentID,
          Keys.tournamentPayload: Values.tournamentPayload
        ]
      ]
    ]

    static let missingIdentifier = [
      "data": [
        [
          Keys.tournamentTitle: Values.tournamentTitle,
          Keys.tournamentEndTime: Values.tournamentEndTime
        ]
      ]
    ]

    static let invalidGraphAPIResponse = ["not_data": []]
  }
}
