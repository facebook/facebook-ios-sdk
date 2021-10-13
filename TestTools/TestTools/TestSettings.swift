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
  public var isCodelessDebugLogEnabled: Bool = false
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
