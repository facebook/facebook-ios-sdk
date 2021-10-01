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

  enum UpdateConstants {
    static let scheme = "https"
    static let host = "fb.gg"
    static let payloadQueryItem = "tournament_payload"
    static let scoreQueryItem = "score"
    static let tournamentID = "tournament_id"
    static let path = "/me/instant_tournament/"
  }

  case create(Tournament)
  case update(Tournament)

  var queryItems: [URLQueryItem] {
    switch self {
    case .create: return []
    case .update(let tournament):
      guard let score = tournament.score else {
        return []
      }
      var updateQueryItems = [
        URLQueryItem(
          name: UpdateConstants.tournamentID,
          value: String(describing: tournament.identifier)
        ),
        URLQueryItem(
          name: UpdateConstants.scoreQueryItem,
          value: String(describing: score)
        )
      ]

      if let payload = tournament.payload {
        updateQueryItems.append(URLQueryItem(
          name: UpdateConstants.payloadQueryItem,
          value: "\(payload)"
        ))
      }
      return updateQueryItems
    }
  }

  func url(withPathAppID appID: String) -> URL? {
    var components = URLComponents()
    components.scheme = UpdateConstants.scheme
    components.host = UpdateConstants.host
    components.path = "\(UpdateConstants.path)\(appID)"
    components.queryItems = queryItems
    return components.url
  }
}
