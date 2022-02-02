/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

public enum TournamentUpdaterError: Error {
  case server(Error)
  case decoding
  case invalidAuthToken
  case invalidAccessToken
  case invalidTournamentID
}

/**
 A graph request wrapper to update a tournament
 */
public class TournamentUpdater {

  enum GraphRequest {
    static let gamingGraphDomain = "gaming"
    static let scoreParameterKey = "score"

    static func path(identifier: String) -> String {
      "\(identifier)/update_score"
    }
  }

  let graphRequestFactory: GraphRequestFactoryProtocol

  /**
   Creates the TournamentUpdater
   */
  public convenience init() {
    self.init(graphRequestFactory: GraphRequestFactory())
  }

  init(graphRequestFactory: GraphRequestFactoryProtocol) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
   Updates the given tournament with the given score

   - Parameter tournamentID: The ID of the tournament you want to update
   - Parameter score: The new score to update within the tournament
   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete
   */

  public func update(
    tournamentID: String,
    score: Int,
    completionHandler: @escaping (Result<Bool, TournamentUpdaterError>) -> Void
  ) {
    guard !tournamentID.isEmpty else {
      return completionHandler(.failure(TournamentUpdaterError.invalidTournamentID))
    }
    update(tournament: Tournament(identifier: tournamentID), score: score, completionHandler: completionHandler)
  }

  /**
   Updates the given tournament with the given score

   - Parameter tournament: The tournament you want to update
   - Parameter score: The new score to update within the tournament
   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete
   */

  public func update(
    tournament: Tournament,
    score: Int,
    completionHandler: @escaping (Result<Bool, TournamentUpdaterError>) -> Void
  ) {
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == GraphRequest.gamingGraphDomain else {
      return completionHandler(.failure(TournamentUpdaterError.invalidAuthToken))
    }

    let parameters = [GraphRequest.scoreParameterKey: score]
    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: GraphRequest.path(identifier: tournament.identifier),
      parameters: parameters as [String: Any],
      httpMethod: .post
    )

    request.start { _, result, error in
      if let error = error {
        completionHandler(.failure(.server(error)))
        return
      }
      guard
        let result = result as? [String: Bool],
        let data = try? JSONSerialization.data(withJSONObject: result, options: []),
        let serverResults = try? JSONDecoder().decode(ServerResult.self, from: data),
        serverResults.success
      else {
        completionHandler(.failure(.decoding))
        return
      }
      completionHandler(.success(serverResults.success))
    }
  }
}
