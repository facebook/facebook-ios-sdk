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
      eventCollectionEnabled: false
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
    defaultATEStatus: AdvertisingTrackingStatus,
    advertiserIDCollectionEnabled: Bool,
    eventCollectionEnabled: Bool,
    iapObservationTime: UInt64 = 3600000000000
  ) -> _AppEventsConfiguration {
    _AppEventsConfiguration(
      defaultATEStatus: defaultATEStatus,
      advertiserIDCollectionEnabled: advertiserIDCollectionEnabled,
      eventCollectionEnabled: eventCollectionEnabled,
      iapObservationTime: iapObservationTime
    )
  }
}
