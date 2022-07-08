/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

final class LoginManagerLogger {
  var identifier: String?
  var extras = [String: Any]()
  var lastResult = ""
  var lastError: NSError?
  var authMethod: String?
  var loggingToken: String?

  private enum ClientStateKeys {
    static let state = "state"
    static let isClientState = "com.facebook.sdk_client_state"
  }

  private enum LoggerParameterKeys {
    static let identifier = AppEvents.ParameterName("0_auth_logger_id")
    static let timestamp = AppEvents.ParameterName("1_timestamp_ms")
    static let result = AppEvents.ParameterName("2_result")
    static let authMethod = AppEvents.ParameterName("3_method")
    static let errorCode = AppEvents.ParameterName("4_error_code")
    static let errorMessage = AppEvents.ParameterName("5_error_message")
    static let extras = AppEvents.ParameterName("6_extras")
    static let loggingToken = AppEvents.ParameterName("7_logging_token")
    static let declinedPermissions = AppEvents.ParameterName("declined_permissions")
  }

  private enum ErrorParameterKeys {
    static let errorMessage = "error_message"
    static let innerErrorMessage = "inner_error_message"
    static let errorLocalizedDescription = "com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"
    static let graphRequestErrorCode = "com.facebook.sdk:FBSDKGraphRequestErrorGraphErrorCodeKey"
  }

  private enum ErrorDomains: String {
    case core = "com.facebook.sdk.core"
    case login = "com.facebook.sdk.login"
  }

  private enum LoggerResult: String {
    case success
    case cancel = "cancelled"
    case error
  }

  convenience init?(parameters: [String: Any]?, tracking: LoginTracking) {
    guard
      let parameters = parameters,
      let clientStateString = parameters[ClientStateKeys.state] as? String,
      let clientStateData = clientStateString.data(using: .utf8),
      let clientState = try? JSONSerialization.jsonObject(with: clientStateData) as? [String: Any],
      clientState[ClientStateKeys.isClientState] as? Bool == true
    else { return nil }

    self.init(loggingToken: nil, tracking: tracking)

    identifier = clientState[LoggerParameterKeys.identifier.rawValue] as? String
    authMethod = clientState[LoggerParameterKeys.authMethod.rawValue] as? String
    loggingToken = clientState[LoggerParameterKeys.loggingToken.rawValue] as? String
  }

  init?(loggingToken: String?, tracking: LoginTracking) {

    switch tracking {
    case .enabled:
      break
    case .limited:
      return nil
    }

    identifier = UUID().uuidString
    self.loggingToken = loggingToken
  }

  func startSession(for loginManager: LoginManager) {
    let isReauthorize = AccessToken.current != nil
    let willTryNative = false
    let willTryBrowser = true
    let behaviorString = "FBSDKLoginBehaviorBrowser"
    let audience = LoginUtility.stringForAudience(loginManager.defaultAudience)

    var permissionsString = ""
    if let permissions = loginManager.requestedPermissions {
      permissionsString = permissions.reduce("") { result, permission in
        result + (result.isEmpty ? "" : ",") + "\(permission.value)"
      }
    }

    let sessionParameters: [String: Any] = [
      "tryFBAppAuth": willTryNative,
      "trySafariAuth": willTryBrowser,
      "isReauthorize": isReauthorize,
      "login_behavior": behaviorString,
      "default_audience": audience,
      "permissions": permissionsString,
    ]

    extras = extras.merging(sessionParameters) { _, last in last }

    logEvent(.sessionAuthStart, params: parametersForNewEvent())
  }

  func endSession() {
    logEvent(.sessionAuthEnd, result: lastResult, error: lastError)

    if let eventLogger = Self.eventLogger,
       eventLogger.flushBehavior != .explicitOnly {
      eventLogger.flush()
    }
  }

  func start(authenticationMethod: String) {
    authMethod = authenticationMethod
    logEvent(.sessionAuthMethodStart, params: parametersForNewEvent())
  }

  func endLogin(result: LoginManagerLoginResult?, error: NSError?) {
    var resultString = ""

    if error != nil {
      resultString = LoggerResult.error.rawValue
    } else if let isCancelled = result?.isCancelled, isCancelled {
      resultString = LoggerResult.cancel.rawValue
    } else if result?.token != nil {
      resultString = LoggerResult.success.rawValue

      if let declinedPermissions = result?.declinedPermissions,
         !declinedPermissions.isEmpty {
        let declinedPermissionsString = declinedPermissions.reduce("") { result, permission in
          result + (result.isEmpty ? "" : ",") + permission
        }
        extras[LoggerParameterKeys.declinedPermissions.rawValue] = declinedPermissionsString
      }
    }

    lastResult = resultString
    lastError = error

    if let loggingExtras = result?.loggingExtras {
      extras = extras.merging(loggingExtras) { _, last in last }
    }

    logEvent(.sessionAuthMethodEnd, result: resultString, error: error)
  }

  func postLoginHeartbeat() {
    Timer.scheduledTimer(
      timeInterval: 5.0,
      target: self,
      selector: #selector(heartbeatTimerDidFire),
      userInfo: nil,
      repeats: false
    )
  }

  @objc
  func heartbeatTimerDidFire() {
    logEvent(.sessionAuthHeartbeat, result: lastResult, error: lastError)
  }

