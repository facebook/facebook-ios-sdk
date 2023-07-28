/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class SampleSKAdNetworkConversionConfiguration: NSObject {

  static var fineCVconfigurationJson: [String: Any] {
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
                  "event_name": "fb_test",
                ],
              ],
            ],
          ],
        ],
      ],
    ]
  }

  static var coarseCVconfigurationJson: [String: Any] {
    [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 1,
          "default_currency": "USD",
          "isCoarseCVAccumulative": false,
          "conversion_value_rules": [],
          "coarse_cv_configs": [
            [
              "postback_sequence_index": 1,
              "coarse_cv_rules":
                [
                  [
                    "coarse_cv_value": "medium",
                    "events": [
                      [
                        "event_name": "fb_test",
                      ],
                    ],
                  ],
                ],
            ],
          ],
        ],
      ],
    ]
  }
}
