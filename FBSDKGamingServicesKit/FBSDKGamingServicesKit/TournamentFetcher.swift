/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

public enum TournamentFetchError: Error {
  case server(Error)
  case decoding
  case invalidAuthToken
  case invalidAccessToken
}

public final class TournamentFetcher {

  let graphRequestFactory: GraphRequestFactoryProtocol
  let gamingGraphDomain = "gaming"

  /// Creates the TournamentFetcher
  public convenience init() {
    self.init(graphRequestFactory: GraphRequestFactory())
  }

  init(graphRequestFactory: GraphRequestFactoryProtocol) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
      Attempts to fetch all the tournaments where the current logged in user is a participant ;

   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete
   */
  public func fetchTournaments(completionHandler: @escaping (Result<[Tournament], TournamentFetchError>) -> Void) {
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == gamingGraphDomain else {
      return completionHandler(.failure(TournamentFetchError.invalidAuthToken))
    }

    guard let accessToken = AccessToken.current else {
      return completionHandler(.failure(TournamentFetchError.invalidAccessToken))
    }

    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: "\(accessToken.userID)/tournaments",
      parameters: [:]
    )

    request.start { _, result, error in
      if let error = error {
        completionHandler(.failure(.server(error)))
        return
      }
      guard
        let result = result as? [String: Any],
        let data = try? JSONSerialization.data(withJSONObject: result, options: []),
        let graphAPIResponse = try? JSONDecoder().decode(GraphAPIResponse<[Tournament]>.self, from: data)
      else {
        completionHandler(.failure(.decoding))
        return
      }
      completionHandler(.success(graphAPIResponse.data))
    }
  }
}
