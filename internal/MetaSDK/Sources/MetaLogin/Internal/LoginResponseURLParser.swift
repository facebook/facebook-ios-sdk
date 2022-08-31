/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum LoginError: Error {
  case invalidIncomingURL
  case invalidURLCreation
  case cancelledLogin
  case unhandledError(message: String?)
}

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
    static let error = "error"
    static let errorMessage = "error_message"
  }

  func parse(url: URL) throws -> UserSession {
    var urlString = url.absoluteString
    // Changes url with fragments to url with query items to enable URLComponents parsing
    urlString = urlString.replacingOccurrences(of: "#", with: "?")

    guard
      let components = URLComponents(string: urlString),
      let queryItems = components.queryItems
    else {
      throw LoginError.invalidIncomingURL
    }

    let queryItemsDictionary = queryItems.reduce(into: [String: String]()) { result, item in
      result[item.name] = item.value
    }

    if let error = parseError(from: queryItemsDictionary) {
      throw error
    }

    guard let token = AccessToken(
      tokenString: queryItemsDictionary[Keys.accessToken] ?? "",
      expirationDate: expirationDateFrom(parameters: queryItemsDictionary),
      dataAccessExpirationDate: dataAccessExpirationDateFrom(parameters: queryItemsDictionary)
    ) else {
      // if error is nil and no access token found, then this should be processed as a cancellation
      throw LoginError.cancelledLogin
    }

    guard let signedRequest = queryItemsDictionary[Keys.signedRequest],
          let userID = UserIDExtractor().getUserID(from: signedRequest)
    else {
      throw LoginError.invalidIncomingURL
    }

    var grantedPermissions = Set<Permission>()
    if let grantedScopes = queryItemsDictionary[Keys.grantedScopes],
       !grantedScopes.isEmpty {
      grantedPermissions = Set(
        grantedScopes
          .components(separatedBy: ",")
          .compactMap(Permission.init(rawValue:))
      )
    }

    var declinedPermissions = Set<Permission>()
    if let deniedScopes = queryItemsDictionary[Keys.deniedScopes],
       !deniedScopes.isEmpty {
      declinedPermissions = Set(
        deniedScopes
          .components(separatedBy: ",")
          .compactMap(Permission.init(rawValue:))
      )
    }

    let userSession = UserSession(
      userID: userID,
      graphDomain: GraphDomain(rawValue: queryItemsDictionary[Keys.graphDomain] ?? "") ?? .facebook,
      accessToken: token,
      requestedPermissions: grantedPermissions,
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

  func isValidAuthenticationURL(_ url: URL) -> Bool {
    guard
      let scheme = url.scheme,
      let host = url.host,
      let redirectURL = URL(string: MetaLogin.redirectURI)
    else { return false }

    return scheme == redirectURL.scheme && host == redirectURL.host
  }

  private func parseError(from urlParameters: [String: String]) -> LoginError? {
    guard let errorMsg = urlParameters[Keys.errorMessage] else {
      return nil
    }
    let error = urlParameters[Keys.error] ?? errorMsg
    return LoginError.unhandledError(message: "\(error)")
  }
}
