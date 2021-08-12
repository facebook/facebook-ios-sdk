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
class TestSettings: NSObject, SettingsProtocol, SettingsLogging {
  static var appID: String?
  static var clientToken: String?
  static var userAgentSuffix: String?
  static var loggingBehaviors = Set<LoggingBehavior>()
  static var sdkVersion: String?

  var logWarningsCallCount = 0
  var logIfSDKSettingsChangedCallCount = 0
  var recordInstallCallCount = 0

  var appID: String?

  var stubbedGraphAPIVersion = FBSDK_TARGET_PLATFORM_VERSION
  var advertisingTrackingStatus: AdvertisingTrackingStatus = .unspecified
  var stubbedIsDataProcessingRestricted = false
  var stubbedIsAutoLogAppEventsEnabled = false
  var stubbedInstallTimestamp: Date?
  // swiftlint:disable:next identifier_name
  var stubbedSetAdvertiserTrackingEnabledTimestamp: Date?
  var stubbedIsSetATETimeExceedsInstallTime = false
  var stubbedIsSKAdNetworkReportEnabled = false
  var stubbedLimitEventAndDataUsage = false
  var shouldUseTokenOptimizations = true
  var isGraphErrorRecoveryEnabled = false
  var graphAPIDebugParamValue: String?

  var isDataProcessingRestricted: Bool {
    stubbedIsDataProcessingRestricted
  }

  var isAutoLogAppEventsEnabled: Bool {
    stubbedIsAutoLogAppEventsEnabled
  }

  var isSetATETimeExceedsInstallTime: Bool {
    stubbedIsSetATETimeExceedsInstallTime
  }

  var isSKAdNetworkReportEnabled: Bool {
    stubbedIsSKAdNetworkReportEnabled
  }

  var loggingBehaviors: Set<LoggingBehavior> {
    TestSettings.loggingBehaviors
  }

  var shouldLimitEventAndDataUsage: Bool {
    stubbedLimitEventAndDataUsage
  }

  var installTimestamp: Date? {
    stubbedInstallTimestamp
  }

  var advertiserTrackingEnabledTimestamp: Date? {
    stubbedSetAdvertiserTrackingEnabledTimestamp
  }

  var graphAPIVersion: String {
    stubbedGraphAPIVersion
  }

  func logWarnings() {
    logWarningsCallCount += 1
  }

  func logIfSDKSettingsChanged() {
    logIfSDKSettingsChangedCallCount += 1
  }

  func recordInstall() {
    recordInstallCallCount += 1
  }

  static func reset() {
    appID = nil
    clientToken = nil
    userAgentSuffix = nil
    loggingBehaviors = []
    sdkVersion = nil
  }
}
