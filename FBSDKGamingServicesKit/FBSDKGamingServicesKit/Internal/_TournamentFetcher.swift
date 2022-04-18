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
 An internal class for fetching tournament objects. Use `TournamentFetcher` instead.
 - Warning: For internal use only! Subject to change or removal at any time.
 */
@objcMembers
@objc(_FBSDKTournamentFetcher)
public final class _TournamentFetcher: NSObject {

  let graphRequestFactory: GraphRequestFactoryProtocol

  init(graphRequestFactory: GraphRequestFactoryProtocol) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
      Attempts to fetch all the tournaments where the current logged in user is a participant ;

   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete
   */
  public func fetchTournaments(completionHandler: @escaping ([_FBSDKTournament]?, Error?) -> Void) {
    TournamentFetcher(graphRequestFactory: graphRequestFactory).fetchTournaments { result in
      switch result {
      case let .success(tournaments):
        completionHandler(tournaments.map(_FBSDKTournament.init), nil)
      case let .failure(error):
        completionHandler(nil, error)
      }
    }
  }
}
