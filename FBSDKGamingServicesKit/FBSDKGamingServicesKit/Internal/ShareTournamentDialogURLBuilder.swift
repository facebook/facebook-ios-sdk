/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

  func queryItems(for configuration: TournamentConfig, score: Int) -> [URLQueryItem] {
    var tournamentDictionary = [String: String]()
    tournamentDictionary[QueryKeys.score] = "\(score)"

    if let title = configuration.title {
      tournamentDictionary[QueryKeys.title] = title
    }
    if let endTime = configuration.endTime {
      tournamentDictionary[QueryKeys.endTime] = "\(Int(endTime))"
    }
    if let scoreType = configuration.scoreType?.rawValue {
      tournamentDictionary[QueryKeys.scoreFormat] = scoreType
    }
    if let sortOrder = configuration.sortOrder?.rawValue {
      tournamentDictionary[QueryKeys.sortOrder] = sortOrder
    }
    if let payload = configuration.payload {
      tournamentDictionary[QueryKeys.payload] = payload
    }
    return tournamentDictionary.map { queryName, value in
      URLQueryItem(name: queryName, value: value)
    }
  }

  func url(withPathAppID appID: String, score: Int) -> URL? {
    var components = URLComponents()
    components.scheme = URLSchemeEnum.https.rawValue
    components.host = Constants.host
    components.path = "\(Constants.path)\(appID)"

    if case let .update(tournament) = self {
      components.queryItems = [
        URLQueryItem(name: QueryKeys.tournamentID, value: tournament.identifier),
        URLQueryItem(name: QueryKeys.score, value: "\(score)"),
        URLQueryItem(name: QueryKeys.payload, value: tournament.payload),
      ]
    }
    if case let .create(configuration) = self {
      components.queryItems = queryItems(for: configuration, score: score)
    }

    return components.url
  }
}
