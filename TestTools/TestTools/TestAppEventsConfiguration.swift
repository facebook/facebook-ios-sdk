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
public final class TestAppEventsConfiguration: NSObject, _AppEventsConfigurationProtocol {
  static var stubbedDefaultConfiguration: TestAppEventsConfiguration?

  public var defaultATEStatus: AdvertisingTrackingStatus = .unspecified
  public var advertiserIDCollectionEnabled = false
  public var eventCollectionEnabled = false
  public var iapObservationTime: UInt64 = 3600000000000

  public init(
    defaultATEStatus: AdvertisingTrackingStatus = .unspecified,
    advertiserIDCollectionEnabled: Bool = false,
    eventCollectionEnabled: Bool = false,
    iapObservationTime: UInt64 = 3600000000000
  ) {
    self.defaultATEStatus = defaultATEStatus
    self.advertiserIDCollectionEnabled = advertiserIDCollectionEnabled
    self.eventCollectionEnabled = eventCollectionEnabled
    self.iapObservationTime = iapObservationTime
  }

  public required init(json dict: [String: Any]?) {}

  public static func `default`() -> Self {
    guard let stubbed = stubbedDefaultConfiguration as? Self else {
      fatalError("Must have a default configuration")
    }
    return stubbed
  }

  public static func reset() {
    stubbedDefaultConfiguration = nil
  }
}
