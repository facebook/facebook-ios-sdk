/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import TestTools

@objcMembers
class RawAppEventsConfigurationResponseFixtures: NSObject {

  enum Keys {
    static let defaultATEStatus = "default_ate_status"
    static let advertiserIDCollectionEnabled = "advertiser_id_collection_enabled"
    static let eventCollectionEnabled = "event_collection_enabled"
    static let topLevel = "app_events_config"
  }

  static var valid: [String: Any] {
    [
      Keys.topLevel: [
        Keys.defaultATEStatus: 1,
        Keys.advertiserIDCollectionEnabled: false,
        Keys.eventCollectionEnabled: true
      ]
    ]
  }

  static var validMissingTopLevelKey: [String: Any] {
    [
      Keys.defaultATEStatus: 1,
      Keys.advertiserIDCollectionEnabled: 1,
      Keys.eventCollectionEnabled: 1,
    ]
  }

  static var invalidValues: [String: Any] {
    [
      Keys.topLevel: [
        Keys.defaultATEStatus: "foo",
        Keys.advertiserIDCollectionEnabled: "bar",
        Keys.eventCollectionEnabled: "baz"
      ]
    ]
  }

  /// Provides a dictionary with well-known keys and random values for a network provided app events configuration
  static var random: Any {
    let response = [
      Keys.topLevel: [
        Keys.defaultATEStatus: Fuzzer.random,
        Keys.advertiserIDCollectionEnabled: Fuzzer.random,
        Keys.eventCollectionEnabled: Fuzzer.random,
      ]
    ]
    return Fuzzer.randomize(json: response)
  }
}
