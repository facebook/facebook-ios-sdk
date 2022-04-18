/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit

public enum ShareTournamentDialogError: Error {
  case invalidAccessToken
  case invalidAuthToken
  case invalidTournamentID
  case unableToCreateDialogUrl
  case unknownBridgeError
  case errorMessage(String)
  case bridgeError(Error)
}

public final class ShareTournamentDialog: NSObject, URLOpening {

  let gamingGraphDomain = "gaming"
  var bridgeURLOpener: BridgeAPIRequestOpening = BridgeAPI.shared
  weak var delegate: ShareTournamentDialogDelegate?
  var currentConfig: TournamentConfig?
  var tournamentToUpdate: Tournament?

  init(
    delegate: ShareTournamentDialogDelegate,
    urlOpener: BridgeAPIRequestOpening
  ) {
    self.delegate = delegate
    bridgeURLOpener = urlOpener
  }

  /**
   Creates a share a dialog that can be used to share a score using a new tournament configuration
   or an existing tournament

   - Parameter delegate: The delegate for the dialog to be invoked in case of error, cancellation or completion
   */
  public convenience init(
    delegate: ShareTournamentDialogDelegate
  ) {
    self.init(delegate: delegate, urlOpener: BridgeAPI.shared)
  }

  /**
   Attempts to show the share dialog to share an existing tournament
   - Parameter score: A score to share in the tournament could be a numeric score or time interval
      dependent on the given tournament score type
   - Parameter tournamentID: The ID of the  tournament to share and update with the given score
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  public func show(score: Int, tournamentID: String) throws {
    guard !tournamentID.isEmpty else {
      throw ShareTournamentDialogError.invalidTournamentID
    }
    try show(score: score, tournament: Tournament(identifier: tournamentID))
  }

  /**
   Attempts to show the share dialog to share an existing tournament
   - Parameter score: A score to share in the tournament could be a numeric score or time interval
      dependent on the given tournament score type
   - Parameter tournament: The tournament to share and update with the given score
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  public func show(score: Int, tournament: Tournament) throws {
    tournamentToUpdate = tournament
    guard let accessToken = AccessToken.current else {
      throw ShareTournamentDialogError.invalidAccessToken
    }
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == gamingGraphDomain else {
      throw ShareTournamentDialogError.invalidAuthToken
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

  /**
   Attempts to show the share dialog to share a newly created tournnament

   - Parameter initialScore: An initial score to share, could be a numeric score or time interval
      dependent on the tournament configuration
   - Parameter config: The tournament configuration used to create a new tournament
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  public func show(initialScore: Int, config: TournamentConfig) throws {
    currentConfig = config
    guard let accessToken = AccessToken.current else {
      throw ShareTournamentDialogError.invalidAccessToken
    }
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == gamingGraphDomain else {
      throw ShareTournamentDialogError.invalidAuthToken
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

  func isTournamentURL(url: URL) -> Bool {
    if let scheme = url.scheme,
       let host = url.host,
       let appID = Settings.shared.appID {
      return scheme.hasPrefix("fb\(appID)") && host.elementsEqual("instant_tournament")
    }
    return false
  }

  func parseTournamentURL(url: URL) -> Bool {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    guard let queryItems = components?.queryItems else {
      delegate?.didCancel(dialog: self)
      return false
    }
    let tournamentIDQueryItem = queryItems.filter { item in
      item.name.elementsEqual("tournament_id")
    }
    let errorMessageQueryItem = queryItems.filter { item in
      item.name.elementsEqual("error_message")
    }
    if errorMessageQueryItem.count == 1, let errorMessage = errorMessageQueryItem.first?.value {
      delegate?.didFail(withError: ShareTournamentDialogError.errorMessage(errorMessage), dialog: self)
    }
    guard
      tournamentIDQueryItem.count == 1,
      let tournamentID = tournamentIDQueryItem.first?.value
    else {
      return false
    }
    if let currentConfig = currentConfig {
      let createdTournament = Tournament(identifier: tournamentID, config: currentConfig)
      delegate?.didComplete(dialog: self, tournament: createdTournament)
    }
    if let tournamentToUpdate = tournamentToUpdate, tournamentToUpdate.identifier == tournamentID {
      delegate?.didComplete(dialog: self, tournament: tournamentToUpdate)
    }
    return false
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
    guard let url = url else {
      return false
    }
    return parseTournamentURL(url: url)
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    isTournamentURL(url: url)
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {}
}
