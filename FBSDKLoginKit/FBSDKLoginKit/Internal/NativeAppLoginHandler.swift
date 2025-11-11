/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import UIKit

/// Handles native Facebook app login flow
internal final class NativeAppLoginHandler {

  private let loginManager: LoginManager
  private let configuration: LoginConfiguration
  private let defaultAudience: DefaultAudience
  private let logger: LoginManagerLogger?

  internal init(
    loginManager: LoginManager,
    configuration: LoginConfiguration,
    defaultAudience: DefaultAudience,
    logger: LoginManagerLogger?
  ) {
    self.loginManager = loginManager
    self.configuration = configuration
    self.defaultAudience = defaultAudience
    self.logger = logger
  }

  /// Determines if native app login should be attempted
  func shouldAttemptNativeAppLogin() -> Bool {
    guard let dependencies = try? loginManager.getDependencies() else {
      return false
    }

    // Check if app switch is enabled by the app (opt-in model)
    guard configuration.appSwitch == .enabled else {
      return false
    }

    // Only attempt native app login for enabled tracking
    // Limited tracking users must use browser for privacy compliance
    guard configuration.tracking == .enabled else {
      return false
    }

    // Limited login shim requests should not use fast app switch
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled(), !Settings.shared.isAdvertiserTrackingEnabled {
      return false
    }

    // Check if Facebook app is installed using fbapi scheme
    guard dependencies.internalUtility.isFacebookAppInstalled else {
      return false
    }

    // Also verify fbauth2 scheme can be opened (needed for native login flow)
    let fbauth2URL = URL(string: "fbauth2://")!
    guard UIApplication.shared.canOpenURL(fbauth2URL) else {
      return false
    }

    return true
  }

  /// Performs native Facebook app login
  func performNativeAppLogin(
    loggingToken: String?,
    handler: @escaping (Bool, Error?) -> Void
  ) {
    guard let dependencies = try? loginManager.getDependencies() else {
      handler(false, nil)
      return
    }

    // Build Facebook app authentication URL
    guard let nativeAppURL = buildNativeAppLoginURL(
      dependencies: dependencies,
      loggingToken: loggingToken
    ) else {
      handler(false, nil)
      return
    }

    logger?.start(authenticationMethod: "native_app_auth")

    // Open Facebook app for authentication
    dependencies.urlOpener.open(nativeAppURL, sender: loginManager) { didOpen, error in
      // The handler is called to report whether the URL was successfully opened
      // The actual login result will be delivered via LoginManager's URL callback handler
      handler(didOpen, error)
    }
  }

  /// Builds the URL for native Facebook app authentication
  private func buildNativeAppLoginURL(
    dependencies: LoginManager.ObjectDependencies,
    loggingToken: String?
  ) -> URL? {
    // Use LoginManager's normal parameter builder for consistency
    guard let parameters = loginManager.logInParameters(
      configuration: configuration,
      loggingToken: loggingToken,
      authenticationMethod: "native_app_auth"
    ) else {
      return nil
    }

    // Build Facebook app URL scheme (fbauth2://authorize)
    var components = URLComponents()
    components.scheme = "fbauth2"
    components.host = "authorize"

    // Add query parameters
    var queryItems: [URLQueryItem] = []
    for (key, value) in parameters {
      queryItems.append(URLQueryItem(name: key, value: value))
    }
    components.queryItems = queryItems

    return components.url
  }
}
