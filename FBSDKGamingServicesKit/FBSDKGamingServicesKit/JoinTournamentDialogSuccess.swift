/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 The result of a successful `JoinTournamentDialog`.
 */
public struct JoinTournamentDialogSuccess: GamingWebDialogSuccess {
  /// ID of the joined tournament.
  public let tournamentID: String
  /// Optional payload for the tournament.
  public let payload: String?

  public init(_ dict: [String: Any]) throws {
    guard let tournamentID = dict[JoinTournamentDialog.Keys.tournamentID] as? String,
          !tournamentID.isEmpty else { throw GamingServicesDialogError.cancelled }

    self.tournamentID = tournamentID
    payload = dict[JoinTournamentDialog.Keys.payload] as? String
  }
}
