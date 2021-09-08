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

public struct TournamentDecodingError: Error {}

public struct Tournament: Codable {

  let identifier: String
  let expiration: Date
  let title: String?
  let payload: String?

  init(identifier: String, expiration: Date, title: String?, payload: String?) {
    self.identifier = identifier
    self.expiration = expiration
    self.title = title
    self.payload = payload
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    identifier = try container.decode(String.self, forKey: .identifier)
    let dateStamp = try container.decode(String.self, forKey: .expiration)
    if let timeInterval = Double(dateStamp) {
      expiration = Date(timeIntervalSince1970: timeInterval)
    } else {
      throw TournamentDecodingError()
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
