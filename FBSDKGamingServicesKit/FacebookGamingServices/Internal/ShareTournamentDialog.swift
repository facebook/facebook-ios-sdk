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

public class ShareTournamentDialog: NSObject, URLOpening {

  var bridgeURLOpener: BridgeAPIRequestOpening = BridgeAPI.shared
  weak var delegate: ShareTournamentDialogDelegate?

  init(
    delegate: ShareTournamentDialogDelegate,
    urlOpener: BridgeAPIRequestOpening
  ) {
    self.delegate = delegate
    self.bridgeURLOpener = urlOpener
  }

  /**
   Creates a share a dialog that can be used to share a score in the given `Tournament`

   - Parameter delegate: The delegate for the dialog to be invoked in case of error, cancellation or completion
   */
  convenience init(
    delegate: ShareTournamentDialogDelegate
  ) {
    self.init(delegate: delegate, urlOpener: BridgeAPI.shared)
  }

  // swiftlint:disable line_length
  /**
   Attempts to show the share dialog to share an existing tournament
   - Parameter score: A score to share in the tournament could be a numeric score or time interval dependent on the given tournament score type
   - Parameter tournament: The tournament to share and update with the given score
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  // swiftlint:enable line_length
  public func show(score: Int, tournament: Tournament) throws {
    guard let accessToken = AccessToken.current else {
      throw ShareTournamentDialogError.invalidAccessToken
    }
    guard
      let url = ShareTournamentDialogURLBuilder
        .update(tournament)
        .url(withPathAppID: accessToken.appID, score: score)
    else {
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

  // swiftlint:disable line_length
  /**
   Attempts to show the share dialog to share a newly created tournnament

   - Parameter initialScore: An initial score to share, could be a numeric score or time interval dependent on the tournament configuration
   - Parameter config: The tournament configuration used to create a new tournament
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  // swiftlint:enable line_length
  public func show(initialScore: Int, config: TournamentConfig) throws {
    guard let accessToken = AccessToken.current else {
      throw ShareTournamentDialogError.invalidAccessToken
    }
    guard
      let url = ShareTournamentDialogURLBuilder
        .create(config)
        .url(withPathAppID: accessToken.appID, score: initialScore)
    else {
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
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    false
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
  }
}
