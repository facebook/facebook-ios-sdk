/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

extension Settings {
  enum PersistenceKey: String {
    case urlSchemeSuffix = "FacebookUrlSchemeSuffix"
    case clientToken = "FacebookClientToken"
    case displayName = "FacebookDisplayName"
    case domainPart = "FacebookDomainPart"
    case isAutoLogAppEventsEnabled = "FacebookAutoLogAppEventsEnabled"
    case isAdvertiserIDCollectionEnabled = "FacebookAdvertiserIDCollectionEnabled"
    case isCodelessDebugLogEnabled = "FacebookCodelessDebugLogEnabled"
    case loggingBehaviors = "FacebookLoggingBehavior"
    case appID = "FacebookAppID"
    case jpegCompressionQuality = "FacebookJpegCompressionQuality"
    case isSKAdNetworkReportEnabled = "FacebookSKAdNetworkReportEnabled"
    case advertisingTrackingStatus = "com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus"
    case limitEventAndDataUsage = "com.facebook.sdk:FBSDKSettingsLimitEventAndDataUsage"
    case useCachedValuesForExpensiveMetadata = "com.facebook.sdk:FBSDKSettingsUseCachedValuesForExpensiveMetadata"
    case useTokenOptimizations = "com.facebook.sdk.FBSDKSettingsUseTokenOptimizations"
    case dataProcessingOptions = "com.facebook.sdk:FBSDKSettingsDataProcessingOptions"
    case bitmask = "com.facebook.sdk:FBSDKSettingsBitmask"
    case installTimestamp = "com.facebook.sdk:FBSDKSettingsInstallTimestamp"
    case setAdvertiserTrackingEnabledTimestamp = "com.facebook.sdk:FBSDKSettingsSetAdvertiserTrackingEnabledTimestamp"
  }
}
