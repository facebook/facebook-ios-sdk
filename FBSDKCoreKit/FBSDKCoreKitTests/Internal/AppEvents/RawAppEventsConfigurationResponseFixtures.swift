/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import TestTools

@objcMembers
final class RawAppEventsConfigurationResponseFixtures: NSObject {

  enum Keys {
    static let defaultATEStatus = "default_ate_status"
    static let advertiserIDCollectionEnabled = "advertiser_id_collection_enabled"
    static let eventCollectionEnabled = "event_collection_enabled"
    static let iapObservationTime = "ios_iap_observation_time"
    static let iapManualAndAutoLogDedupWindow = "iap_manual_log_dedup_window_millis"
    static let iapManualAndAutologDedupKeys = "iap_manual_and_auto_log_dedup_keys"
    static let topLevel = "app_events_config"
  }

  static var valid: [String: Any] {
    [
      Keys.topLevel: [
        Keys.defaultATEStatus: 1,
        Keys.advertiserIDCollectionEnabled: false,
        Keys.eventCollectionEnabled: true,
        Keys.iapObservationTime: 3600000000000,
        Keys.iapManualAndAutoLogDedupWindow: 60000,
        Keys.iapManualAndAutologDedupKeys: [
          [
            "key": "prod_keys",
            "value": [
              [
                "key": "fb_content_id",
                "value": [
                  [
                    "key": 0,
                    "value": "fb_content_id",
                  ],
                  [
                    "key": 1,
                    "value": "fb_product_item_id",
                  ],
                ],
              ],
              [
                "key": "fb_transaction_id",
                "value": [
                  [
                    "key": 0,
                    "value": "fb_transaction_id",
                  ],
                  [
                    "key": 1,
                    "value": "fb_order_id",
                  ],
                ],
              ],
            ],
          ],
          [
            "key": "test_keys",
            "value": [
              [
                "key": "test_key_1",
                "value": [
                  [
                    "key": 0,
                    "value": "test_value_0",
                  ],
                  [
                    "key": 1,
                    "value": "test_value_1",
                  ],
                ],
              ],
            ],
          ],
        ],
      ],
    ]
  }

  static var emptyDedupConfig: [String: Any] {
    [
      Keys.topLevel: [
        Keys.defaultATEStatus: 1,
        Keys.advertiserIDCollectionEnabled: false,
        Keys.eventCollectionEnabled: true,
        Keys.iapObservationTime: 3600000000000,
        Keys.iapManualAndAutoLogDedupWindow: 60000,
        Keys.iapManualAndAutologDedupKeys: [],
      ],
    ]
  }

  static var emptyProdAndTestDedupConfig: [String: Any] {
    [
      Keys.topLevel: [
        Keys.defaultATEStatus: 1,
        Keys.advertiserIDCollectionEnabled: false,
        Keys.eventCollectionEnabled: true,
        Keys.iapObservationTime: 3600000000000,
        Keys.iapManualAndAutoLogDedupWindow: 60000,
        Keys.iapManualAndAutologDedupKeys: [
          [
            "key": "prod_keys",
          ],
          [
            "key": "test_keys",
          ],
        ],
      ],
    ]
  }

  static var validMissingTopLevelKey: [String: Any] {
    [
      Keys.defaultATEStatus: 1,
      Keys.advertiserIDCollectionEnabled: 1,
      Keys.eventCollectionEnabled: 1,
      Keys.iapObservationTime: 3600000000000,
      Keys.iapManualAndAutoLogDedupWindow: 60000,
      Keys.iapManualAndAutologDedupKeys: [],
    ]
  }

  static var invalidValues: [String: Any] {
    [
      Keys.topLevel: [
        Keys.defaultATEStatus: "foo",
        Keys.advertiserIDCollectionEnabled: "bar",
        Keys.eventCollectionEnabled: "baz",
        Keys.iapObservationTime: "fuzz",
        Keys.iapManualAndAutoLogDedupWindow: "bizz",
        Keys.iapManualAndAutologDedupKeys: "buzz",
      ],
    ]
  }

  /// Provides a dictionary with well-known keys and random values for a network provided app events configuration
  static var random: Any {
    let response = [
      Keys.topLevel: [
        Keys.defaultATEStatus: Fuzzer.random,
        Keys.advertiserIDCollectionEnabled: Fuzzer.random,
        Keys.eventCollectionEnabled: Fuzzer.random,
        Keys.iapObservationTime: Fuzzer.random,
        Keys.iapManualAndAutoLogDedupWindow: Fuzzer.random,
        Keys.iapManualAndAutologDedupKeys: Fuzzer.random,
      ],
    ]
    return Fuzzer.randomize(json: response)
  }
}
