/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
    var components = try XCTUnwrap(URLComponents(url: SampleURLs.valid, resolvingAgainstBaseURL: false))

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
