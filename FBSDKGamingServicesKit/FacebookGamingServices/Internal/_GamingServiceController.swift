/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
@objc(FBSDKGamingServiceController)
public class _GamingServiceController: NSObject {

  private let serviceType: _GamingServiceType
  private var completionHandler: GamingServiceResultCompletion?
  private let pendingResult: [String: Any]
  private let urlOpener: URLOpener
  private let settings: SettingsProtocol

  public convenience init(
    serviceType: _GamingServiceType,
    pendingResult: [String: Any],
    completionHandler completion: @escaping GamingServiceResultCompletion
  ) {
    self.init(
      serviceType: serviceType,
      pendingResult: pendingResult,
      urlOpener: BridgeAPI.shared,
      settings: Settings.shared,
      completionHandler: completion
    )
  }

  init(
    serviceType: _GamingServiceType,
    pendingResult: [String: Any],
    urlOpener: URLOpener,
    settings: SettingsProtocol,
    completionHandler completion: @escaping GamingServiceResultCompletion
  ) {
    self.serviceType = serviceType
    self.completionHandler = completion
    self.pendingResult = pendingResult
    self.urlOpener = urlOpener
    self.settings = settings
  }

  func handleBridgeAPIError(_ error: Error?) {
    completionHandler?(
      false,
      nil,
      SDKError.error(
        withCode: CoreError.errorBridgeAPIInterruption.rawValue,
        message: "\(error != nil ? "Error" : "An unknown error") occured while interacting with Gaming Services",
        underlyingError: error
      )
    )

    self.completionHandler = nil
  }

  func isValidCallbackURL(_ url: URL, forService service: String) -> Bool {
    // verify the URL is intended as a callback for the SDK's friend finder
    guard let appID = settings.appID, let scheme = url.scheme else { return false }
    return scheme.hasPrefix("fb\(appID)") && url.host == service
  }
}

extension _GamingServiceController: _GamingServiceControllerProtocol {
  public func call(withArgument argument: String?) {
    guard
      let argument = argument,
      let url = URL(string: "https://fb.gg/me/\(serviceType.urlPath)/\(argument)")
    else {
      return
    }

    urlOpener.open(url, sender: self) { [weak self] success, error in
      guard !success else { return }
      self?.handleBridgeAPIError(error)
    }
  }
}

extension _GamingServiceController: URLOpening {
  public func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    guard let url = url else { return false }

    let isGamingUrl = canOpen(
      url,
      for: application,
      sourceApplication: sourceApplication,
      annotation: annotation
    )

    if let completionHandler = completionHandler, isGamingUrl {
      completionHandler(true, pendingResult, nil)
      self.completionHandler = nil
    }

    return isGamingUrl
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    isValidCallbackURL(url, forService: serviceType.urlPath)
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    completionHandler?(true, pendingResult, nil)
    completionHandler = nil
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    false
  }
}
