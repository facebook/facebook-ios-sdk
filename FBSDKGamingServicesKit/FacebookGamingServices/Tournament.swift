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

public enum TournamentDecodingError: Error {
  case invalidExpirationDate
}

public struct Tournament: Codable {

  /**
   The unique ID that is associated with this tournament.
   */
  public internal(set) var identifier: String

  /**
   Timestamp when the  tournament ends.
   If the expiration is in the past, then the tournament is already finished and has expired.
   */
  public internal(set) var expiration: Date

  /**
   Title of the tournament provided upon the creation of the tournament.
   */
  public internal(set) var title: String?

  /**
   Payload of the tournament provided upon the creation of the tournament.
   */
  public internal(set) var payload: String?

  /**
   The current score for the player for this  tournament.
   You can update the score by calling the `TournamentUpdater` and passing in the tournament and new score.
   */
  public internal(set) var score: Int?

  init(
    identifier: String,
    expiration: Date,
    score: Int? = nil,
    title: String? = nil,
    payload: String? = nil
  ) {
    self.identifier = identifier
    self.expiration = expiration
    self.title = title
    self.payload = payload
    self.score = score
  }

  public init(from decoder: Decoder) throws {
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
    score = try container.decodeIfPresent(Int.self, forKey: .score)
  }

  enum CodingKeys: String, CodingKey {
    case identifier = "id"
    case expiration = "tournament_end_time"
    case title = "tournament_title"
    case payload = "tournament_payload"
    case score
  }
}
