/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// TODO: Define login results with custom type
/// Login Result Block
public typealias LoginCompletion = (Result<String, Error>) -> Void

enum LoginError: Error {
  case invalidIncomingURL
}

/// Provides methods for logging the user in and out.
public struct MetaLogin {

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? {
    .init(
      urlOpener: AuthWebView(),
      localStorage: LocalStorage()
    )
  }

  static let redirectURI: String = "fbconnect://success"

  /// represents login information including both user and authentication data
  public var userSession: UserSession? {
    guard let dependencies = try? getDependencies() else { return nil }

    do {
      return try dependencies.localStorage.getUserSession()
    } catch LocalStorageError.itemNotFound {
      return nil
    } catch {
      // TODO: error logging
      print("Failed to get UserSession with \(error)")
      return nil
    }
  }

  public init() {}

  /**
   Logs the user in or authorizes additional permissions.
   - Parameter configuration: The login configuration to use. If not explicitly set, the default
   configuration will be used
   - Parameter param: completion the login completion handler.
   */
  public func logIn(
    configuration: LoginConfiguration,
    completion: @escaping LoginCompletion
  ) {
    guard let dependencies = try? getDependencies() else { return }

    let parameters = makeLoginParameters(configuration: configuration)
    guard let url = getUniversalLoginURL(parameters: parameters) else { return }

    dependencies.urlOpener.openURL(
      url: url,
      callbackURLScheme: "fbconnect"
    ) { result in
      switch result {
      case let .success(url):
        if isValidAuthenticationURL(url: url) {
          _ = LoginResponseURLParser().parseURL(url: url)
          return completion(.success("Login response parser was called"))
        } else {
          return completion(.failure(LoginError.invalidIncomingURL))
        }
      case let .failure(error):
        return completion(.failure(error))
      }
    }
  }

  /**
   Logs the user out

   This deletes the `UserSession` instance.

   @note This is only a client side logout. It will not log the user out of their Facebook/Meta account.
   */
  public func logOut() {
    guard var dependencies = try? getDependencies() else { return }

    do {
      try dependencies.localStorage.deleteUserSession()
      dependencies.localStorage.authenticationSessionState = .none
    } catch {
      // TODO: error logging
      print("Failed to logout with \(error)")
    }
  }

  func makeLoginParameters(
    configuration: LoginConfiguration
  ) -> [String: String] {
    let cbtInMilliseconds = round(1000 * Date().timeIntervalSince1970)
    var parameters: [String: String] = [
      "app_id": configuration.facebookAppID,
      "display": "touch",
      "sdk": "meta_sdk_ios",
      "return_scopes": "true",
      "cbt": String(cbtInMilliseconds),
      "response_type": "token,graph_domain,signed_request",
    ]

    let permissions = configuration.permissions
    parameters["scope"] = permissions.map(\.rawValue).joined(separator: ",")
    parameters["redirect_uri"] = MetaLogin.redirectURI

    return parameters
  }

  private func getUniversalLoginURL(parameters: [String: String]) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "figowa.com"
    components.path = "/oauth/accounts"
    components.queryItems = parameters.map {
      URLQueryItem(name: $0, value: $1)
    }

    return components.url
  }

  func isValidAuthenticationURL(url: URL) -> Bool {
    guard
      let scheme = url.scheme,
      let host = url.host,
      let redirectURL = URL(string: MetaLogin.redirectURI)
    else { return false }

    return scheme == redirectURL.scheme && host == redirectURL.host
  }
}

extension MetaLogin: DependentAsInstance {
  struct InstanceDependencies {
    var urlOpener: AuthenticationSessionWebView
    var localStorage: UserSessionPersisting & AuthenticationSessionStatePersisting
  }
}
