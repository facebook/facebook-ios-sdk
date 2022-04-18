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
 An internal class for fetching tournament objects. Use `TournamentUpdater` instead.
 - Warning: For internal use only! Subject to change or removal at any time.
 */
@objcMembers
@objc(_FBSDKTournamentUpdater)
public final class _TournamentUpdater: NSObject {

  let graphRequestFactory: GraphRequestFactoryProtocol

  init(graphRequestFactory: GraphRequestFactoryProtocol) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
   Updates the given tournament with the given score

   - Parameter tournamentID: The ID of the tournament you want to update
   - Parameter score: The new score to update within the tournament
   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete. Completes with `true` if successful.
   */
  public func update(
    tournamentID: String,
    score: Int,
    completionHandler: @escaping (Bool, Error?) -> Void
  ) {
    guard !tournamentID.isEmpty else {
      return completionHandler(false, TournamentUpdaterError.invalidTournamentID)
    }
    TournamentUpdater(graphRequestFactory: graphRequestFactory)
      .update(tournamentID: tournamentID, score: score) { result in
        switch result {
        case let .success(success):
          completionHandler(success, nil)
        case let .failure(error):
          completionHandler(false, error)
        }
      }
  }

  /**
   Updates the given tournament with the given score

   - Parameter tournament: The tournament you want to update
   - Parameter score: The new score to update within the tournament
   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete. Completes with `true` if successful.
   */

  public func update(
    tournament: _FBSDKTournament,
    score: Int,
    completionHandler: @escaping (Bool, Error?) -> Void
  ) {
    update(tournamentID: tournament.identifier, score: score, completionHandler: completionHandler)
  }
}
