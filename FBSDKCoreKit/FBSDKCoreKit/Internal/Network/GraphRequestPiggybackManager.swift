/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class GraphRequestPiggybackManager: _GraphRequestPiggybackManaging {

  private struct AggregatePermissions {
    var granted = Set<Permission>()
    var declined = Set<Permission>()
    var expired = Set<Permission>()
  }

  private enum Keys {
    static let data = "data"
    static let accessToken = "access_token"
    static let accessTokenPath = "oauth/access_token"
    static let grantType = "grant_type"
    static let fields = "fields"
    static let clientId = "client_id"
    static let expiresAt = "expires_at"
    static let dataAccessExpirationTime = "data_access_expiration_time"
    static let permission = "permission"
    static let status = "status"
    static let granted = "granted"
    static let declined = "declined"
    static let expired = "expired"
  }

  enum Values {
    static let tokenRefreshThresholdInSeconds: TimeInterval = 24 * 60 * 60 // one day
    static let tokenRefreshRetryInSeconds: TimeInterval = 60 * 60 // one hour
    static let extendSSOToken = "fb_extend_sso_token"
    static let accessTokenRefreshFields = ""
    static let permissionsPath = "me/permissions"
    static let permissionsRefreshFields = ""
  }

  var lastRefreshTry = Date.distantPast

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    tokenWallet: AccessToken.self,
    settings: Settings.shared,
    serverConfigurationProvider: _ServerConfigurationManager.shared,
    graphRequestFactory: GraphRequestFactory()
  )

  func addPiggybackRequests(_ connection: GraphRequestConnecting) {
    guard
      let dependencies = try? getDependencies(),
      let appID = dependencies.settings.appID,
      !appID.isEmpty
    else {
      return
    }

    // There's a circular dependency with GraphRequestConnecting and GraphRequestMetadata
    // that prevents the type from being available correctly due to forward declaration.
    // This will go away once everything is in Swift but for now we can just cast it.
    let isSafeForPiggyback = connection.requests.allSatisfy { metaData in
      guard let request = (metaData as? GraphRequestMetadata)?.request else {
        return false
      }

      return isRequestSafeForPiggyback(request)
    }

    if isSafeForPiggyback {
      addRefreshPiggybackIfStale(to: connection)
      addServerConfigurationPiggyback(to: connection)
    }
  }

  func addRefreshPiggyback(
    _ connection: GraphRequestConnecting,
    permissionHandler: GraphRequestCompletion?
  ) {
    guard
      let dependencies = try? getDependencies(),
      let expectedToken = dependencies.tokenWallet.current else { return }

    var permissions = AggregatePermissions(
      granted: expectedToken.permissions,
      declined: expectedToken.declinedPermissions,
      expired: expectedToken.expiredPermissions
    )
    var tokenString: String?
    var expirationDateNumber: NSNumber?
    var dataAccessExpirationDateNumber: NSNumber?
    var expectingCallbacksCount = 2

    let expectingCallbackComplete = {
      expectingCallbacksCount -= 1
      if expectingCallbacksCount == 0 {
        guard let currentToken = dependencies.tokenWallet.current else {
          return
        }

        var expirationDate = currentToken.expirationDate
        if let expirationDateNumber = expirationDateNumber {
          expirationDate = expirationDateNumber.doubleValue > 0
            ? Date(timeIntervalSince1970: expirationDateNumber.doubleValue)
            : .distantFuture
        }

        var dataExpirationDate = currentToken.dataAccessExpirationDate
        if let dataAccessExpirationDateNumber = dataAccessExpirationDateNumber {
          dataExpirationDate = dataAccessExpirationDateNumber.doubleValue > 0
            ? Date(timeIntervalSince1970: dataAccessExpirationDateNumber.doubleValue)
            : .distantFuture
        }

        let granted = permissions.granted.map(\.name)
        let declined = permissions.declined.map(\.name)
        let expired = permissions.expired.map(\.name)

        let refreshedToken = AccessToken(
          tokenString: tokenString ?? currentToken.tokenString,
          permissions: granted,
          declinedPermissions: declined,
          expiredPermissions: expired,
          appID: currentToken.appID,
          userID: currentToken.userID,
          expirationDate: expirationDate,
          refreshDate: Date(),
          dataAccessExpirationDate: dataExpirationDate
        )

        if expectedToken == currentToken {
          dependencies.tokenWallet.current = refreshedToken
        }
      }
    }

    let extensionRequest = dependencies.graphRequestFactory.createGraphRequest(
      withGraphPath: Keys.accessTokenPath,
      parameters: [
        Keys.grantType: Values.extendSSOToken,
        Keys.fields: Values.accessTokenRefreshFields,
        Keys.clientId: expectedToken.appID,
      ],
      flags: .disableErrorRecovery
    )

    connection.add(extensionRequest) { _, potentialResult, _ in
      defer { expectingCallbackComplete() }

      guard let result = potentialResult as? [String: Any] else {
        return
      }

      tokenString = result[Keys.accessToken] as? String
      expirationDateNumber = result[Keys.expiresAt] as? NSNumber
      dataAccessExpirationDateNumber = result[Keys.dataAccessExpirationTime] as? NSNumber
    }

    let permissionsRequest = dependencies.graphRequestFactory.createGraphRequest(
      withGraphPath: Values.permissionsPath,
      parameters: [Keys.fields: Values.permissionsRefreshFields],
      flags: .disableErrorRecovery
    )

    connection.add(permissionsRequest) { [self] innerConnection, potentialResult, potentialError in
      defer {
        expectingCallbackComplete()
        permissionHandler?(innerConnection, potentialResult, potentialError)
      }

      if let result = potentialResult as? [String: Any] {
        let extractedPermissions = extractPermissions(
          fromResponse: result,
          priorPermissions: permissions
        )
        permissions = extractedPermissions
      } else if potentialError != nil {
        return
      } else {
        permissions = AggregatePermissions()
        return
      }
    }
  }

  private func extractPermissions(
    fromResponse response: [String: Any],
    priorPermissions: AggregatePermissions
  ) -> AggregatePermissions {
    guard let resultData = response[Keys.data] as? [[String: Any]] else {
      return priorPermissions
    }

    var permissions = AggregatePermissions()

    resultData.forEach { permissionsDictionary in
      guard
        let name = permissionsDictionary[Keys.permission] as? String,
        let status = permissionsDictionary[Keys.status] as? String
      else {
        return
      }

      let permission = Permission(stringLiteral: name)
      switch status {
      case Keys.granted: permissions.granted.insert(permission)
      case Keys.declined: permissions.declined.insert(permission)
      case Keys.expired: permissions.expired.insert(permission)
      default: break
      }
    }

    return permissions
  }

  func isRequestSafeForPiggyback(_ request: GraphRequestProtocol) -> Bool {
    guard let dependencies = try? getDependencies() else { return false }

    return (request.version == dependencies.settings.graphAPIVersion) && !request.hasAttachments
  }

  func addRefreshPiggybackIfStale(to connection: GraphRequestConnecting) {
    guard let dependencies = try? getDependencies() else { return }

    // don't piggy back more than once an hour as a cheap way of
    // retrying in cases of errors and preventing duplicate refreshes.
    // obviously this is not foolproof but is simple and sufficient.
    let now = Date()

    guard
      let refreshDate = dependencies.tokenWallet.current?.refreshDate,
      now.timeIntervalSince(lastRefreshTry) > Values.tokenRefreshRetryInSeconds,
      now.timeIntervalSince(refreshDate) > Values.tokenRefreshThresholdInSeconds
    else {
      return
    }

    addRefreshPiggyback(connection, permissionHandler: nil)
    lastRefreshTry = Date()
  }

  func addServerConfigurationPiggyback(to connection: GraphRequestConnecting) {
    guard let dependencies = try? getDependencies() else { return }

    let isDefaults = dependencies.serverConfigurationProvider.cachedServerConfiguration().isDefaults

    // This is bad. The pre-conversion implementation resolved to NaN and then checked if
    // NaN was less than FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT.
    // This resolved to false. The Swift version also needs to default to false.
    var isCacheTimedOut = false
    if let cachedConfigurationTimeStamp = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .timestamp {
      let timeout = TimeInterval(FBSDK_SERVER_CONFIGURATION_MANAGER_CACHE_TIMEOUT)

      isCacheTimedOut = Date().timeIntervalSince(cachedConfigurationTimeStamp) < timeout
    }

    guard
      isDefaults || !isCacheTimedOut,
      let appID = dependencies.settings.appID,
      let request = dependencies.serverConfigurationProvider.request(toLoadServerConfiguration: appID)
    else { return }

    connection.add(request) { _, potentialResult, error in
      guard let result = potentialResult else { return }

      dependencies.serverConfigurationProvider.processLoadRequestResponse(
        result,
        error: error,
        appID: appID
      )
    }
  }
}

extension GraphRequestPiggybackManager: DependentAsObject {
  struct ObjectDependencies {
    let tokenWallet: _AccessTokenProviding.Type
    let settings: SettingsProtocol
    let serverConfigurationProvider: _ServerConfigurationProviding
    let graphRequestFactory: GraphRequestFactoryProtocol
  }
}
