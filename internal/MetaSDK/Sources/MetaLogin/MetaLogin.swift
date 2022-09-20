/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Provides methods for logging the user in and out.
public struct MetaLogin {

  var configuredDependencies: InstanceDependencies?
  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    webAuthenticator: AppleWebAuthenticator(),
    userSessionStore: UserSessionStore()
  )

  static let redirectURI: String = "fbconnect://success"
  static let callbackURLScheme = "fbconnect"

  private enum ParameterKeys {
    static let fbAppID = "fb_app_id"
    static let metaAppID = "meta_app_id"
    static let display = "display"
    static let sdk = "sdk"
    static let returnScopes = "return_scopes"
    static let cbt = "cbt"
    static let responseType = "response_type"
    static let scope = "scope"
    static let redirectURI = "redirect_uri"
    static let authType = "auth_type"
    static let tokenType = "token_type"
  }

  private enum ParameterValues {
    static let display = "touch"
    static let sdk = "meta_sdk_ios"
    static let returnScopes = "true"
    static let responseType = "token,graph_domain,signed_request"
    static let rerequest = "rerequest"
  }

  /// Login information including both user and authentication data.
  public var userSession: UserSession? {
    get async {
      guard let userSessionStore = try? getDependencies().userSessionStore else { return nil }

      do {
        return try await userSessionStore.getUserSession()
      } catch LocalStorageError.itemNotFound {
        return nil
      } catch {
        // TODO: error logging
        print("Failed to get UserSession with \(error)")
        return nil
      }
    }
  }

  public init() {}

  /**
   Logs the user in or authorizes additional permissions.

   - Parameter configuration: The login configuration to use. If not explicitly set, the default
   configuration will be used.
   */
  @discardableResult
  public func logIn(configuration: LoginConfiguration = LoginConfiguration()) async throws -> UserSession {
    let authenticator = try getDependenciesWithLoginFailure().webAuthenticator

    let url: URL
    do {
      url = try await createUniversalLoginURL(
        from: try getLoginParameters(from: configuration)
      )
    } catch {
      throw LoginFailure.internal(error)
    }

    let response = try await authenticator.authenticate(
      parameters: WebAuthenticationParameters(
        url: url,
        callbackScheme: Self.callbackURLScheme
      )
    )

    return try await completeLogin(with: response)
  }

  /**
   Logs the user out

   This deletes the `UserSession` instance.

   @note This is only a client side logout. It will not log the user out of their Facebook/Meta account.
   */
  public func logOut() async {
    guard let dependencies = try? getDependencies() else { return }

    do {
      try await dependencies.userSessionStore.deleteUserSession()
    } catch {
      // TODO: error logging
      print("Failed to logout with \(error)")
    }
  }

  enum LoginURLError: Error {
    case missingApplicationIdentifier
    case invalidComponents
    case invalidResponse
  }

  func getLoginParameters(from configuration: LoginConfiguration) async throws -> [String: String] {
    guard
      let fbAppID = configuration.facebookAppID,
      let metaAppID = configuration.metaAppID
    else { throw LoginURLError.missingApplicationIdentifier }

    let cbtInMilliseconds = round(1000 * Date().timeIntervalSince1970)

    var parameters: [String: String] = [
      ParameterKeys.fbAppID: fbAppID,
      ParameterKeys.metaAppID: metaAppID,
      ParameterKeys.display: ParameterValues.display,
      ParameterKeys.sdk: ParameterValues.sdk,
      ParameterKeys.returnScopes: ParameterValues.returnScopes,
      ParameterKeys.cbt: String(cbtInMilliseconds),
      ParameterKeys.responseType: ParameterValues.responseType,
      ParameterKeys.authType: ParameterValues.rerequest,
    ]

    if let session = await userSession {
      parameters[ParameterKeys.tokenType] = session.graphDomain.rawValue
    }

    let permissions = configuration.permissions
    parameters[ParameterKeys.scope] = permissions.map(\.rawValue).joined(separator: ",")
    parameters[ParameterKeys.redirectURI] = Self.redirectURI

    return parameters
  }

  private func createUniversalLoginURL(from parameters: [String: String]) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "facebook.com"
    components.path = "/oauth/universal_login"
    components.queryItems = parameters.map {
      URLQueryItem(name: $0, value: $1)
    }

    guard let url = components.url else {
      throw LoginURLError.invalidComponents
    }

    return url
  }

  func completeLogin(with url: URL) async throws -> UserSession {
    let userSessionStore: UserSessionPersisting
    do {
      userSessionStore = try getDependencies().userSessionStore
    } catch {
      throw LoginFailure.internal(error)
    }

    let parser = LoginResponseURLParser()
    guard parser.isValidAuthenticationURL(url) else {
      throw LoginFailure.internal(LoginURLError.invalidResponse)
    }

    do {
      let userSession = try parser.parse(url: url)
      try await userSessionStore.saveUserSession(userSession)
      return userSession
    } catch LoginResponseURLParser.Error.isCanceled {
      throw LoginFailure.isCanceled
    } catch {
      throw LoginFailure.internal(error)
    }
  }
}

extension MetaLogin: DependentAsInstance {
  struct InstanceDependencies {
    var webAuthenticator: WebAuthenticating
    var userSessionStore: UserSessionPersisting
  }

  func getDependenciesWithLoginFailure() throws -> InstanceDependencies {
    do {
      return try getDependencies()
    } catch {
      throw LoginFailure.internal(error)
    }
  }
}
