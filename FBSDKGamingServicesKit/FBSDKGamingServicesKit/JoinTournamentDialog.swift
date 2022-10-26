/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// A dialog that allows the user to join a tournament.
public final class JoinTournamentDialog: GamingWebDialog<JoinTournamentDialogSuccess> {

  private let viewName = "join_tournament"
  public var tournamentID: String?
  public var payload: String?

  enum Keys {
    static let tournamentID = "tournament_id"
    static let payload = "payload"
  }

  public init() {
    super.init(name: viewName)
  }

  /**
   Shows a dialog prompting the user to join a specific, active tournament.
   - Parameters:
    - tournamentID: ID for the tournament to be joined.
    - payload: Optional payload for the tournament.
   */
  public func showSpecific(
    tournamentID: String,
    payload: String?,
    completion: @escaping (Result<JoinTournamentDialogSuccess, Error>) -> Void
  ) {
    parameters = [Keys.tournamentID: tournamentID]
    if let payload = payload {
      parameters[Keys.payload] = payload
    }
    show(completion: completion)
  }

  /**
   Shows a dialog listing joinable tournaments suggested by Facebook.
   - Parameters:
    - payload: Payload for the tournament.
   */
  public func showSuggested(
    payload: String?,
    completion: @escaping (Result<JoinTournamentDialogSuccess, Error>) -> Void
  ) {
    if let payload = payload {
      parameters[Keys.payload] = payload
    }
    show(completion: completion)
  }
}
