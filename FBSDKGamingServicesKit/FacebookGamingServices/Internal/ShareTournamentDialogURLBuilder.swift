/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit

internal enum ShareTournamentDialogURLBuilder {

  enum Constants {
    static let host = "fb.gg"
    static let path = "/me/instant_tournament/"
  }

  enum QueryKeys {
    static let score = "score"
    static let tournamentID = "tournament_id"
    static let title = "tournament_title"
    static let scoreFormat = "score_format"
    static let sortOrder = "sort_order"
    static let endTime = "end_time"
    static let payload = "tournament_payload"
  }

  case create(TournamentConfig)
  case update(Tournament)

  func queryItems(for config: TournamentConfig, score: Int) -> [URLQueryItem] {
    var tournamentDictionary = [String: String]()
    tournamentDictionary[QueryKeys.score] = "\(score)"

    if let title = config.title {
      tournamentDictionary[QueryKeys.title] = title
    }
    if let endTime = config.endTime {
      tournamentDictionary[QueryKeys.endTime] = "\(Int(endTime))"
    }
    if let scoreType = config.scoreType?.rawValue {
      tournamentDictionary[QueryKeys.scoreFormat] = scoreType
    }
    if let sortOrder = config.sortOrder?.rawValue {
      tournamentDictionary[QueryKeys.sortOrder] = sortOrder
    }
    if let payload = config.payload {
      tournamentDictionary[QueryKeys.payload] = payload
    }
    return tournamentDictionary.map { queryName, value in
      URLQueryItem(name: queryName, value: value)
    }
  }

  func url(withPathAppID appID: String, score: Int) -> URL? {
    var components = URLComponents()
    components.scheme = URLScheme.https.rawValue
    components.host = Constants.host
    components.path = "\(Constants.path)\(appID)"

    if case .update(let tournament) = self {
      components.queryItems = [
        URLQueryItem(name: QueryKeys.tournamentID, value: tournament.identifier),
        URLQueryItem(name: QueryKeys.score, value: "\(score)"),
        URLQueryItem(name: QueryKeys.payload, value: tournament.payload)
      ]
    }
    if case .create(let config) = self {
      components.queryItems = queryItems(for: config, score: score)
    }

    return components.url
  }
}
