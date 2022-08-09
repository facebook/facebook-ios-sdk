/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct LoginResponseURLParser {
  enum Keys {
    static let accessToken = "access_token"
    static let grantedScopes = "granted_scopes"
    static let deniedScopes = "denied_scopes"
    static let signedRequest = "signed_request"
    static let expires = "expires"
    static let expiresAt = "expires_at"
    static let expiresIn = "expires_in"
    static let dataAccessExpirationTime = "data_access_expiration_time"
    static let graphDomain = "graph_domain"
  }

  func parseURL(url: URL) -> UserSession? {
    var urlString = url.absoluteString
    // Changes url with fragments to url with query items to enable URLComponents parsing
    urlString = urlString.replacingOccurrences(of: "#", with: "?")

    guard
      let components = URLComponents(string: urlString),
      let queryItems = components.queryItems
    else {
      return nil
    }

    let queryItemsDictionary = queryItems.reduce(into: [String: String]()) { result, item in
      result[item.name] = item.value
    }

    guard let token = AccessToken(
      tokenString: queryItemsDictionary[Keys.accessToken] ?? "",
      expirationDate: expirationDateFrom(parameters: queryItemsDictionary),
      dataAccessExpirationDate: dataAccessExpirationDateFrom(parameters: queryItemsDictionary)
    ),
      let userID = UserIDExtractor().getUserID(from: queryItemsDictionary[Keys.signedRequest] ?? "")
    else {
      return nil
    }

    var permissions: [String] = []
    if let grantedScopes = queryItemsDictionary[Keys.grantedScopes],
       !grantedScopes.isEmpty {
      permissions = grantedScopes.components(separatedBy: ",")
    }

    var declinedPermissions: [String] = []
    if let deniedScopes = queryItemsDictionary[Keys.deniedScopes],
       !deniedScopes.isEmpty {
      declinedPermissions = deniedScopes.components(separatedBy: ",")
    }

    let userSession = UserSession(
      userID: userID,
      graphDomain: GraphDomain(rawValue: queryItemsDictionary[Keys.graphDomain] ?? "") ?? .faceBook,
      accessToken: token,
      requestedPermissions: permissions,
      declinedPermissions: declinedPermissions
    )

    return userSession
  }

  func dataAccessExpirationDateFrom(parameters: [String: String]) -> Date {
    if let dataAccessExpirationDate = Double(parameters[Keys.dataAccessExpirationTime] ?? ""),
       dataAccessExpirationDate > 0 {
      return Date(timeIntervalSince1970: dataAccessExpirationDate)
    }
    return .distantFuture
  }

  func expirationDateFrom(parameters: [String: String]) -> Date {
    let expires = Double(parameters[Keys.expires] ?? "")
    let expiresAt = Double(parameters[Keys.expiresAt] ?? "")
    let expiresIn = Double(parameters[Keys.expiresIn] ?? "")

    let expirationDate = expires ?? expiresAt

    if let expirationDate = expirationDate,
       expirationDate > 0 {
      return Date(timeIntervalSince1970: expirationDate)
    } else if let expiresIn = expiresIn,
              expiresIn > 0 {
      return Date(timeIntervalSinceNow: expiresIn)
    } else {
      return .distantFuture
    }
  }
}
