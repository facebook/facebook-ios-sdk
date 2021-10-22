/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit

enum ShareTournamentDialogURLBuilder {

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

  case create(Tournament)
  case update(Tournament)

  var queryItems: [URLQueryItem] {
    switch self {
    case .create(let tournament):
      return self.queryItems(for: tournament)
    case .update(let tournament):
      return self.queryItems(for: tournament)
    }
  }

  func queryItems(for tournament: Tournament) -> [URLQueryItem] {
    guard let score = tournament.score else {
      return []
    }
    var tournamentDictionary = [String: String]()
    tournamentDictionary[QueryKeys.score] = "\(score)"

    if let payload = tournament.payload {
      tournamentDictionary[QueryKeys.payload] = payload
    }
    if !tournament.identifier.isEmpty {
      tournamentDictionary[QueryKeys.tournamentID] = tournament.identifier
      return tournamentDictionary.map { queryName, value in
        URLQueryItem(name: queryName, value: value)
      }
    }
    if let endTime = tournament.expiration?.timeIntervalSince1970 {
      tournamentDictionary[QueryKeys.endTime] = "\(Int(endTime))"
    }
    if let title = tournament.title {
      tournamentDictionary[QueryKeys.title] = title
    }
    if let sortOrder = tournament.sortOrder?.rawValue {
      tournamentDictionary[QueryKeys.sortOrder] = sortOrder
    }
    if tournament.numericScore != nil {
      tournamentDictionary[QueryKeys.scoreFormat] = ScoreType.numeric.rawValue
    }
    if tournament.timeScore != nil {
      tournamentDictionary[QueryKeys.scoreFormat] = ScoreType.time.rawValue
    }
    return tournamentDictionary.map { queryName, value in
      URLQueryItem(name: queryName, value: value)
    }
  }

  func url(withPathAppID appID: String) -> URL? {
    var components = URLComponents()
    components.scheme = URLScheme.https.rawValue
    components.host = Constants.host
    components.path = "\(Constants.path)\(appID)"
    components.queryItems = queryItems
    return components.url
  }
}
