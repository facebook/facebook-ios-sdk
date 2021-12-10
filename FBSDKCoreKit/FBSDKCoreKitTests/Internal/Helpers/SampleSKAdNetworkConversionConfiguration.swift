/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
class SampleSKAdNetworkConversionConfiguration: NSObject {

  static var configJson: [String: Any] {
    [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 1,
          "default_currency": "USD",
          "conversion_value_rules": [
            [
              "conversion_value": 2,
              "events": [
                [
                  "event_name": "fb_test"
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  }
}
