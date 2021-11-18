/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestAppEventsConfiguration: NSObject, AppEventsConfigurationProtocol {
  static var stubbedDefaultConfiguration: TestAppEventsConfiguration?

  var defaultATEStatus: AdvertisingTrackingStatus = .unspecified
  var advertiserIDCollectionEnabled = false
  var eventCollectionEnabled = false

  init(
    defaultATEStatus: AdvertisingTrackingStatus = .unspecified,
    advertiserIDCollectionEnabled: Bool = false,
    eventCollectionEnabled: Bool = false
  ) {
    self.defaultATEStatus = defaultATEStatus
    self.advertiserIDCollectionEnabled = advertiserIDCollectionEnabled
    self.eventCollectionEnabled = eventCollectionEnabled
  }

  required init(json dict: [String: Any]?) {
  }

  static func `default`() -> Self {
    guard let stubbed = stubbedDefaultConfiguration as? Self else {
      fatalError("Must have a default configuration")
    }
    return stubbed
  }

  static func reset() {
    stubbedDefaultConfiguration = nil
  }
}
