/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum SampleRawLoginCompletionParameters {

  static let secondsInDay = 60 * 60 * 24
  static let daysUntilExpiration = 60
  static let daysUntilDataExpiration = 90
  static let dataExpirationDate = Date().timeIntervalSince1970.advanced(by: Double(secondsInDay * daysUntilDataExpiration)) // swiftlint:disable:this line_length
  static let expirationDate = Date().timeIntervalSince1970.advanced(by: Double(secondsInDay * daysUntilExpiration))
  static let fakeChallenge = "some_challenge"
  static let defaultDomain = "facebook"
  static let defaultState = "{\"challenge\":\"some_challenge\"}"

  static let defaultParameters: [String: Any] = [
    "access_token": "some_access_token",
    "id_token": "some_id_token",
    "nonce": "some_nonce",
    "granted_scopes": "public_profile,openid",
    "denied_scopes": "email",
    "signed_request": "some_signed_request",
    "user_id": "123",
    "expires": expirationDate,
    "expires_at": expirationDate,
    "expires_in": secondsInDay * 60,
    "data_access_expiration_time": dataExpirationDate,
    "state": "{\"challenge\":\"\(fakeChallenge)\"}",
    "graph_domain": "facebook",
    "error": "some_error",
    "error_message": "some_error_message",
    "code": "some_code",
  ]

  static var withAccessToken: [String: Any] {
    createParameters(withKeys: [
      "access_token",
      "granted_scopes",
      "denied_scopes",
      "signed_request",
      "user_id",
      "expires",
      "expires_at",
      "expires_in",
      "data_access_expiration_time",
      "state",
      "graph_domain",
    ])
  }

  static var withAccessTokenWithIDToken: [String: Any] {
    createParameters(withKeys: [
      "access_token",
      "id_token",
      "granted_scopes",
      "denied_scopes",
      "signed_request",
      "user_id",
      "expires",
      "expires_at",
      "expires_in",
      "data_access_expiration_time",
      "state",
      "graph_domain",
    ])
  }

  static var withNonce: [String: Any] {
    createParameters(withKeys: [
      "nonce",
      "user_id",
      "state",
      "graph_domain",
    ])
  }

  static var withCode: [String: Any] {
    createParameters(withKeys: [
      "code",
      "user_id",
      "state",
      "graph_domain",
    ])
  }

  static var withIDToken: [String: Any] {
    createParameters(withKeys: [
      "id_token",
      "granted_scopes",
      "denied_scopes",
      "user_id",
      "state",
      "graph_domain",
    ])
  }

  static var withoutAccessTokenWithoutIDTokenWithoutCode: [String: Any] {
    createParameters(withKeys: [
      "granted_scopes",
      "denied_scopes",
      "signed_request",
      "user_id",
      "expires",
      "expires_at",
      "expires_in",
      "data_access_expiration_time",
      "state",
      "graph_domain",
    ])
  }

  static var withEmptyStrings = [
    "access_token": "",
    "id_token": "",
    "nonce": "",
    "code": "",
  ]

  static var withStringExpirations = [
    "access_token": "some_access_token",
    "user_id": "123",
    "expires_in": String(secondsInDay * 60),
    "data_access_expiration_time": String(dataExpirationDate),
    "state": defaultState,
    "graph_domain": defaultDomain,
  ]

  static var withError: [String: Any] {
    createParameters(withKeys: [
      "user_id",
      "state",
      "graph_domain",
      "error",
      "error_message",
    ])
  }

  static func createParameters(withKeys keys: [String]) -> [String: Any] {
    var parameters: [String: Any] = [:]
    keys.forEach { key in
      parameters[key] = defaultParameters[key]
    }
    return parameters
  }
}
