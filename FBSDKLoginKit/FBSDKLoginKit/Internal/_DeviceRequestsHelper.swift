/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

/// Helper class for device requests mDNS broadcasts. Note this is only intended for internal consumption.
@objcMembers
@objc(FBSDKDeviceRequestsHelper)
public final class _DeviceRequestsHelper: NSObject {

  // We use weak to strong in order to retain the advertisement services
  // without having to pass them back to the delegate that started them
  // Note that in case the delegate is destroyed before it had a chance to
  // stop the service, the service will continue broadcasting until the map
  // resizes itself and releases the service, causing it to stop
  private(set) static var mdnsAdvertisementServices = NSMapTable<NetServiceDelegate, AnyObject>.weakToStrongObjects()

  private enum DeviceInfoKeys {
    static let deviceInfo = "device"
    static let deviceModel = "model"
  }

  private enum NetServiceValues {

    static let header = "fbsdk"

    #if !os(tvOS)
    static let flavor = "ios"
    #else
    static let flavor = "tvos"
    #endif

    static let sdkVersion: String = {
      var sdkVersion = Settings.shared.sdkVersion.replacingOccurrences(of: ".", with: "|")

      guard
        sdkVersion.count > 10,
        let firstCharacter = sdkVersion.first,
        firstCharacter.isASCII,
        firstCharacter.isNumber
      else {
        return "dev"
      }

      return sdkVersion
    }()

    static let netServiceType = "_fb._tcp."
  }

  /// Get device info to include with the GraphRequest
  public static func getDeviceInfo() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)

    let data = Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN))

    guard
      let device = String(bytes: data, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters)
    else { return "" }

    let model = UIDevice.current.model

    return """
      {"\(DeviceInfoKeys.deviceModel)":"\(model)","\(DeviceInfoKeys.deviceInfo)":"\(device)"}
      """
  }

  /**
   Start the mDNS advertisement service for a device request
   @param loginCode The login code associated with the action for the device request.
   @return True if the service broadcast was successfully started.
   */
  @discardableResult
  public static func startAdvertisementService(loginCode: String, delegate: NetServiceDelegate) -> Bool {
    let serviceName = """
      \(NetServiceValues.header)_\(NetServiceValues.flavor)-\(NetServiceValues.sdkVersion)_\(loginCode)
      """

    guard serviceName.count <= 60 else { return false }

    let mdnsAdvertisementService = NetService(
      domain: "local.",
      type: NetServiceValues.netServiceType,
      name: serviceName,
      port: 0
    )
    mdnsAdvertisementService.delegate = delegate
    mdnsAdvertisementService.publish(options: [.noAutoRename, .listenForConnections])
    AppEvents.shared.logInternalEvent(.smartLoginService, parameters: [:], isImplicitlyLogged: true)
    mdnsAdvertisementServices.setObject(mdnsAdvertisementService, forKey: delegate)
    return true
  }

  /**
   Check if a service delegate is registered with particular advertisement service
   @param delegate The delegate to check if registered.
   @param service The advertisement service to check for.
   @return True if the service is the one the delegate registered with.
   */
  public static func isDelegate(_ delegate: NetServiceDelegate, forAdvertisementService service: NetService) -> Bool {
    guard
      let mdnsAdvertisementService = mdnsAdvertisementServices.object(forKey: delegate) as? NetService
    else {
      return false
    }
    return mdnsAdvertisementService === service
  }

  /**
   Stop the mDNS advertisement service for a device request
   @param delegate The delegate registered with the service.
   */
  public static func cleanUpAdvertisementService(for delegate: NetServiceDelegate) {
    guard
      let mdnsAdvertisementService = mdnsAdvertisementServices.object(forKey: delegate) as? NetService
    else {
      return
    }
    mdnsAdvertisementService.delegate = nil
    mdnsAdvertisementService.stop()
    mdnsAdvertisementServices.removeObject(forKey: delegate)
  }
}
