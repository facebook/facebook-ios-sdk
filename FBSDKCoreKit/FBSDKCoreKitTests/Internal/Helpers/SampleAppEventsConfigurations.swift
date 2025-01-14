/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class SampleAppEventsConfigurations: NSObject {

  static let `default` = _AppEventsConfiguration.default()

  static var valid: _AppEventsConfiguration {
    create(
      defaultATEStatus: AdvertisingTrackingStatus.unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false,
      iapProdDedupConfiguration: self.default.iapProdDedupConfiguration,
      iapTestDedupConfiguration: self.default.iapTestDedupConfiguration
    )
  }

  static func create(
    defaultATEStatus status: AdvertisingTrackingStatus
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: status,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled
    )
  }

  static func create(
    advertiserIDCollectionEnabled: Bool
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled
    )
  }

  static func create(
    eventCollectionEnabled: Bool
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: eventCollectionEnabled
    )
  }

  static func create(
    iapObservationTime: UInt64
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled,
      iapObservationTime: iapObservationTime
    )
  }

  static func create(
    iapManualAndAutoLogDedupWindow: UInt64
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled,
      iapManualAndAutoLogDedupWindow: iapManualAndAutoLogDedupWindow
    )
  }

  static func create(
    iapProdDedupConfiguration: [String: [String]]
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled,
      iapProdDedupConfiguration: iapProdDedupConfiguration
    )
  }

  static func create(
    iapTestDedupConfiguration: [String: [String]]
  ) -> _AppEventsConfiguration {
    create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled,
      iapTestDedupConfiguration: iapTestDedupConfiguration
    )
  }

  static func create(
    defaultATEStatus: AdvertisingTrackingStatus,
    advertiserIDCollectionEnabled: Bool,
    eventCollectionEnabled: Bool,
    iapObservationTime: UInt64 = 3600000000000,
    iapManualAndAutoLogDedupWindow: UInt64 = 60000,
    iapProdDedupConfiguration: [String: [String]] = [String: [String]](),
    iapTestDedupConfiguration: [String: [String]] = [String: [String]]()
  ) -> _AppEventsConfiguration {
    _AppEventsConfiguration(
      defaultATEStatus: defaultATEStatus,
      advertiserIDCollectionEnabled: advertiserIDCollectionEnabled,
      eventCollectionEnabled: eventCollectionEnabled,
      iapObservationTime: iapObservationTime,
      iapManualAndAutoLogDedupWindow: iapManualAndAutoLogDedupWindow,
      iapProdDedupConfiguration: iapProdDedupConfiguration,
      iapTestDedupConfiguration: iapTestDedupConfiguration
    )
  }
}
