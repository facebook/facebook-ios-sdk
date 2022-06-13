/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import Foundation

/**
 Use this class to perform a device login flow.
 The device login flow starts by requesting a code from the device login API.
   This class informs the delegate when this code is received. You should then present the
   code to the user to enter. In the meantime, this class polls the device login API
   periodically and informs the delegate of the results.

 See [Facebook Device Login](https://developers.facebook.com/docs/facebook-login/for-devices).
 */
@objcMembers
@objc(FBSDKDeviceLoginManager)
public final class DeviceLoginManager: NSObject {

  private static var loginManagerInstances = [DeviceLoginManager]()

  /// The device login manager delegate.
  public weak var delegate: DeviceLoginManagerDelegate?

  /// The requested permissions.
  public let permissions: [String]

  /**
   The optional URL to redirect the user to after they complete the login.
   The URL must be configured in your App Settings -> Advanced -> OAuth Redirect URIs
   */
  public var redirectURL: URL?

  var codeInfo: DeviceLoginCodeInfo?
  private var isCancelled = false
  private let isSmartLoginEnabled: Bool

  var configuredDependencies: InstanceDependencies?

  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    devicePoller: _DevicePoller(),
    errorFactory: ErrorFactory(),
    graphRequestFactory: GraphRequestFactory(),
    internalUtility: InternalUtility.shared,
    settings: Settings.shared
  )

  /**
   Initializes a new instance.
   @param permissions The permissions to request.
   @param enableSmartLogin Whether to enable smart login.
   */

  @objc(initWithPermissions:enableSmartLogin:)
  public init(permissions: [String], enableSmartLogin: Bool) {
    self.permissions = permissions
    self.isSmartLoginEnabled = enableSmartLogin
    super.init()
  }

  /**
   Starts the device login flow
   This instance will retain self until the flow is finished or cancelled.
   */
  public func start() {
    guard let dependencies = try? getDependencies() else { return }

    dependencies.internalUtility.validateAppID()
    Self.loginManagerInstances.append(self)

    let parameters: [String: Any] = [
      "scope": permissions.joined(separator: ","),
      "redirect_uri": redirectURL?.absoluteString ?? "",
      "device_info": _DeviceRequestsHelper.getDeviceInfo(),
    ]
    let request = dependencies.graphRequestFactory.createGraphRequest(
      withGraphPath: "device/login",
      parameters: parameters,
      tokenString: dependencies.internalUtility.validateRequiredClientAccessToken(),
      httpMethod: .post,
      flags: []
    )
    request.isGraphErrorRecoveryDisabled = true

    request.start { [self] _, anyResult, potentialError in
      if let error = potentialError {
        return processError(error)
      }

      let result = anyResult as? [String: Any]
      let verificationURL = (result?["verification_uri"] as? String)
        .flatMap(URL.init(string:))

      guard
        let url = verificationURL,
        let identifier = result?["code"] as? String,
        let loginCode = result?["user_code"] as? String
      else {
        return notifyDelegate(
          error: dependencies.errorFactory.error(
            code: CoreError.errorUnknown.rawValue,
            message: "Unable to create a login request",
            underlyingError: nil
          )
        )
      }

      let expirationInterval = (result?["expires_in"] as? String)
        .flatMap(TimeInterval.init) ?? 0.0
      let pollingInterval = (result?["interval"] as? NSNumber)?.uintValue ?? 0

      let codeInfo = DeviceLoginCodeInfo(
        identifier: identifier,
        loginCode: loginCode,
        verificationURL: url,
        expirationDate: Date().addingTimeInterval(expirationInterval),
        pollingInterval: pollingInterval
      )
      self.codeInfo = codeInfo

      if isSmartLoginEnabled {
        _DeviceRequestsHelper.startAdvertisementService(loginCode: codeInfo.loginCode, delegate: self)
      }

      delegate?.deviceLoginManager(self, startedWith: codeInfo)
      schedulePoll(interval: codeInfo.pollingInterval)
    }
  }

  /// Attempts to cancel the device login flow.
  public func cancel() {
    _DeviceRequestsHelper.cleanUpAdvertisementService(for: self)
    isCancelled = true
    Self.loginManagerInstances.removeAll { $0 === self }
  }

  private func notifyDelegate(error: Error) {
    _DeviceRequestsHelper.cleanUpAdvertisementService(for: self)
    delegate?.deviceLoginManager(self, completedWith: nil, error: error)
    Self.loginManagerInstances.removeAll { $0 === self }
  }

  func notifyDelegate(
    token tokenString: String?,
    expirationDate: Date?,
    dataAccessExpirationDate: Date?
  ) {
    _DeviceRequestsHelper.cleanUpAdvertisementService(for: self)

    let complete: (DeviceLoginManagerResult) -> Void = { [self] result in
      delegate?.deviceLoginManager(self, completedWith: result, error: nil)
      Self.loginManagerInstances.removeAll { $0 === self }
    }

    guard let tokenString = tokenString else {
      isCancelled = true
      let result = DeviceLoginManagerResult(token: nil, isCancelled: true)
      return complete(result)
    }

    guard let dependencies = try? getDependencies() else { return }

    let request = dependencies.graphRequestFactory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["fields": "id,permissions"],
      tokenString: tokenString,
      httpMethod: .get,
      flags: [.disableErrorRecovery]
    )

    request.start { [self] _, anyResult, potentialError in
      guard
        potentialError == nil,
        let graphResult = anyResult as? [String: Any],
        let userID = graphResult["id"] as? String,
        let permissionResult = graphResult["permissions"] as? [String: Any]
      else {
        return notifyDelegate(
          error: dependencies.errorFactory.error(
            domain: LoginErrorDomain,
            code: CoreError.errorUnknown.rawValue,
            userInfo: nil,
            message: "Unable to fetch permissions for token",
            underlyingError: potentialError
          )
        )
      }

      let permissions = NSMutableSet()
      let declinedPermissions = NSMutableSet()
      let expiredPermissions = NSMutableSet()

      dependencies.internalUtility.extractPermissions(
        fromResponse: permissionResult,
        grantedPermissions: permissions,
        declinedPermissions: declinedPermissions,
        expiredPermissions: expiredPermissions
      )
      let accessToken = AccessToken(
        tokenString: tokenString,
        permissions: permissions.compactMap { $0 as? String },
        declinedPermissions: declinedPermissions.compactMap { $0 as? String },
        expiredPermissions: expiredPermissions.compactMap { $0 as? String },
        appID: dependencies.settings.appID ?? "",
        userID: userID,
        expirationDate: expirationDate,
        refreshDate: nil,
        dataAccessExpirationDate: dataAccessExpirationDate
      )
      let result = DeviceLoginManagerResult(token: accessToken, isCancelled: false)
      AccessToken.current = accessToken
      complete(result)
    }
  }

  func processError(_ error: Error) {
    let nsError = error as NSError
    let code = (nsError.userInfo[GraphRequestErrorGraphErrorSubcodeKey] as? Int)
      .flatMap(DeviceLoginError.Code.init(rawValue:))

    switch (code, codeInfo) {
    case let (.authorizationPending, info?):
      schedulePoll(interval: info.pollingInterval)
    case (.codeExpired, _), (.authorizationDeclined, _):
      notifyDelegate(token: nil, expirationDate: nil, dataAccessExpirationDate: nil)
    case let (.excessivePolling, info?):
      schedulePoll(interval: info.pollingInterval * 2)
    default:
      notifyDelegate(error: error)
    }
  }

  func schedulePoll(interval: UInt) {
    guard let dependencies = try? getDependencies() else { return }

    dependencies.devicePoller.schedule(interval: interval) { [self] in
      guard !isCancelled else { return }

      let parameters: [String: Any] = ["code": codeInfo?.identifier ?? NSNull()]
      let request = dependencies.graphRequestFactory.createGraphRequest(
        withGraphPath: "device/login_status",
        parameters: parameters,
        tokenString: dependencies.internalUtility.validateRequiredClientAccessToken(),
        httpMethod: .post,
        flags: []
      )
      request.isGraphErrorRecoveryDisabled = true

      request.start { [self] _, anyResult, potentialError in
        guard !isCancelled else { return }

        if let error = potentialError {
          processError(error)
        } else {
          let result = anyResult as? [String: Any]
          let tokenString = result?["access_token"] as? String
          var expirationDate = Date.distantFuture
          let expirationInterval = (result?["expires_in"] as? String).flatMap(Int.init) ?? 0
          if expirationInterval > 0 {
            expirationDate = Date(timeIntervalSinceNow: TimeInterval(expirationInterval))
          }

          var dataAccessExpirationDate = NSDate.distantFuture
          let dataAccessExpirationTime = (result?["data_access_expiration_time"] as? String).flatMap(Int.init) ?? 0
          if dataAccessExpirationTime > 0 {
            dataAccessExpirationDate = Date(timeIntervalSince1970: TimeInterval(dataAccessExpirationTime))
          }

          if let tokenString = tokenString {
            notifyDelegate(
              token: tokenString,
              expirationDate: expirationDate,
              dataAccessExpirationDate: dataAccessExpirationDate
            )
          } else {
            notifyDelegate(
              error: dependencies.errorFactory.error(
                domain: LoginErrorDomain,
                code: CoreError.errorUnknown.rawValue,
                userInfo: nil,
                message: "Device Login poll failed. No token or error was found.",
                underlyingError: nil
              )
            )
          }
        }
      }
    }
  }
}

extension DeviceLoginManager: NetServiceDelegate {
  public func netService(_ service: NetService, didNotPublish errorValues: [String: NSNumber]) {
    // Only cleanup if the publish error is from our advertising service
    guard _DeviceRequestsHelper.isDelegate(self, forAdvertisementService: service) else { return }

    _DeviceRequestsHelper.cleanUpAdvertisementService(for: self)
  }
}

extension DeviceLoginManager: DependentAsInstance {
  struct InstanceDependencies {
    var devicePoller: DevicePolling
    var errorFactory: ErrorCreating
    var graphRequestFactory: GraphRequestFactoryProtocol
    var internalUtility: InternalUtilityProtocol
    var settings: SettingsProtocol
  }
}
