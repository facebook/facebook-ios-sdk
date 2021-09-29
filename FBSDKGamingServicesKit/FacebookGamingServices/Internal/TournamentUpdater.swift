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

public enum TournamentUpdaterError: Error {
  case server(Error)
  case decoding
}

/**
  A graph request wrapper to update a tournament
 */
public class TournamentUpdater {

  enum GraphRequest {
    static let scoreParameterKey = "score"

    static func path(identifier: String) -> String {
      "\(identifier)/update_score"
    }
  }

  let graphRequestFactory: GraphRequestFactoryProtocol

  /**
   Creates the TournamentUpdater
   */
  public convenience init() {
    self.init(graphRequestFactory: GraphRequestFactory())
  }

  init(graphRequestFactory: GraphRequestFactoryProtocol) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
      Updates the given tournament with the given score

   - Parameter tournament: The tournament you want to update
   - Parameter score: The new score to update within the tournament
   - Parameter completionHandler: The caller's completion handler to invoke once the graph request is complete
   */

  public func update(
    tournament: Tournament,
    score: Int,
    completionHandler: @escaping (Result<Void, TournamentUpdaterError>) -> Void
  ) {
    let parameters = [GraphRequest.scoreParameterKey: score]
    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: GraphRequest.path(identifier: tournament.identifier),
      parameters: parameters,
      httpMethod: .post
    )

    request.start { _, result, error in
      if let error = error {
        completionHandler(.failure(.server(error)))
        return
      }
      guard
        let result = result as? [String: Bool],
        let data = try? JSONSerialization.data(withJSONObject: result, options: []),
        let serverResults = try? JSONDecoder().decode(ServerResult.self, from: data),
        serverResults.success
      else {
        completionHandler(.failure(.decoding))
        return
      }
      completionHandler(.success(()))
    }
  }
}
