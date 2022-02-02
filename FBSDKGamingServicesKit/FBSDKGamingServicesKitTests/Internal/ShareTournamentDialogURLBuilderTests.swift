/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import XCTest

final class ShareTournamentDialogURLBuilderTests: XCTestCase {
  let expirationDate = DateFormatter.format(ISODateString: "2021-09-24T18:03:47+0000")
  lazy var updateTournament = Tournament(
    identifier: "1234",
    payload: "Hello"
  )
  lazy var tournamentConfig = TournamentConfig(
    title: "Test",
    endTime: expirationDate,
    scoreType: .numeric,
    sortOrder: .higherIsBetter,
    payload: "Hello"
  )

  func testUpdateURL() throws {
    let expectURLComponents = try XCTUnwrap(
      URLComponents(
        string: "https://fb.gg/me/instant_tournament/12345?tournament_id=1234&payload=Hello&score=1000"
      )
    )
    let updateURL = try XCTUnwrap(
      ShareTournamentDialogURLBuilder
        .update(updateTournament)
        .url(withPathAppID: "12345", score: 1000)
    )
    let updateURLComponents = try XCTUnwrap(
      URLComponents(
        url: updateURL,
        resolvingAgainstBaseURL: false
      )
    )
    let updateURLQueryItems: [URLQueryItem] = try XCTUnwrap(updateURLComponents.queryItems)
    let expectedQueryItems: [URLQueryItem] = try XCTUnwrap(expectURLComponents.queryItems)

    XCTAssertEqual(updateURLComponents.scheme, expectURLComponents.scheme)
    XCTAssertEqual(updateURLComponents.host, expectURLComponents.host)
    XCTAssertEqual(updateURLComponents.path, expectURLComponents.path)
    XCTAssertEqual(updateURLQueryItems.count, expectedQueryItems.count, "Should contain the same number of query items")
  }

  func testCreateURL() throws {
    let expectURLComponents = try XCTUnwrap(
      URLComponents(
        string: "https://fb.gg/me/instant_tournament/12345?score=1000&end_time=1632506627&tournament_title=Test&score_format=NUMERIC&sort_order=HIGHER_IS_BETTER&tournament_payload=Hello"
      )
    )

    let updateURL = try XCTUnwrap(
      ShareTournamentDialogURLBuilder
        .create(tournamentConfig)
        .url(withPathAppID: "12345", score: 1000)
    )
    let updateURLComponents = try XCTUnwrap(
      URLComponents(
        url: updateURL,
        resolvingAgainstBaseURL: false
      )
    )
    let updateURLQueryItems: [URLQueryItem] = try XCTUnwrap(updateURLComponents.queryItems)
    let expectedQueryItems: [URLQueryItem] = try XCTUnwrap(expectURLComponents.queryItems)

    XCTAssertEqual(updateURLComponents.scheme, expectURLComponents.scheme)
    XCTAssertEqual(updateURLComponents.host, expectURLComponents.host)
    XCTAssertEqual(updateURLComponents.path, expectURLComponents.path)
    XCTAssertEqual(updateURLQueryItems.count, expectedQueryItems.count, "Should contain the same number of query items")
  }
}
