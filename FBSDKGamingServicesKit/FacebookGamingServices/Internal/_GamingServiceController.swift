/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

let kServiceTypeStringFriendFinder = "friendfinder"
let kServiceTypeStringMediaAsset = "media_asset"
let kServiceTypeStringCommunity = "community"

private func FBSDKGamingServiceTypeString(_ type: _GamingServiceType) -> String {
  switch type {
  case .friendFinder:
    return kServiceTypeStringFriendFinder
  case .mediaAsset:
    return kServiceTypeStringMediaAsset
  case .community:
    return kServiceTypeStringCommunity
  }
}

private func FBSDKGamingServicesUrl(_ serviceType: _GamingServiceType, _ argument: String) -> URL {
  let serviceTypeString = FBSDKGamingServiceTypeString(serviceType)
  return URL(string: "https://fb.gg/me/\(serviceTypeString)/\(argument)")! // swiftlint:disable:this force_unwrapping
}

@objcMembers
@objc(FBSDKGamingServiceController) // swiftlint:disable:next type_name
public class _GamingServiceController: NSObject, _GamingServiceControllerProtocol, URLOpening {

  private let serviceType: _GamingServiceType
  private var completionHandler: GamingServiceResultCompletion?
  private let pendingResult: Any
  private let urlOpener: URLOpener
  private let settings: SettingsProtocol

  public convenience init(
    serviceType: _GamingServiceType,
    completionHandler completion: @escaping GamingServiceResultCompletion,
    pendingResult: Any
  ) {
    self.init(
      serviceType: serviceType,
      completionHandler: completion,
      pendingResult: pendingResult,
      urlOpener: BridgeAPI.shared,
      settings: Settings.shared
    )
  }

  init(
    serviceType: _GamingServiceType,
    completionHandler completion: @escaping GamingServiceResultCompletion,
    pendingResult: Any,
    urlOpener: URLOpener,
    settings: SettingsProtocol
  ) {
    self.serviceType = serviceType
    self.completionHandler = completion
    self.pendingResult = pendingResult
    self.urlOpener = urlOpener
    self.settings = settings
  }

  public func call(withArgument argument: String?) {
    guard let argument = argument else { return }
    let url = FBSDKGamingServicesUrl(serviceType, argument)
    urlOpener.open(url, sender: self) { [weak self] success, error in
      if !success {
        self?.handleBridgeAPIError(error)
      }
    }
  }

  func handleBridgeAPIError(_ error: Error?) {
    guard let completionHandler = completionHandler else {
      return
    }

    if let error = error {
      completionHandler(
        false,
        nil,
        SDKError.error(
          withCode: CoreError.errorBridgeAPIInterruption.rawValue,
          message: "Error occured while interacting with Gaming Services",
          underlyingError: error
        )
      )
    } else {
      completionHandler(
        false,
        nil,
        SDKError.error(
          withCode: CoreError.errorBridgeAPIInterruption.rawValue,
          message: "An Unknown error occured while interacting with Gaming Services"
        )
      )
    }

    self.completionHandler = nil
  }

  func completeSuccessfully() {
    completionHandler?(true, pendingResult as? [String: Any], nil)
    completionHandler = nil
  }

  // MARK: - URLOpening
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

    if isGamingUrl && completionHandler != nil {
      completeSuccessfully()
    }

    return isGamingUrl
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    isValidCallbackURL(url, forService: FBSDKGamingServiceTypeString(serviceType))
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    if completionHandler != nil {
      completeSuccessfully()
    }
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    false
  }

  func isValidCallbackURL(_ url: URL, forService service: String) -> Bool {
    // verify the URL is intended as a callback for the SDK's friend finder
    guard let appID = settings.appID, let scheme = url.scheme else { return false }
    return scheme.hasPrefix("fb\(appID)") && url.host == service
  }
}
