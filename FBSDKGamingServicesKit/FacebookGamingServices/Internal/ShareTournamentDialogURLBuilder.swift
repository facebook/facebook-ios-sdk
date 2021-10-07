// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

import FBSDKCoreKit

enum ShareTournamentDialogURLBuilder {

  enum Constants {
    static let scheme = "https"
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
    components.scheme = Constants.scheme
    components.host = Constants.host
    components.path = "\(Constants.path)\(appID)"
    components.queryItems = queryItems
    return components.url
  }
}
