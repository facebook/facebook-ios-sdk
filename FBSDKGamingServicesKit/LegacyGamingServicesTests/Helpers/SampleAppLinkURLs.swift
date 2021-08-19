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

enum SampleUnparsedAppLinkURLs {
  enum AppLinkKeys {
    static let data = "al_applink_data"
    static let extras = "extras"
    static let payload = "payload"
    static let gameRequestId = "game_request_id"
    static let contextTokenID = "context_token_id"
  }

  enum Values {
    static let payload = "payload"
    static let gameRequestID = "123"
    static let contextTokenID = "123"
  }

  static func create(
    payload potentialPayload: String? = Values.payload,
    gameRequestID potentialGameRequestID: String? = Values.gameRequestID,
    contextTokenID potentialContextTokenID: String? = Values.contextTokenID
  ) throws -> URL {
    let payload = createAppLinkExtras(
      payload: potentialPayload,
      gameRequestID: potentialGameRequestID,
      contextTokenID: potentialContextTokenID
    )
    let url = try XCTUnwrap(createUrl(payload: payload))
    return url
  }

  static func validGameRequestUrl() throws -> URL {
    let payload = createAppLinkExtras(contextTokenID: nil)
    let url = try XCTUnwrap(createUrl(payload: payload))
    return url
  }

  static func validGamingContextUrl() throws -> URL {
    let payload = createAppLinkExtras(gameRequestID: nil)
    let url = try XCTUnwrap(createUrl(payload: payload))
    return url
  }

  static func missingKeys() throws -> URL {
    let payload = createAppLinkExtras(
      payload: nil,
      gameRequestID: nil
    )
    let url = try XCTUnwrap(createUrl(payload: payload))
    return url
  }

  // MARK: - Helpers

  static func createUrl(payload: [String: Any]) throws -> URL {
    let data = try JSONSerialization.data(withJSONObject: payload, options: [])
    let json = try XCTUnwrap(String(data: data, encoding: .utf8))
    var components = try XCTUnwrap(URLComponents(url: SampleUrls.valid, resolvingAgainstBaseURL: false))

    components.queryItems = [
      URLQueryItem(name: AppLinkKeys.data, value: json)
    ]

    return try XCTUnwrap(components.url)
  }

  static func createAppLinkExtras(
    payload potentialPayload: String? = Values.payload,
    gameRequestID potentialGameRequestID: String? = Values.gameRequestID,
    contextTokenID potentialContextTokenID: String? = Values.contextTokenID
  ) -> [String: Any] {
    var extras = [String: Any]()

    if let payload = potentialPayload {
      extras[AppLinkKeys.payload] = payload
    }
    if let gameRequestID = potentialGameRequestID {
      extras[AppLinkKeys.gameRequestId] = gameRequestID
    }
    if let contextTokenID = potentialContextTokenID {
      extras[AppLinkKeys.contextTokenID] = contextTokenID
    }

    return [AppLinkKeys.extras: extras]
  }
}
