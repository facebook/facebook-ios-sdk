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

enum ShareTournamentDialogError: Error {
  case invalidAccessToken
  case tournamentMissingIdentifier
  case tournamentMissingScore
  case missingUpdateScore
  case unableToCreateDialogUrl
  case unknownBridgeError
  case bridgeError(Error)
}

class ShareTournamentDialog: NSObject, URLOpening {

  enum ShareType {
    case create
    case update
  }

  var bridgeURLOpener: BridgeAPIRequestOpening = BridgeAPI.shared
  var tournament: Tournament
  var shareType: ShareType
  weak var delegate: ShareTournamentDialogDelegate?
  var urlBuilder: ShareTournamentDialogURLBuilder {
    if shareType == .update {
      return ShareTournamentDialogURLBuilder.update(self.tournament)
    } else {
      return ShareTournamentDialogURLBuilder.create(self.tournament)
    }
  }

  init(
    tournament: Tournament,
    delegate: ShareTournamentDialogDelegate,
    urlOpener: BridgeAPIRequestOpening
  ) {
    self.tournament = tournament
    self.delegate = delegate
    self.bridgeURLOpener = urlOpener
    shareType = tournament.identifier.isEmpty ? .create:.update
  }

  /**
   Creates a share a dialog that can be used to share a score in the given `Tournament`

   - Parameter tournament: The Tournament to share
   - Parameter delegate: The delegate for the dialog to be invoked in case of error, cancellation or completion
   */
  convenience init(
    tournament: Tournament,
    delegate: ShareTournamentDialogDelegate
  ) {
    self.init(tournament: tournament, delegate: delegate, urlOpener: BridgeAPI.shared)
  }

  /**
   Attempts to share the given score by showing the share dialog
   - Parameter score: A score to  share in the tournament. Try `NumericScore` or `TimeScore`
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  func share<T: Score>(score: T) throws {
    try self.tournament.update(score: score)
    guard let accessToken = AccessToken.current else {
      throw ShareTournamentDialogError.invalidAccessToken
    }
    guard let url = urlBuilder.url(withPathAppID: accessToken.appID) else {
      throw ShareTournamentDialogError.unableToCreateDialogUrl
    }
    bridgeURLOpener.open(url, sender: self) { [weak self] success, error in
      guard let strongSelf = self else {
        return
      }
      if let error = error {
        strongSelf.delegate?.didFail(withError: ShareTournamentDialogError.bridgeError(error), dialog: strongSelf)
        return
      }
      if !success {
        strongSelf.delegate?.didFail(withError: ShareTournamentDialogError.unknownBridgeError, dialog: strongSelf)
      }
    }
  }

  // MARK: URLOpening

  func isAuthenticationURL(_ url: URL) -> Bool {
    false
  }

  func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    false
  }

  func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    false
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
  }
}
