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

class ShareTournamentDialogURLBuilderTests: XCTestCase {
  let expirationDate = Date()
  lazy var updateTournament = Tournament(
    identifier: "1234",
    payload: "Hello"
  )

  override func setUp() {
    super.setUp()

    try? updateTournament.update(score: NumericScore(value: 1000))
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
      URLQueryItem(
        name: "score",
        value: "1000"
      ),
      URLQueryItem(
        name: "tournament_id",
        value: "1234"
      ),
      URLQueryItem(
        name: "tournament_payload",
        value: "Hello"
      ),
    ]

    for item in queryItems {
      if !expectedQueryItems.contains(item) {
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
}
