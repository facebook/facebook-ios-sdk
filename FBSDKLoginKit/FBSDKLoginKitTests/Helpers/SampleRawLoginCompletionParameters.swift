/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// swiftlint:disable identifier_name line_length
enum SampleRawLoginCompletionParameters {

  static let secondsInDay = 60 * 60 * 24
  static let daysUntilExpiration = 60
  static let daysUntilDataExpiration = 90
  static let dataExpirationDate = Date().timeIntervalSince1970.advanced(by: Double(secondsInDay * daysUntilDataExpiration))
  static let expirationDate = Date().timeIntervalSince1970.advanced(by: Double(secondsInDay * daysUntilExpiration))
  static let fakeChallenge = "some_challenge"

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
    "expires_in": (secondsInDay * 60),
    "data_access_expiration_time": dataExpirationDate,
    "state": "{\"challenge\":\"\(fakeChallenge)\"}",
    "graph_domain": "facebook",
    "error": "some_error",
    "error_message": "some_error_message",
  ]

  static var withAccessToken: [String: Any] {
    createParameters(withoutKeys: ["id_token", "nonce", "error", "error_message"])
  }

  static var withAccessTokenWithIDToken: [String: Any] {
    createParameters(withoutKeys: ["nonce", "error", "error_message"])
  }

  static var missingNonce: [String: Any] {
    createParameters(withoutKeys: ["nonce"])
  }

  static var withNonce: [String: Any] {
    createParameters(withoutKeys: ["id_token", "access_token", "error", "error_message"])
  }

  static var withIDToken: [String: Any] {
    createParameters(withoutKeys: ["access_token", "nonce", "error", "error_message"])
  }

  static var withoutAccessTokenWithoutIDTokenWithoutNonce: [String: Any] {
    createParameters(withoutKeys: ["id_token", "access_token", "nonce", "error", "error_message"])
  }

  static var withEmptyAccessTokenWithEmptyIDTokenWithEmptyNonce: [String: Any] {
    var parameters = createParameters(withoutKeys: ["error", "error_message"])
    parameters["access_token"] = ""
    parameters["id_token"] = ""
    parameters["nonce"] = ""

    return parameters
  }

  static var withStringExpirations: [String: Any] {
    var parameters = createParameters(withoutKeys: ["error", "error_message"])
    parameters["expires"] = defaultParameters["expires"] as? String
    parameters["expires_at"] = defaultParameters["expires_at"] as? String
    parameters["expires_in"] = defaultParameters["expires_in"] as? String
    parameters["data_access_expiration_time"] = defaultParameters["data_access_expiration_time"] as? String
    return parameters
  }

  static var withError: [String: Any] {
    createParameters(withoutKeys: ["id_token", "access_token", "nonce"])
  }

  static func createParameters(withoutKeys keys: [String]) -> [String: Any] {
    var parameters = defaultParameters
    keys.forEach { key in
      parameters.removeValue(forKey: key)
    }
    return parameters
  }
}
