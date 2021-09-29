// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@objcMembers
class ServerConfigurationFixtures: NSObject {
  // swiftlint:disable function_body_length line_length

  /// A default configuration with valid inputs. This is the same default configuration used in production code
  static var defaultConfig: ServerConfiguration {
    ServerConfiguration.defaultServerConfiguration(forAppID: "1.0")
  }

  /// A default configuration with custom values passed by dictionary.
  /// To use: Include a dictionary with the keys and values you want to override on the default configuration
  class func config(withDictionary dict: [String: Any]) -> ServerConfiguration {
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
    if dict["defaults"] != nil {
      defaults = dict["defaults"] as? Int != 0
    }

    let appID = dict["appID"] as? String ?? defaultConfig.appID
    let appName = dict["appName"] as? String ?? defaultConfig.appName
    let loginTooltipText = dict["loginTooltipText"] as? String ?? defaultConfig.loginTooltipText
    let defaultShareMode = dict["defaultShareMode"] as? String ?? defaultConfig.defaultShareMode
    let dialogConfigurations = defaultConfig.dialogConfigurations() ?? dict["dialogConfigurations"] as? [String: Any]
    let dialogFlows = dict["dialogFlows"] as? [String: Any] ?? defaultConfig.dialogFlows()
    let timestamp = dict["timestamp"] as? Date ?? defaultConfig.timestamp
    let errorConfiguration = dict["errorConfiguration"] as? ErrorConfiguration ?? defaultConfig.errorConfiguration
    let sessionTimeoutInterval = TimeInterval(dict["sessionTimeoutInterval"] as? Double ?? defaultConfig.sessionTimoutInterval)
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
