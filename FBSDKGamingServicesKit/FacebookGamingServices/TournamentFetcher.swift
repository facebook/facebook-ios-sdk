/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

enum TournamentFetchError: Error {
  case server(Error)
  case decoding
  case invalidAuthToken
  case invalidAccessToken
}

class TournamentFetcher {

  let graphRequestFactory: GraphRequestFactoryProtocol
  let gamingGraphDomain = "gaming"

  init(graphRequestFactory: GraphRequestFactoryProtocol = GraphRequestFactory()) {
    self.graphRequestFactory = graphRequestFactory
  }

  func fetchTournaments(completionHandler: @escaping (Result<[Tournament], TournamentFetchError>) -> Void) {
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == gamingGraphDomain  else {
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
