/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class ServerConfigurationFixtures: NSObject {
  /// A default configuration with valid inputs. This is the same default configuration used in production code
  static var defaultConfiguration: ServerConfiguration {
    ServerConfiguration.defaultServerConfiguration(forAppID: "1.0")
  }

  /// A default configuration with custom values passed by dictionary.
  /// To use: Include a dictionary with the keys and values you want to override on the default configuration
  class func configuration( // swiftlint:disable:this cyclomatic_complexity
    withDictionary dict: [String: Any]
  ) -> ServerConfiguration {
    var loginTooltipEnabled = defaultConfiguration.isLoginTooltipEnabled
    if dict["loginTooltipEnabled"] != nil {
      loginTooltipEnabled = dict["loginTooltipEnabled"] as? Int != 0
    }
    var advertisingIDEnabled = defaultConfiguration.isAdvertisingIDEnabled
    if dict["advertisingIDEnabled"] != nil {
      advertisingIDEnabled = dict["advertisingIDEnabled"] as? Int != 0
    }
    var implicitLoggingEnabled = defaultConfiguration.isImplicitLoggingSupported
    if dict["implicitLoggingEnabled"] != nil {
      implicitLoggingEnabled = dict["implicitLoggingEnabled"] as? Int != 0
    }
    var implicitPurchaseLoggingEnabled = defaultConfiguration.isImplicitPurchaseLoggingSupported
    if dict["implicitPurchaseLoggingEnabled"] != nil {
      implicitPurchaseLoggingEnabled = dict["implicitPurchaseLoggingEnabled"] as? Int != 0
    }
    var codelessEventsEnabled = defaultConfiguration.isCodelessEventsEnabled
    if dict["codelessEventsEnabled"] != nil {
      codelessEventsEnabled = dict["codelessEventsEnabled"] as? Int != 0
    }
    var uninstallTrackingEnabled = defaultConfiguration.isUninstallTrackingEnabled
    if dict["uninstallTrackingEnabled"] != nil {
      uninstallTrackingEnabled = dict["uninstallTrackingEnabled"] as? Int != 0
    }

    var smartLoginOptions = defaultConfiguration.smartLoginOptions
    if let rawValue = dict["smartLoginOptions"] as? UInt {
      smartLoginOptions = FBSDKServerConfigurationSmartLoginOptions(rawValue: rawValue)
    }

    var defaults = defaultConfiguration.isDefaults
    if let dictDefaults = dict["defaults"] {
      if let intDefaults = dictDefaults as? Int {
        defaults = intDefaults != 0
      } else if let boolDefaults = dictDefaults as? Bool {
        defaults = boolDefaults
      }
    }

    let appID = dict["appID"] as? String ?? defaultConfiguration.appID
    let appName = dict["appName"] as? String ?? defaultConfiguration.appName
    let loginTooltipText = dict["loginTooltipText"] as? String ?? defaultConfiguration.loginTooltipText
    let defaultShareMode = dict["defaultShareMode"] as? String ?? defaultConfiguration.defaultShareMode
    let dialogConfigurations = defaultConfiguration.dialogConfigurations()
      ?? (dict["dialogConfigurations"] as? [String: Any])
    let dialogFlows = dict["dialogFlows"] as? [String: Any] ?? defaultConfiguration.dialogFlows()
    let timestamp = dict["timestamp"] as? Date ?? defaultConfiguration.timestamp
    let errorConfiguration = dict["errorConfiguration"] as? ErrorConfiguration
      ?? defaultConfiguration.errorConfiguration

    var sessionTimeoutInterval = defaultConfiguration.sessionTimoutInterval
    if let intInterval = dict["sessionTimeoutInterval"] as? Int {
      sessionTimeoutInterval = TimeInterval(Double(intInterval))
    } else if let doubleInterval = dict["sessionTimeoutInterval"] as? Double {
      sessionTimeoutInterval = TimeInterval(doubleInterval)
    }

    let loggingToken = dict["loggingToken"] as? String ?? defaultConfiguration.loggingToken
    let smartLoginBookmarkIconURL = (dict["smartLoginBookmarkIconURL"] as? URL)
      ?? defaultConfiguration.smartLoginBookmarkIconURL
    let smartLoginMenuIconURL = dict["smartLoginMenuIconURL"] as? URL ?? defaultConfiguration.smartLoginMenuIconURL
    let updateMessage = dict["updateMessage"] as? String ?? defaultConfiguration.updateMessage
    let eventBindings = dict["eventBindings"] as? [[String: Any]] ?? defaultConfiguration.eventBindings
    let restrictiveParams = dict["restrictiveParams"] as? [String: Any] ?? defaultConfiguration.restrictiveParams
    let AAMRules = dict["aamRules"] as? [String: Any] ?? defaultConfiguration.aamRules
    // swiftlint:disable:next line_length
    let suggestedEventsSetting = dict["suggestedEventsSetting"] as? [String: Any] ?? defaultConfiguration.suggestedEventsSetting

    return ServerConfiguration(
      appID: appID,
      appName: appName,
      loginTooltipEnabled: loginTooltipEnabled,
      loginTooltipText: loginTooltipText,
      defaultShareMode: defaultShareMode,
      advertisingIDEnabled: advertisingIDEnabled,
      implicitLoggingEnabled: implicitLoggingEnabled,
      implicitPurchaseLoggingEnabled: implicitPurchaseLoggingEnabled,
      codelessEventsEnabled: codelessEventsEnabled,
      uninstallTrackingEnabled: uninstallTrackingEnabled,
      dialogConfigurations: dialogConfigurations,
      dialogFlows: dialogFlows,
      timestamp: timestamp,
      errorConfiguration: errorConfiguration,
      sessionTimeoutInterval: sessionTimeoutInterval,
      defaults: defaults,
      loggingToken: loggingToken,
      smartLoginOptions: smartLoginOptions,
      smartLoginBookmarkIconURL: smartLoginBookmarkIconURL,
      smartLoginMenuIconURL: smartLoginMenuIconURL,
      updateMessage: updateMessage,
      eventBindings: eventBindings,
      restrictiveParams: restrictiveParams,
      aamRules: AAMRules,
      suggestedEventsSetting: suggestedEventsSetting
    )
  }
}
