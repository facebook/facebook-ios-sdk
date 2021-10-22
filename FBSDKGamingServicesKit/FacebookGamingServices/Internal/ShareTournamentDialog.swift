/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