  func willAttemptAppSwitchingBehavior(urlScheme: String) {
    let isURLSchemeRegistered = InternalUtility.shared.isRegisteredURLScheme(urlScheme)
    let isFacebookAppCanOpenURLSchemeRegistered = InternalUtility.shared.isRegisteredCanOpenURLScheme(
      URLScheme.facebookAPI.rawValue
    )
    let isMessengerAppCanOpenURLSchemeRegistered = InternalUtility.shared.isRegisteredCanOpenURLScheme(
      URLScheme.messengerApp.rawValue
    )

    let urlSchemeParameters: [String: Bool] = [
      "isURLSchemeRegistered": isURLSchemeRegistered,
      "isFacebookAppCanOpenURLSchemeRegistered": isFacebookAppCanOpenURLSchemeRegistered,
      "isMessengerAppCanOpenURLSchemeRegistered": isMessengerAppCanOpenURLSchemeRegistered,
    ]

    extras = extras.merging(urlSchemeParameters) { _, last in last }
  }

  static func getClientState(
    authenticationMethod: String?,
    existingState: [String: Any]?,
    logger: LoginManagerLogger?
  ) -> String? {

    var clientState: [String: Any] = [
      LoggerParameterKeys.authMethod.rawValue: authenticationMethod ?? "",
      LoggerParameterKeys.identifier.rawValue: logger?.identifier ?? UUID().uuidString,
      ClientStateKeys.isClientState: true,
    ]

    if let existingState = existingState {
      var mutableState = clientState
      mutableState = mutableState.merging(existingState) { _, last in last }
      clientState = mutableState
    }

    guard
      let clientStateData = try? JSONSerialization.data(withJSONObject: clientState),
      let clientStateJSONString = String(data: clientStateData, encoding: .utf8)
    else {
      return nil
    }

    return clientStateJSONString
  }

  func parametersForNewEvent() -> [AppEvents.ParameterName: Any] {
    var eventParameters = [AppEvents.ParameterName: Any]()

    // NOTE: We ALWAYS add all params to each event, to ensure predictable mapping on the backend.
    eventParameters[LoggerParameterKeys.identifier] = identifier ?? ""
    eventParameters[LoggerParameterKeys.timestamp] = round(1000 * Date().timeIntervalSince1970)
    eventParameters[LoggerParameterKeys.result] = ""
    eventParameters[LoggerParameterKeys.authMethod] = authMethod
    eventParameters[LoggerParameterKeys.errorCode] = ""
    eventParameters[LoggerParameterKeys.errorMessage] = ""
    eventParameters[LoggerParameterKeys.extras] = ""
    eventParameters[LoggerParameterKeys.loggingToken] = loggingToken ?? ""

    return eventParameters
  }

  func logEvent(_ eventName: AppEvents.Name, params: [AppEvents.ParameterName: Any]?) {
    guard identifier != nil else { return }

    var parameters = params
    if let extrasData = try? JSONSerialization.data(withJSONObject: extras),
       let extrasJSONString = String(data: extrasData, encoding: .utf8),
       var mutableParams = parameters {
      mutableParams[LoggerParameterKeys.extras] = extrasJSONString
      parameters = mutableParams
    }

    extras.removeAll()
    Self.eventLogger?.logInternalEvent(eventName, parameters: parameters, isImplicitlyLogged: true)
  }

  func logEvent(_ eventName: AppEvents.Name, result: String, error: NSError?) {
    var params = parametersForNewEvent()
    params[LoggerParameterKeys.result] = result

    if let error = error,
       error.domain == ErrorDomains.core.rawValue ||
       error.domain == ErrorDomains.login.rawValue {
      // tease apart the structure.

      // first see if there is an explicit message in the error's userInfo. If not, default to the reason,
      // which is less useful.
      var errorMessage = error.userInfo[ErrorParameterKeys.errorMessage] ?? error.userInfo[
        ErrorParameterKeys.errorLocalizedDescription
      ]
      params[LoggerParameterKeys.errorMessage] = errorMessage

      errorMessage = error.userInfo[ErrorParameterKeys.graphRequestErrorCode] ?? "\(error.code)"
      params[LoggerParameterKeys.errorCode] = errorMessage

      if let innerError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
        errorMessage = innerError.userInfo[
          ErrorParameterKeys.errorMessage
        ] ?? innerError.userInfo[NSLocalizedDescriptionKey]
        extras[ErrorParameterKeys.innerErrorMessage] = errorMessage

        errorMessage = innerError.userInfo[
          ErrorParameterKeys.graphRequestErrorCode
        ] ?? "\(innerError.code)"

        extras[ErrorParameterKeys.innerErrorMessage] = errorMessage
      }
    } else if let error = error {
      params[LoggerParameterKeys.errorCode] = error.code
      params[LoggerParameterKeys.errorMessage] = error.localizedDescription
    }

    logEvent(eventName, params: params)
  }
}

extension LoginManagerLogger: DependentAsType {
  struct TypeDependencies {
    var eventLogger: LoginEventLogging
  }

  static var defaultDependencies: TypeDependencies? = TypeDependencies(eventLogger: AppEvents.shared)

  static var configuredDependencies: TypeDependencies?
}

#endif
