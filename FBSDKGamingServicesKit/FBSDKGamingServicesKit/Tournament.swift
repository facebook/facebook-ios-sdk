/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

public struct Tournament: Codable {

  /// The unique ID that is associated with this tournament.
  public internal(set) var identifier: String

  /**
   Timestamp when the tournament ends.
   If the expiration is in the past, then the tournament is already finished and has expired.
   */
  public internal(set) var endTime: Date?

  /// Title of the tournament provided upon the creation of the tournament.
  public internal(set) var title: String?

  /// Payload of the tournament provided upon the creation of the tournament.
  public var payload: String?

  init(
    identifier: String,
    configuration: TournamentConfig
  ) {
    self.init(identifier: identifier, title: configuration.title, payload: configuration.payload)
    if let expirationTimeStamp = configuration.endTime {
      endTime = Date(timeIntervalSince1970: expirationTimeStamp)
    }
  }

  init(
    identifier: String,
    endTime: Date? = nil,
    title: String? = nil,
    payload: String? = nil
  ) {
    self.identifier = identifier
    self.endTime = endTime
    self.title = title
    self.payload = payload
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    identifier = try container.decode(String.self, forKey: .identifier)
    let dateStamp = try container.decode(String.self, forKey: .endTime)

    if let expirationDate = DateFormatter.format(ISODateString: dateStamp) {
      endTime = expirationDate
    } else {
      throw TournamentDecodingError.invalidExpirationDate
    }

    title = try container.decodeIfPresent(String.self, forKey: .title)
    payload = try container.decodeIfPresent(String.self, forKey: .payload)
  }

  enum CodingKeys: String, CodingKey {
    case identifier = "id"
    case endTime = "tournament_end_time"
    case title = "tournament_title"
    case payload = "tournament_payload"
  }
}
