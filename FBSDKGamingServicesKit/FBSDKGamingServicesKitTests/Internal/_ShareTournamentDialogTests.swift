/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import TestTools
import XCTest

final class _ShareTournamentDialogTests: XCTestCase, _ShareTournamentDialogDelegate {
  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: ShareTournamentDialogError?

  let bridgeOpener = TestBridgeAPIRequestOpener()
  let expirationDate = DateFormatter.format(ISODateString: "2021-09-24T18:03:47+0000")
  lazy var validTournamentForUpdate = Tournament(
    identifier: "1234",
    endTime: expirationDate
  )
  lazy var tournamentConfig = _TournamentConfig(
    title: "test",
    endTime: expirationDate,
    scoreType: .numeric,
    sortOrder: .higherIsBetter,
    payload: "test"
  )

  lazy var shareDialogWrapper = _ShareTournamentDialog(
    delegate: self,
    urlOpener: bridgeOpener
  )

  override func setUp() {
    super.setUp()

    dialogDidCompleteSuccessfully = false
    dialogDidCancel = false
    dialogError = nil
    AccessToken.current = SampleAccessTokens.validToken
    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "gaming")
  }

  override func tearDown() {
    AccessToken.current = nil
    AuthenticationToken.current = nil

    super.tearDown()
  }

  func testWrapperShareDialogTournamentCreateURLIsValid() throws {
    _ = try shareDialogWrapper.show(initialScore: 120, config: tournamentConfig)
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    let query = try XCTUnwrap(dialogURL.query)
    XCTAssertEqual(dialogURL.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertNotNil(query, "Query should not be null")
  }

  func testWrapperUpdateDialogURLIsValid() throws {
    try shareDialogWrapper.show(score: 120, tournament: _FBSDKTournament(tournament: validTournamentForUpdate))
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    XCTAssertEqual(dialogURL.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertNotNil(dialogURL.query)
  }

  func testWrapperUpdateDialogWithTournamentIDCreatesValidURL() throws {
    try shareDialogWrapper.show(score: 1, tournamentID: "12345")
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    XCTAssertEqual(dialogURL.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertNotNil(dialogURL.query)
  }

  func testWrapperUpdateDialogWithInvalidTournamentID() throws {
    var caughtInvalidTournamentID = false
    do {
      _ = try shareDialogWrapper.show(score: 1, tournamentID: "")
    } catch ShareTournamentDialogError.invalidTournamentID {
      caughtInvalidTournamentID = true
    } catch {
      return XCTFail("Should not throw an error other than invalid access token, error received: \(error)")
    }

    XCTAssertTrue(caughtInvalidTournamentID, "Should catch error ShareTournamentDialogError.invalidTournamentID")
    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func didComplete(dialog: _ShareTournamentDialog, tournament: _FBSDKTournament) {
    dialogDidCompleteSuccessfully = true
  }

  func didFail(withError error: Error, dialog: _ShareTournamentDialog) {
    dialogError = error as? ShareTournamentDialogError
  }

  func didCancel(dialog: _ShareTournamentDialog) {
    dialogDidCancel = true
  }
}
