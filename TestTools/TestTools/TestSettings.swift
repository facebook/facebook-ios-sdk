/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
public class TestSettings: NSObject, SettingsProtocol, SettingsLogging {
  public var isEventDataUsageLimited = false
  // swiftlint:disable:next identifier_name
  public var shouldUseCachedValuesForExpensiveMetadata = false
  public var isAdvertiserIDCollectionEnabled = false
  public var appID: String?
  public var clientToken: String?
  public var sdkVersion: String = ""
  public var userAgentSuffix: String?
  public var displayName: String?
  public var facebookDomainPart: String?
  public var logWarningsCallCount = 0
  public var logIfSDKSettingsChangedCallCount = 0
  public var recordInstallCallCount = 0
  public var appURLSchemeSuffix: String?
  public var graphAPIVersion = FBSDK_DEFAULT_GRAPH_API_VERSION
  public var advertisingTrackingStatus: AdvertisingTrackingStatus = .unspecified
  public var stubbedIsDataProcessingRestricted = false
  public var stubbedIsAutoLogAppEventsEnabled = false
  public var stubbedInstallTimestamp: Date?
  // swiftlint:disable:next identifier_name
  public var stubbedSetAdvertiserTrackingEnabledTimestamp: Date?
  public var stubbedIsSetATETimeExceedsInstallTime = false
  public var stubbedIsSKAdNetworkReportEnabled = false
  public var stubbedLimitEventAndDataUsage = false
  public var shouldUseTokenOptimizations = true
  public var isGraphErrorRecoveryEnabled = false
  public var graphAPIDebugParamValue: String?
  public var isAdvertiserTrackingEnabled = false
  public var loggingBehaviors = Set<LoggingBehavior>()
  public var isCodelessDebugLogEnabled = false
  public static var loggingBehaviors = Set<LoggingBehavior>()

  public var isDataProcessingRestricted: Bool {
    stubbedIsDataProcessingRestricted
  }

  public var isAutoLogAppEventsEnabled: Bool {
    stubbedIsAutoLogAppEventsEnabled
  }

  public var isSetATETimeExceedsInstallTime: Bool {
    stubbedIsSetATETimeExceedsInstallTime
  }

  public var isSKAdNetworkReportEnabled: Bool {
    stubbedIsSKAdNetworkReportEnabled
  }

  public var shouldLimitEventAndDataUsage: Bool {
    stubbedLimitEventAndDataUsage
  }

  public var installTimestamp: Date? {
    stubbedInstallTimestamp
  }

  public var advertiserTrackingEnabledTimestamp: Date? {
    stubbedSetAdvertiserTrackingEnabledTimestamp
  }

  public func logWarnings() {
    logWarningsCallCount += 1
  }

  public func logIfSDKSettingsChanged() {
    logIfSDKSettingsChangedCallCount += 1
  }

  public func recordInstall() {
    recordInstallCallCount += 1
  }

  public func reset() {
    appID = nil
    clientToken = nil
    userAgentSuffix = nil
    loggingBehaviors = []
  }
}
