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

import Foundation

import FBSDKCoreKit

public enum ShareTournamentDialogError: Error {
  case invalidAccessToken
  case tournamentMissingIdentifier
  case tournamentMissingScore
  case missingUpdateScore
  case bridgeError(Error)
}

public class ShareTournamentDialog: NSObject, URLOpening {

  enum ShareType {
    case create
    case update
  }

  var bridgeURLOpener: BridgeAPIRequestOpening
  var tournament: Tournament
  var shareType: ShareType

  init(
    tournament: Tournament,
    score: Int?,
    urlOpener: BridgeAPIRequestOpening,
    shareType: ShareType
  ) {
    self.tournament = tournament
    self.bridgeURLOpener = urlOpener
    self.shareType = shareType
    self.tournament.score = score
  }

  /**
     Creates a share a dialog that will share and update the given tournament with the given score and payload.

      - Parameter tournament: The Tournament to update and share
      - Parameter score: The new score to update in the given tournament
      - Parameter payload: Optional blob of data to attach to the update.
                           Must be less than or equal to 1000 characters when stringified.
   */
  public convenience init(
    update tournament: Tournament,
    score: Int,
    payload: String? = nil
  ) {
    self.init(tournament: tournament, score: score, urlOpener: BridgeAPI.shared, shareType: .update)
    self.tournament.payload = payload
  }

  public func show() throws {
    try validateTournamentForUpdate()
    guard let accessToken = AccessToken.current else {
      return
    }

    guard let url = ShareTournamentDialogURLBuilder.update(self.tournament).url(withPathAppID: accessToken.appID) else {
      return
    }
    bridgeURLOpener.open(url, sender: self) { _, _ in }
    return
  }

  func validateTournamentForUpdate() throws {
    guard tournament.identifier.isEmpty else {
      throw ShareTournamentDialogError.tournamentMissingIdentifier
    }

    guard tournament.score != nil else {
      throw ShareTournamentDialogError.tournamentMissingScore
    }
  }

  // MARK: URLOpening

  public func isAuthenticationURL(_ url: URL) -> Bool {
    false
  }

  public func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    false
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication,
    sourceApplication: String,
    annotation: Any?
  ) -> Bool {
    false
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
  }
}
