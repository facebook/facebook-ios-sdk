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
import TestTools

class ShareTournamentDialogTests: XCTestCase, ShareTournamentDialogDelegate {

  var dialogDidCompleteSuccessfully = false
  var dialogDidCancel = false
  var dialogError: ShareTournamentDialogError?

  let bridgeOpener = TestBridgeAPIRequestOpener()
  let expirationDate = Date()
  lazy var validTournament = Tournament(identifier: "1234", expiration: expirationDate, score: 0)
  lazy var tournamentWithInvalidIdentifier = Tournament(identifier: "", expiration: expirationDate)
  lazy var updateShareDialog = ShareTournamentDialog(
    tournament: validTournament,
    score: 120,
    urlOpener: bridgeOpener,
    shareType: .update,
    delegate: self
  )

  override func setUp() {
    super.setUp()

    self.dialogDidCompleteSuccessfully = false
    self.dialogDidCancel = false
    self.dialogError = nil
    AccessToken.current = SampleAccessTokens.validToken
  }

  override func tearDown() {
    AccessToken.current = nil

    super.tearDown()
  }

  func testCreatingUpdateShareDialog() {
    let dialog = ShareTournamentDialog(update: validTournament, score: 120, delegate: self)

    XCTAssertNotNil(dialog.delegate)
    XCTAssertEqual(dialog.tournament, validTournament)
    XCTAssertEqual(dialog.tournament.score, 120)
    XCTAssertEqual(dialog.shareType, .update)
  }

  func testShowingUpdateDialogWithInvalidTournament() throws {
    let dialog = ShareTournamentDialog(update: tournamentWithInvalidIdentifier, score: 120, delegate: self)
    do {
      try dialog.show()
    } catch ShareTournamentDialogError.tournamentMissingIdentifier {
      // should catch error ShareTournamentDialogError.tournamentMissingIdentifier
    } catch {
      return XCTFail("Should not throw an error other than tournament identifier error, error received: \(error)")
    }

    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func testShowingUpdateDialogWithInvalidAccessToken() throws {
    AccessToken.current = nil
    do {
      try updateShareDialog.show()
    } catch ShareTournamentDialogError.invalidAccessToken {
      // should catch error ShareTournamentDialogError.invalidAccessToken
    } catch {
      return XCTFail("Should not throw an error other than invalid access token, error received: \(error)")
    }

    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    XCTAssertNil(dialogError, "Dialog should not call delegate with error")
  }

  func testUpdateDialogBridgeFailure() throws {
    _ = try updateShareDialog.show()
    guard let handler = bridgeOpener.capturedHandler else {
      return XCTFail("The bridge should be called with a valid success block handler")
    }

    handler(false, SampleError())

    XCTAssertFalse(dialogDidCompleteSuccessfully, "Dialog should not complete")
    XCTAssertFalse(dialogDidCancel, "Dialog should not cancel")
    guard case .bridgeError(let error) = dialogError, error is SampleError else {
      return XCTFail("Expecting bridge error but instead received: \(String(describing: dialogError)) ")
    }
  }

  func testUpdateDialogURLIsValid() throws {
    _ = try updateShareDialog.show()
    guard let dialogURL = bridgeOpener.capturedURL else {
      return XCTFail("The bridge opener should be called with a valid url")
    }

    let query = try XCTUnwrap(dialogURL.query)
    XCTAssertEqual(dialogURL.scheme, "https")
    XCTAssertEqual(dialogURL.host, "fb.gg")
    XCTAssertEqual(dialogURL.path, "/me/instant_tournament/\(SampleAccessTokens.defaultAppID)")
    XCTAssertEqual(query, "tournament_id=1234&score=120")
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
