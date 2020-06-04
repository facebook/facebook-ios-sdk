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

import Foundation

@objc
public class RawServerConfigurationResponseFixtures: NSObject {

  enum Keys {
    static let appEventsFeatureBitmask = "app_events_feature_bitmask"
    static let appName = "name"
    static let defaultShareMode = "default_share_mode"
    static let loginTooltipEnabled = "gdpv4_nux_enabled"
    static let loginTooltipText = "gdpv4_nux_content"
    static let smartLoginOptions = "seamless_login"
    static let dialogConfigurations = "ios_dialog_configs"
    static let dialogFlows = "ios_sdk_dialog_flows"
    static let errorConfiguration = "ios_sdk_error_categories"
    static let sessionTimeoutInterval = "app_events_session_timeout"
    static let loggingToken = "logging_token"
    static let smartLoginBookmarkIconURL = "smart_login_bookmark_icon_url"
    static let smartLoginMenuIconURL = "smart_login_menu_icon_url"
    static let updateMessage = "sdk_update_message"
    static let restrictiveParams = "restrictive_data_filter_params"
    static let aamRules = "aam_rules"
    static let eventBindings = "auto_event_mapping_ios"
    static let suggestedEventsSetting = "suggested_events_setting"
    static let monitoringConfiguration = "monitoringConfiguration"
    static let implicitLoggingEnabled = "supports_implicit_sdk_logging"
  }

  /// Provides a dictionary with well-known keys and random values for a network provided server configuration
  @objc
  public class var random: [AnyHashable: Any] {
    return [
      Keys.appEventsFeatureBitmask: Fuzzer.random,
      Keys.appName: Fuzzer.random,
      Keys.defaultShareMode: Fuzzer.random,
      Keys.loginTooltipEnabled: Fuzzer.random,
      Keys.loginTooltipText: Fuzzer.random,
      Keys.smartLoginOptions: Fuzzer.random,
      Keys.dialogConfigurations: Fuzzer.random,
      Keys.dialogFlows: Fuzzer.random,
      Keys.errorConfiguration: Fuzzer.random,
      Keys.sessionTimeoutInterval: Fuzzer.random,
      Keys.loggingToken: Fuzzer.random,
      Keys.smartLoginBookmarkIconURL: Fuzzer.random,
      Keys.smartLoginMenuIconURL: Fuzzer.random,
      Keys.updateMessage: Fuzzer.random,
      Keys.restrictiveParams: Fuzzer.random,
      Keys.aamRules: Fuzzer.random,
      Keys.eventBindings: Fuzzer.random,
      Keys.suggestedEventsSetting: Fuzzer.random,
      Keys.monitoringConfiguration: Fuzzer.random,
      Keys.implicitLoggingEnabled: Fuzzer.random
    ]
  }
}
