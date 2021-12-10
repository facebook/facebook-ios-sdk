/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class ServerConfigurationFixtures: NSObject {
  // swiftlint:disable function_body_length line_length

  /// A default configuration with valid inputs. This is the same default configuration used in production code
  static var defaultConfig: ServerConfiguration {
    ServerConfiguration.defaultServerConfiguration(forAppID: "1.0")
  }

  /// A default configuration with custom values passed by dictionary.
  /// To use: Include a dictionary with the keys and values you want to override on the default configuration
  class func config(withDictionary dict: [String: Any]) -> ServerConfiguration { // swiftlint:disable:this cyclomatic_complexity
    var loginTooltipEnabled = defaultConfig.isLoginTooltipEnabled
    if dict["loginTooltipEnabled"] != nil {
      loginTooltipEnabled = dict["loginTooltipEnabled"] as? Int != 0
    }
    var advertisingIDEnabled = defaultConfig.isAdvertisingIDEnabled
    if dict["advertisingIDEnabled"] != nil {
      advertisingIDEnabled = dict["advertisingIDEnabled"] as? Int != 0
    }
    var implicitLoggingEnabled = defaultConfig.isImplicitLoggingSupported
    if dict["implicitLoggingEnabled"] != nil {
      implicitLoggingEnabled = dict["implicitLoggingEnabled"] as? Int != 0
    }
    var implicitPurchaseLoggingEnabled = defaultConfig.isImplicitPurchaseLoggingSupported
    if dict["implicitPurchaseLoggingEnabled"] != nil {
      implicitPurchaseLoggingEnabled = dict["implicitPurchaseLoggingEnabled"] as? Int != 0
    }
    var codelessEventsEnabled = defaultConfig.isCodelessEventsEnabled
    if dict["codelessEventsEnabled"] != nil {
      codelessEventsEnabled = dict["codelessEventsEnabled"] as? Int != 0
    }
    var uninstallTrackingEnabled = defaultConfig.isUninstallTrackingEnabled
    if dict["uninstallTrackingEnabled"] != nil {
      uninstallTrackingEnabled = dict["uninstallTrackingEnabled"] as? Int != 0
    }

    var smartLoginOptions = defaultConfig.smartLoginOptions
    if let rawValue = dict["smartLoginOptions"] as? UInt {
      smartLoginOptions = FBSDKServerConfigurationSmartLoginOptions(rawValue: rawValue)
    }

    var defaults = defaultConfig.isDefaults
    if let dictDefaults = dict["defaults"] {
      if let intDefaults = dictDefaults as? Int {
        defaults = intDefaults != 0
      } else if let boolDefaults = dictDefaults as? Bool {
        defaults = boolDefaults
      }
    }

    let appID = dict["appID"] as? String ?? defaultConfig.appID
    let appName = dict["appName"] as? String ?? defaultConfig.appName
    let loginTooltipText = dict["loginTooltipText"] as? String ?? defaultConfig.loginTooltipText
    let defaultShareMode = dict["defaultShareMode"] as? String ?? defaultConfig.defaultShareMode
    let dialogConfigurations = defaultConfig.dialogConfigurations() ?? dict["dialogConfigurations"] as? [String: Any]
    let dialogFlows = dict["dialogFlows"] as? [String: Any] ?? defaultConfig.dialogFlows()
    let timestamp = dict["timestamp"] as? Date ?? defaultConfig.timestamp
    let errorConfiguration = dict["errorConfiguration"] as? ErrorConfiguration ?? defaultConfig.errorConfiguration

    var sessionTimeoutInterval = defaultConfig.sessionTimoutInterval
    if let intInterval = dict["sessionTimeoutInterval"] as? Int {
      sessionTimeoutInterval = TimeInterval(Double(intInterval))
    } else if let doubleInterval = dict["sessionTimeoutInterval"] as? Double {
      sessionTimeoutInterval = TimeInterval(doubleInterval)
    }

    let loggingToken = dict["loggingToken"] as? String ?? defaultConfig.loggingToken
    let smartLoginBookmarkIconURL = dict["smartLoginBookmarkIconURL"] as? URL ?? defaultConfig.smartLoginBookmarkIconURL
    let smartLoginMenuIconURL = dict["smartLoginMenuIconURL"] as? URL ?? defaultConfig.smartLoginMenuIconURL
    let updateMessage = dict["updateMessage"] as? String ?? defaultConfig.updateMessage
    let eventBindings = dict["eventBindings"] as? [Any] ?? defaultConfig.eventBindings
    let restrictiveParams = dict["restrictiveParams"] as? [String: Any] ?? defaultConfig.restrictiveParams
    let AAMRules = dict["aamRules"] as? [String: Any] ?? defaultConfig.aamRules
    let suggestedEventsSetting = dict["suggestedEventsSetting"] as? [String: Any] ?? defaultConfig.suggestedEventsSetting

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
