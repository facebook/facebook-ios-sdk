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
  public var iapManualAndAutoLogDedupWindow: UInt64 = 60000
  public var iapProdDedupConfiguration: [String: [String]] = [:]
  public var iapTestDedupConfiguration: [String: [String]] = [:]

  public init(
    defaultATEStatus: AdvertisingTrackingStatus = .unspecified,
    advertiserIDCollectionEnabled: Bool = false,
    eventCollectionEnabled: Bool = false,
    iapObservationTime: UInt64 = 3600000000000,
    iapManualAndAutoLogDedupWindow: UInt64 = 60000,
    iapProdDedupConfiguration: [String: [String]] = [:],
    iapTestDedupConfiguration: [String: [String]] = [:]
  ) {
    self.defaultATEStatus = defaultATEStatus
    self.advertiserIDCollectionEnabled = advertiserIDCollectionEnabled
    self.eventCollectionEnabled = eventCollectionEnabled
    self.iapObservationTime = iapObservationTime
    self.iapManualAndAutoLogDedupWindow = iapManualAndAutoLogDedupWindow
    self.iapProdDedupConfiguration = iapProdDedupConfiguration
    self.iapTestDedupConfiguration = iapTestDedupConfiguration
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
