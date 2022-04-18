/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/**
 An internal protocol for sharing tournaments. Use `ShareTournamentDialog` and `ShareTournamentDialogDelegate` instead.
 - Warning: For internal use only! Subject to change or removal at any time.
 */
@objc(_FBSDKShareTournamentDialogDelegate)
public protocol _ShareTournamentDialogDelegate: AnyObject {
  func didComplete(dialog: _ShareTournamentDialog, tournament: _FBSDKTournament)
  func didFail(withError error: Error, dialog: _ShareTournamentDialog)
  func didCancel(dialog: _ShareTournamentDialog)
}

/**
 An internal wrapper for sharing tournaments via dialog. Use `ShareTournamentDialog` instead.
 - Warning: For internal use only! Subject to change or removal at any time.
 */
@objcMembers
@objc(_FBSDKShareTournamentDialog)
public final class _ShareTournamentDialog: NSObject, ShareTournamentDialogDelegate {
  weak var delegate: _ShareTournamentDialogDelegate?
  private var dialog: ShareTournamentDialog?

  init(
    delegate: _ShareTournamentDialogDelegate,
    urlOpener: BridgeAPIRequestOpening
  ) {
    self.delegate = delegate
    super.init()
    dialog = ShareTournamentDialog(delegate: self, urlOpener: urlOpener)
  }

  /**
   Attempts to show the share dialog to share an existing tournament
   - Parameter score: A score to share in the tournament could be a numeric score or time interval
      dependent on the given tournament score type
   - Parameter tournamentID: The ID of the  tournament to share and update with the given score
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  public func show(score: Int, tournamentID: String) throws {
    try dialog?.show(score: score, tournamentID: tournamentID)
  }

  /**
   Attempts to show the share dialog to share an existing tournament
   - Parameter score: A score to share in the tournament could be a numeric score or time interval
      dependent on the given tournament score type
   - Parameter tournament: The tournament to share and update with the given score
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  public func show(score: Int, tournament: _FBSDKTournament) throws {
    let tournamentToUpdate = Tournament(
      identifier: tournament.identifier,
      endTime: tournament.endTime,
      title: tournament.title,
      payload: tournament.payload
    )
    try dialog?.show(score: score, tournament: tournamentToUpdate)
  }

  /**
   Attempts to show the share dialog to share a newly created tournnament

   - Parameter initialScore: An initial score to share, could be a numeric score or time interval
      dependent on the tournament configuration
   - Parameter config: The tournament configuration used to create a new tournament
   - throws  Will throw if an error occurs when attempting to show the dialog
   */
  public func show(initialScore: Int, config: _TournamentConfig) throws {
    // convert from internal to public enums
    let scoreType: TournamentScoreType = config.scoreType == .numeric ? .numeric : .time
    let sortOrder: TournamentSortOrder = config.sortOrder == .higherIsBetter ? .higherIsBetter : .lowerIsBetter
    var endTime: Date?
    if let configEndTime = config.endTime {
      endTime = Date(timeIntervalSince1970: configEndTime)
    }
    let currentConfig = TournamentConfig(
      title: config.title,
      endTime: endTime,
      scoreType: scoreType,
      sortOrder: sortOrder,
      image: config.image,
      payload: config.payload
    )
    try dialog?.show(initialScore: initialScore, config: currentConfig)
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
    dialog?.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation) == true
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    dialog?.canOpen(url, for: application, sourceApplication: sourceApplication, annotation: annotation) == true
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    dialog?.applicationDidBecomeActive(application)
  }

  // MARK: _ShareTournamentDialogDelegate

  public func didComplete(dialog: ShareTournamentDialog, tournament: Tournament) {
    delegate?.didComplete(dialog: self, tournament: _FBSDKTournament(tournament: tournament))
  }

  public func didFail(withError error: Error, dialog: ShareTournamentDialog) {
    delegate?.didFail(withError: error, dialog: self)
  }

  public func didCancel(dialog: ShareTournamentDialog) {
    delegate?.didCancel(dialog: self)
  }
}
