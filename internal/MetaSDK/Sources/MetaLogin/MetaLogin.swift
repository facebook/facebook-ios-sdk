/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public enum LoginResult {
  case cancel
  case success(UserSession)
  case failure(Error)
}

public typealias LoginCompletion = (LoginResult) -> Void

/// Provides methods for logging the user in and out.
public struct MetaLogin {

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    urlOpener: AuthWebView(),
    localStorage: LocalStorage()
  )

  static let redirectURI: String = "fbconnect://success"
  static let callbackURLScheme: String = "fbconnect"

  private enum ParameterKeys {
    static let appID = "app_id"
    static let display = "display"
    static let sdk = "sdk"
    static let returnScopes = "return_scopes"
    static let cbt = "cbt"
    static let responseType = "response_type"
    static let scope = "scope"
    static let redirectURI = "redirect_uri"
  }

  private enum ParameterValues {
    static let display = "touch"
    static let sdk = "meta_sdk_ios"
    static let returnScopes = "true"
    static let responseType = "token,graph_domain,signed_request"
  }

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

    guard let parameters = makeLoginParameters(configuration: configuration),
          let url = getUniversalLoginURL(parameters: parameters)
    else { return completion(.failure(LoginError.invalidURLCreation)) }

    dependencies.urlOpener.openURL(
      url: url,
      callbackURLScheme: "fbconnect"
    ) { result in
      switch result {
      case let .success(url):
        completeLogin(url: url, completion: completion)
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
  ) -> [String: String]? {
    let cbtInMilliseconds = round(1000 * Date().timeIntervalSince1970)
    guard let appID = configuration.facebookAppID
    else { return nil }

    var parameters: [String: String] = [
      ParameterKeys.appID: appID,
      ParameterKeys.display: ParameterValues.display,
      ParameterKeys.sdk: ParameterValues.sdk,
      ParameterKeys.returnScopes: ParameterValues.returnScopes,
      ParameterKeys.cbt: String(cbtInMilliseconds),
      ParameterKeys.responseType: ParameterValues.responseType,
    ]

    let permissions = configuration.permissions
    parameters[ParameterKeys.scope] = permissions.map(\.rawValue).joined(separator: ",")
    parameters[ParameterKeys.redirectURI] = MetaLogin.redirectURI

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

  func completeLogin(url: URL, completion: @escaping LoginCompletion) {
    guard let dependencies = try? getDependencies() else { return }

    let parser = LoginResponseURLParser()
    guard parser.isValidAuthenticationURL(url) else { return completion(.failure(LoginError.invalidIncomingURL)) }
    guard !parser.isCancellationURL(url) else { return completion(.cancel) }

    do {
      let userSession = try LoginResponseURLParser().parse(url: url)
      try dependencies.localStorage.saveUserSession(userSession: userSession)
      return completion(.success(userSession))

    } catch {
      return completion(.failure(error))
    }
  }
}

extension MetaLogin: DependentAsInstance {
  struct InstanceDependencies {
    var urlOpener: AuthenticationSessionWebView
    var localStorage: UserSessionPersisting & AuthenticationSessionStatePersisting
  }
}
