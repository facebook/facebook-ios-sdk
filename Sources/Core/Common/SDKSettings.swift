// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import UIKit
import FBSDKCoreKit.FBSDKSettings

//--------------------------------------
// MARK: - SDK Version
//--------------------------------------

/// Current SDK version.
public let SDKVersion = FBSDKSettings.sdkVersion()

//--------------------------------------
// MARK: - SDKSettings
//--------------------------------------

/**
 Provides access to settings and configuration used by the entire SDK.
 */
public struct SDKSettings {
  /**
   Facebook App ID used by the SDK.
   Default value is read from the application's Info.plist under `FacebookAppId` key.
   */
  public static var appId: String {
    get {
      return FBSDKSettings.appID()
    }
    set {
      FBSDKSettings.setAppID(newValue)
    }
  }

  /**
   The default url scheme suffix used for sessions.
   Default value is read from the applicaiton's Info.plist under `FacebookUrlSchemeSuffix` key.
   */
  public static var appURLSchemeSuffix: String {
    get {
      return FBSDKSettings.appURLSchemeSuffix()
    }
    set {
      FBSDKSettings.setAppURLSchemeSuffix(newValue)
    }
  }

  /**
   The client token used by the SDK.
   It's is required for certain API calls when made anonymously aka without a user-based access token.

   Default value is read from the application's Info.plist under `FacebookClientToken` key.
   */
  public static var clientToken: String? {
    get {
      return FBSDKSettings.clientToken()
    }
    set {
      FBSDKSettings.setClientToken(clientToken)
    }
  }

  /**
   Facebook Display Name used by the SDK.
   Default value is read from the application's Info.plist under `FacebookDisplayName` key.
   */
  public static var displayName: String? {
    get {
      return FBSDKSettings.displayName()
    }
    set {
      FBSDKSettings.setDisplayName(newValue)
    }
  }

  /**
   Facebook sudomain name used by the SDK.
   This can be used to add the subdomain for all network requests that SDK is sending,
   e.g. setting this to `"beta"` will make all graph requests to be sent to `graph.beta.facebook.com`.
   Default value is read from the application's Info.plist under `FacebookDomainPart` key.
   */
  public static var facebookSubdomain: String? {
    get {
      return FBSDKSettings.facebookDomainPart()
    }
    set {
      FBSDKSettings.setFacebookDomainPart(newValue)
    }
  }

  /**
   The quality of JPEG images sent to Facebook from the SDK.
   Default value is `0.9`.
   */
  public static var JPEGCompressionQuality: Double {
    get {
      return Double(FBSDKSettings.jpegCompressionQuality())
    }
    set {
      FBSDKSettings.setJPEGCompressionQuality(CGFloat(newValue))
    }
  }

  /**
   If enabled, data such as that generated through `AppEventsLogger` and sent to Facebook
   should be restricted from being used for other than analytics and conversions.
   Defaults to `false`. This value is stored on the device and persists across app launches.
   */
  public static var limitedEventAndDataUsage: Bool {
    get {
      return FBSDKSettings.limitEventAndDataUsage()
    }
    set {
      FBSDKSettings.setLimitEventAndDataUsage(newValue)
    }
  }
}

//--------------------------------------
// MARK: - SDKSettings + Logging Behavior
//--------------------------------------

extension SDKSettings {
  /**
   Current logging behaviors of Facebook SDK.
   The default enabled behavior is `.DeveloperErrors` only.
   */
  public static var enabledLoggingBehaviors: Set<SDKLoggingBehavior> {
    get {
      let createBehavior = { (object: AnyHashable) -> SDKLoggingBehavior? in
        if let value = object as? String {
          return SDKLoggingBehavior(sdkStringValue: value)
        }
        return nil
      }

#if swift(>=4.1)
      let behaviors = FBSDKSettings.loggingBehavior().compactMap(createBehavior)
#else
      let behaviors = FBSDKSettings.loggingBehavior().flatMap(createBehavior)
#endif

      return Set(behaviors)
    }
    set {
      let behaviors = newValue.map({ $0.sdkStringValue })
      FBSDKSettings.setLoggingBehavior(Set(behaviors))
    }
  }

  /**
   Enable a particular Facebook SDK logging behavior.

   - parameter behavior: The behavior to enable
   */
  public static func enableLoggingBehavior(_ behavior: SDKLoggingBehavior) {
    FBSDKSettings.enableLoggingBehavior(behavior.sdkStringValue)
  }

  /**
   Disable a particular Facebook SDK logging behavior.

   - parameter behavior: The behavior to disable.
   */
  public static func disableLoggingBehavior(_ behavior: SDKLoggingBehavior) {
    FBSDKSettings.disableLoggingBehavior(behavior.sdkStringValue)
  }
}
