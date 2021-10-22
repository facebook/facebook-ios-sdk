/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public enum TournamentDecodingError: Error {
  case invalidExpirationDate
  case invalidScoreType
}

struct Tournament: Codable {

  /**
   The unique ID that is associated with this tournament.
   */
  var identifier: String

  /**
   Timestamp when the tournament ends.
   If the expiration is in the past, then the tournament is already finished and has expired.
   */
  var expiration: Date?

  /**
   Title of the tournament provided upon the creation of the tournament.
   */
  var title: String?

  /**
   The sort order of the score for the tournament provided upon the creation of the tournament.
   */
  var sortOrder: TournamentSortOrder?

  /**
   Payload of the tournament provided upon the creation of the tournament.
   */
  var payload: String?

  /**
   The image associated with the tournament
   */
  var image: UIImage?

  /**
   The current score for the player for this  tournament.
   You can update the score by calling the `TournamentUpdater` and passing in the tournament and new score.
   */
  var score: Int? {
    if let numericScore = numericScore?.value {
      return numericScore
    } else if let time = timeScore?.value {
      return Int(time)
    }
    return nil
  }

  var numericScore: NumericScore?
  var timeScore: TimeScore?

  init(
    identifier: String,
    expiration: Date? = nil,
    title: String? = nil,
    payload: String? = nil
  ) {
    self.identifier = identifier
    self.expiration = expiration
    self.title = title
    self.payload = payload
  }

  // swiftlint:disable line_length
  /// Creates a new tournament with the given parameters. Passing the created tournament to the `ShareTournamentDialog.init(create:delegate:)` will share and create the tournament server side.
  ///
  /// - Parameter title: Optional text title for the tournament
  /// - Parameter expiration: Optional input for setting a custom end time for the tournament. if not specified, the default is a week after creation date.
  /// - Parameter scoreType: Optional input for the formatting of the scores in the tournament leaderboard. See enum `ScoreType`, if not specified, the default is `ScoreType.numeric`.
  /// - Parameter sortOrder: Optional input for the ordering of which score is best in the tournament. See enum `TournamentSortOrder`, if not specified, the default is `TournamentSortOrder.descending`.
  /// - Parameter image: Optional image that will be associated with the tournament and included in any posts.
  /// - Parameter payload: Optional data to attach to the update.All game sessions launched from the update will be able to access this blob. Must be less than or equal to 1000 characters when stringified.
  ///
  // swiftlint:enable line_length
  init(
    title: String? = nil,
    expiration: Date? = nil,
    sortOrder: TournamentSortOrder? = nil,
    image: UIImage? = nil,
    payload: String? = nil
  ) {
    self.init(identifier: "", expiration: expiration, title: title, payload: payload)
    self.sortOrder = sortOrder
    self.image = image
  }

  mutating func update<T: Score>(score: T) throws {
    if let numericScore = score as? NumericScore {
      self.numericScore = numericScore
    } else if let time = score.value as? TimeScore {
      self.timeScore = time
    } else {
      throw TournamentDecodingError.invalidScoreType
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    identifier = try container.decode(String.self, forKey: .identifier)
    let dateStamp = try container.decode(String.self, forKey: .expiration)

    if let expirationDate = DateFormatter.format(ISODateString: dateStamp) {
      expiration = expirationDate
    } else {
      throw TournamentDecodingError.invalidExpirationDate
    }

    title = try container.decodeIfPresent(String.self, forKey: .title)
    payload = try container.decodeIfPresent(String.self, forKey: .payload)
  }

  enum CodingKeys: String, CodingKey {
    case identifier = "id"
    case expiration = "tournament_end_time"
    case title = "tournament_title"
    case payload = "tournament_payload"
  }
}
