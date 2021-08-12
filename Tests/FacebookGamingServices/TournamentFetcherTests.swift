// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@testable import FacebookGamingServices

#if FBSDK_SWIFT_PACKAGE
import FacebookCore
#else
import FBSDKCoreKit
#endif

import TestTools
import XCTest

struct SampleError: Error {}

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
    static let date = Date()
    static let tournamentID = "4227416214015447"
    static let tournamentEndTime = "\(date.timeIntervalSince1970)"
    static let tournamentTitle = "test title"
    static let tournamentPayload = "test payload"
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
      "me",
      "Should create a request with the expected graph path"
    )
    XCTAssertEqual(
      factory.capturedParameters as? [String: String],
      ["fields": "tournaments"],
      "Should create a request with the expected parameters"
    )
  }

  func testHandlingTournamentFetchError() throws {
    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
      switch result {
      case .failure(let error):
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

  func testHandlingTournamentFetchResultAndError() throws {
    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
      switch result {
      case .failure(let error):
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
      case .failure(let error):
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
    let expectedTournament = Tournament(
      identifier: Values.tournamentID,
      expiration: Values.date,
      title: Values.tournamentTitle,
      payload: Values.tournamentPayload
    )

    var completionWasInvoked = false
    fetcher.fetchTournaments { result in
      switch result {
      case .failure(let error):
        XCTFail("Unexpected error received: \(error)")
      case .success(let tournament):
        XCTAssertEqual(tournament.identifier, expectedTournament.identifier)
        XCTAssertEqual(
          tournament.expiration.timeIntervalSince1970,
          expectedTournament.expiration.timeIntervalSince1970,
          accuracy: 100
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
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentID: Values.tournamentID
    ]

    static let validFull = [
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentEndTime: Values.tournamentEndTime,
      Keys.tournamentID: Values.tournamentID,
      Keys.tournamentPayload: Values.tournamentPayload
    ]

    static let missingIdentifier = [
      Keys.tournamentTitle: Values.tournamentTitle,
      Keys.tournamentEndTime: Values.tournamentEndTime
    ]
  }
}
