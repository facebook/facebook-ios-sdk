/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public final class TestSettings: NSObject, SettingsProtocol, SettingsLogging {
  public var isEventDataUsageLimited = false
  public var shouldUseCachedValuesForExpensiveMetadata = false
  public var isAdvertiserIDCollectionEnabled = false
  public var advertiserIDCollectionEnabled = false
  public var appID: String?
  public var clientToken: String?
  public var sdkVersion = ""
  public var userAgentSuffix: String?
  public var displayName: String?
  public var facebookDomainPart: String?
  public var logWarningsCallCount = 0
  public var logIfSDKSettingsChangedCallCount = 0
  public var recordInstallCallCount = 0
  public var appURLSchemeSuffix: String?
  public var graphAPIVersion = FBSDK_DEFAULT_GRAPH_API_VERSION
  public var advertisingTrackingStatus: AdvertisingTrackingStatus = .unspecified
  public var isDataProcessingRestricted = false
  public var isAutoLogAppEventsEnabled = false
  public var installTimestamp: Date?
  public var advertiserTrackingEnabledTimestamp: Date?
  public var isSetATETimeExceedsInstallTime = false
  public var isATETimeSufficientlyDelayed = false
  public var isSKAdNetworkReportEnabled = false
  public var shouldLimitEventAndDataUsage = false
  public var shouldUseTokenOptimizations = true
  public var isGraphErrorRecoveryEnabled = false
  public var graphAPIDebugParameterValue: String?
  public var graphAPIDebugParamValue: String?
  public var isAdvertiserTrackingEnabled = false
  public var advertiserTrackingEnabled = false
  public var loggingBehaviors = Set<LoggingBehavior>()
  public var isCodelessDebugLogEnabled = false
  public var codelessDebugLogEnabled = false
  public static var loggingBehaviors = Set<LoggingBehavior>()
  public var persistableDataProcessingOptions: [String: Any]?
  public var isDomainErrorEnabled = true

  public func logWarnings() {
    logWarningsCallCount += 1
  }

  public func logIfSDKSettingsChanged() {
    logIfSDKSettingsChangedCallCount += 1
  }

  public func recordInstall() {
    recordInstallCallCount += 1
  }

  public func setDataProcessingOptions(_ options: [String]?) {}

  public func setDataProcessingOptions(_ options: [String]?, country: Int32, state: Int32) {}

  public func reset() {
    appID = nil
    clientToken = nil
    userAgentSuffix = nil
    loggingBehaviors = []
  }
}
