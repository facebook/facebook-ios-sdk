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

#if FBSDK_SWIFT_PACKAGE
import FacebookCore
#else
import FBSDKCoreKit
#endif

import Foundation

public enum TournamentFetchError: Error {
  case server(Error)
  case decoding
}

public class TournamentFetcher {

  let graphRequestFactory: GraphRequestProviding

  public init(graphRequestFactory: GraphRequestProviding = GraphRequestFactory()) {
    self.graphRequestFactory = graphRequestFactory
  }

  public func fetchTournaments(completionHandler: @escaping (Result<Tournament, TournamentFetchError>) -> Void) {
    let params = ["fields": "tournaments"]
    let request = graphRequestFactory.createGraphRequest(withGraphPath: "me", parameters: params)
    request.start { _, result, error in
      if let error = error {
        completionHandler(.failure(.server(error)))
        return
      }
      guard
        let result = result,
        let data = try? JSONSerialization.data(withJSONObject: result, options: []),
        let tournament = try? JSONDecoder().decode(Tournament.self, from: data)
      else {
        completionHandler(.failure(.decoding))
        return
      }
      completionHandler(.success(tournament))
    }
  }
}
