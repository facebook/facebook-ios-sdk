/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objc(FBSDKSettings)
public protocol SettingsProtocol {
  var appID: String? { get set }
  var clientToken: String? { get set }
  var userAgentSuffix: String? { get set }
  var sdkVersion: String { get }
  var displayName: String? { get set }
  var facebookDomainPart: String? { get set }
  var loggingBehaviors: Set<LoggingBehavior> { get set }
  var appURLSchemeSuffix: String? { get set }
  var isDataProcessingRestricted: Bool { get }
  var isAutoLogAppEventsEnabled: Bool { get }
  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable let_var_whitespace
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isCodelessDebugLogEnabled` instead.
      """
  )
  var codelessDebugLogEnabled: Bool { get set }
  // swiftlint:enable let_var_whitespace
  var isCodelessDebugLogEnabled: Bool { get set }
  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable let_var_whitespace
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isAdvertiserIDCollectionEnabled` instead.
      """
  )
  var advertiserIDCollectionEnabled: Bool { get set }
  // swiftlint:enable let_var_whitespace
  var isAdvertiserIDCollectionEnabled: Bool { get set }
  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable let_var_whitespace
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isATETimeSufficientlyDelayed` instead.
      """
  )
  var isSetATETimeExceedsInstallTime: Bool { get }
  // swiftlint:enable let_var_whitespace
  var isATETimeSufficientlyDelayed: Bool { get }
  var isSKAdNetworkReportEnabled: Bool { get }
  var advertisingTrackingStatus: AdvertisingTrackingStatus { get }
  var installTimestamp: Date? { get }
  var advertiserTrackingEnabledTimestamp: Date? { get }
  var isEventDataUsageLimited: Bool { get set }
  var shouldUseTokenOptimizations: Bool { get set }
  var graphAPIVersion: String { get set }
  var isGraphErrorRecoveryEnabled: Bool { get set }
  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable let_var_whitespace
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `graphAPIDebugParameterValue` instead.
      """
  )
  var graphAPIDebugParamValue: String? { get }
  // swiftlint:enable let_var_whitespace
  var graphAPIDebugParameterValue: String? { get }
  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable let_var_whitespace
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `isAdvertiserTrackingEnabled` instead.
      """
  )
  var advertiserTrackingEnabled: Bool { get set }
  // swiftlint:enable let_var_whitespace
  var isAdvertiserTrackingEnabled: Bool { get set }
  var shouldUseCachedValuesForExpensiveMetadata: Bool { get set }
  var persistableDataProcessingOptions: [DataProcessingOptionKey.RawValue: Any]? { get }

  /**
   Sets the data processing options.

   - Parameter options: The list of options.
   */
  func setDataProcessingOptions(_ options: [String]?)

  /**
   Sets the data processing options.

   - Parameters:
     - options The list of the options.
     - country The code for the country.
     - state The code for the state.
   */
  func setDataProcessingOptions(_ options: [String]?, country: Int32, state: Int32)
}
