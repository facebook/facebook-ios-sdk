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

import FBSDKCoreKit
import Foundation

public enum TournamentFetchError: Error {
  case server(Error)
  case decoding
  case invalidAuthToken
  case invalidAccessToken
}

public class TournamentFetcher {

  let graphRequestFactory: GraphRequestFactoryProtocol
  let gamingGraphDomain = "gaming"

  public init(graphRequestFactory: GraphRequestFactoryProtocol = GraphRequestFactory()) {
    self.graphRequestFactory = graphRequestFactory
  }

  public func fetchTournaments(completionHandler: @escaping (Result<[Tournament], TournamentFetchError>) -> Void) {
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
