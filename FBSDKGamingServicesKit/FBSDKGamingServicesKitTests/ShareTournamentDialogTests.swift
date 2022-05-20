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

final class ShareTournamentDialogTests: XCTestCase, ShareTournamentDialogDelegate {

  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: ShareTournamentDialogError?

  let bridgeOpener = TestBridgeAPIRequestOpener()
  let expirationDate = DateFormatter.format(ISODateString: "2021-09-24T18:03:47+0000")
  lazy var validTournamentForUpdate = Tournament(
    identifier: "1234",
    endTime: expirationDate
  )
  lazy var tournamentConfiguration = TournamentConfig(
    title: "test",
    endTime: expirationDate,
    scoreType: .numeric,
    sortOrder: .higherIsBetter,
    payload: "test"
  )

  lazy var shareDialog = ShareTournamentDialog(
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

  func testShareDialogCreation() throws {
    let dialog = ShareTournamentDialog(delegate: self)
    XCTAssertNotNil(dialog.delegate)
  }

  // MARK: - Share Dialog Creating Tournament

  func testShareDialogTournamentCreateWithInvalidAccessToken() throws {
    AccessToken.current = nil
    let dialog = try XCTUnwrap(shareDialog)
    var caughtInvalidAccessToken = false
    do {
      try dialog.show(initialScore: 120, config: tournamentConfiguration)
    } catch ShareTournamentDialogError.invalidAccessToken {
      caughtInvalidAccessToken = true
    } catch {
      return XCTFail("Should not throw an error other than invalid access token, error received: \(error)")
    }

    XCTAssertTrue(caughtInvalidAccessToken, "Should catch error ShareTournamentDialogError.invalidAccessToken")
    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func testShareDialogTournamentCreateWithInvalidAuthToken() throws {
    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "notGaming")
    var caughtInvalidAuthToken = false
    let dialog = try XCTUnwrap(shareDialog)
    do {
      try dialog.show(initialScore: 120, config: tournamentConfiguration)
    } catch ShareTournamentDialogError.invalidAuthToken {
      caughtInvalidAuthToken = true
    } catch {
      return XCTFail("Should not throw an error other than invalid access token, error received: \(error)")
    }

    XCTAssertTrue(caughtInvalidAuthToken, "Should catch error ShareTournamentDialogError.invalidAuthToken")
    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func testShareDialogTournamentCreateBridgeFailure() throws {
    let dialog = try XCTUnwrap(shareDialog)
    _ = try dialog.show(initialScore: 120, config: tournamentConfiguration)
    guard let handler = bridgeOpener.capturedHandler else {
      return XCTFail("The bridge should be called with a valid success block handler")
    }

    handler(false, SampleError())

    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    guard case let .bridgeError(error) = dialogError, error is SampleError else {
      if let error = dialogError {
        XCTFail("Expecting bridge error but instead received:  \(error)) ")
      }
      return
    }
  }

  func testShareDialogTournamentCreateURLIsValid() throws {
    let dialog = try XCTUnwrap(shareDialog)
    _ = try dialog.show(initialScore: 120, config: tournamentConfiguration)
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    let query = try XCTUnwrap(dialogURL.query)
    XCTAssertEqual(dialogURL.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertNotNil(query, "Query should not be null")
  }

  // MARK: - Share Dialog Updating Tournament

  func testUpdateShareDialogTournamentWithInvalidAuthToken() throws {
    AuthenticationToken.current = SampleAuthenticationToken.validToken(withGraphDomain: "notGaming")
    var caughtInvalidAuthToken = false
    do {
      try shareDialog.show(score: 120, tournament: validTournamentForUpdate)
    } catch ShareTournamentDialogError.invalidAuthToken {
      caughtInvalidAuthToken = true
    } catch {
      return XCTFail("Should not throw an error other than invalid access token, error received: \(error)")
    }

    XCTAssertTrue(caughtInvalidAuthToken, "Should catch error ShareTournamentDialogError.invalidAuthToken")
    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func testShowingUpdateDialogWithInvalidAccessToken() throws {
    AccessToken.current = nil
    var caughtInvalidAccessToken = false
    do {
      try shareDialog.show(score: 120, tournament: validTournamentForUpdate)
    } catch ShareTournamentDialogError.invalidAccessToken {
      caughtInvalidAccessToken = true
    } catch {
      return XCTFail("Should not throw an error other than invalid access token, error received: \(error)")
    }

    XCTAssertTrue(caughtInvalidAccessToken, "Should catch error ShareTournamentDialogError.invalidAccessToken")
    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func testUpdateDialogBridgeFailure() throws {
    _ = try shareDialog.show(score: 120, tournament: validTournamentForUpdate)
    guard let handler = bridgeOpener.capturedHandler else {
      return XCTFail("The bridge should be called with a valid success block handler")
    }

    handler(false, SampleError())

    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    guard case let .bridgeError(error) = dialogError, error is SampleError else {
      return XCTFail("Expecting bridge error but instead received: \(String(describing: dialogError)) ")
    }
  }

  func testUpdateDialogURLIsValid() throws {
    _ = try shareDialog.show(score: 120, tournament: validTournamentForUpdate)
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    XCTAssertEqual(dialogURL.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertNotNil(dialogURL.query)
  }

  // MARK: - Share Dialog Updating Tournament with ID

  func testUpdateDialogWithInvalidTournamentID() throws {
    var caughtInvalidTournamentID = false
    do {
      try shareDialog.show(score: 1, tournamentID: "")
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

  func testUpdateDialogWithTournamentIDCreatesValidURL() throws {
    _ = try shareDialog.show(score: 1, tournamentID: "12345")
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    XCTAssertEqual(dialogURL.scheme, URLScheme.https.rawValue)
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertNotNil(dialogURL.query)
  }

  func didComplete(dialog: ShareTournamentDialog, tournament: Tournament) {
    dialogDidCompleteSuccessfully = true
  }

  func didFail(withError error: Error, dialog: ShareTournamentDialog) {
    dialogError = error as? ShareTournamentDialogError
  }

  func didCancel(dialog: ShareTournamentDialog) {
    dialogDidCancel = true
  }
}
