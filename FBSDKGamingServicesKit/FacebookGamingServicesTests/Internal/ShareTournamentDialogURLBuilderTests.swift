/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices

class ShareTournamentDialogURLBuilderTests: XCTestCase {
  let expirationDate = DateFormatter.format(ISODateString: "2021-09-24T18:03:47+0000")
  lazy var updateTournament = Tournament(
    identifier: "1234",
    payload: "Hello"
  )
  lazy var createTournament = Tournament(
    title: "Test",
    expiration: expirationDate,
    sortOrder: .descending,
    payload: "Hello"
  )

  override func setUp() {
    super.setUp()

    try? updateTournament.update(score: NumericScore(value: 1000))
    try? createTournament.update(score: NumericScore(value: 1000))
  }

  func testUpdateQueryItemsWithoutScore() throws {
    let tournamentWithoutScore = Tournament(
      identifier: "1234",
      payload: "Hello"
    )
    let queryItems = ShareTournamentDialogURLBuilder.update(tournamentWithoutScore).queryItems
    XCTAssertEqual(queryItems, [])
  }

  func testUpdateQueryItems() throws {
    try updateTournament.update(score: NumericScore(value: 1000))
    let queryItems = ShareTournamentDialogURLBuilder.update(updateTournament).queryItems
    let expectedQueryItems = [
      "score": "1000",
      "tournament_id": "1234",
      "tournament_payload": "Hello"
    ].map { key, value in
      URLQueryItem(name: key, value: value)
    }

    for item in expectedQueryItems {
      if !queryItems.contains(item) {
        XCTFail("Missing query item \(item)")
      }
    }
  }

  func testUpdateURL() throws {
    try updateTournament.update(score: NumericScore(value: 1000))
    let expectedURL = try XCTUnwrap(
      URL(
        string: "https://fb.gg/me/instant_tournament/12345?tournament_id=1234&tournament_payload=Hello&score=1000"
      )
    )
    let updateURL = try XCTUnwrap(ShareTournamentDialogURLBuilder.update(updateTournament).url(withPathAppID: "12345"))

    XCTAssertEqual(updateURL.scheme, expectedURL.scheme)
    XCTAssertEqual(updateURL.host, expectedURL.host)
    XCTAssertEqual(updateURL.path, expectedURL.path)
    XCTAssertNotNil(updateURL.query)
  }

  func testCreateQueryItemsWithoutScore() throws {
    let tournamentWithoutScore = Tournament(
      title: "Test",
      expiration: expirationDate,
      sortOrder: .descending,
      payload: "Hello"
    )
    let queryItems = ShareTournamentDialogURLBuilder.create(tournamentWithoutScore).queryItems
    XCTAssertEqual(queryItems, [])
  }

  func testCreateQueryItems() {
    let queryItems = ShareTournamentDialogURLBuilder.create(createTournament).queryItems
    let expectedQueryItems = [
      "score": "1000",
      "end_time": "1632506627",
      "tournament_title": "Test",
      "score_format": "NUMERIC",
      "sort_order": "HIGHER_IS_BETTER",
      "tournament_payload": "Hello"
    ].map { key, value in
      URLQueryItem(name: key, value: value)
    }

    for item in expectedQueryItems {
      if !queryItems.contains(item) {
        XCTFail("Missing query item \(item)")
      }
    }
  }

  func testCreateURL() throws {
    let expectedURL = try XCTUnwrap(URL(
      string: "https://fb.gg/me/instant_tournament/12345?score=1000&end_time=1632506627.0&tournament_title=Test&score_format=NUMERIC&sort_order=HIGHER_IS_BETTER&tournament_payload=Hello" // swiftlint:disable:this line_length
    ))

    let updateURL = try XCTUnwrap(ShareTournamentDialogURLBuilder.create(createTournament).url(withPathAppID: "12345"))

    XCTAssertEqual(updateURL.scheme, expectedURL.scheme)
    XCTAssertEqual(updateURL.host, expectedURL.host)
    XCTAssertEqual(updateURL.path, expectedURL.path)
    XCTAssertNotNil(updateURL.query)
  }
}
