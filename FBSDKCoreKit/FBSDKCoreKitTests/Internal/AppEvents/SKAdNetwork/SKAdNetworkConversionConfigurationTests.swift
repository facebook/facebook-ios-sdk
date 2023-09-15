/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class SKAdNetworkConversionConfigurationTests: XCTestCase {
  func testInit() {
    // Init with nil
    var configuration = SKAdNetworkConversionConfiguration(json: nil)
    XCTAssertNil(configuration)

    // Init with invalid data
    var invalidData = [String: Any]()
    configuration = SKAdNetworkConversionConfiguration(json: invalidData)
    XCTAssertNil(configuration)

    invalidData = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2,
        ],
      ],
    ]
    configuration = SKAdNetworkConversionConfiguration(json: invalidData)
    XCTAssertNil(configuration)

    invalidData = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "conversion_value_rules": [],
        ],
      ],
    ]
    configuration = SKAdNetworkConversionConfiguration(json: invalidData)
    XCTAssertNil(configuration)

    // Init with valid data
    let validData = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2,
          "conversion_value_rules": [],
          "lock_window_rules": [],
          "coarse_cv_configs": [],
          "is_coarse_cv_accumulative": false,
        ],
      ],
    ]

    configuration = SKAdNetworkConversionConfiguration(json: validData)
    XCTAssertNotNil(configuration)
    XCTAssertEqual(1, configuration?.timerBuckets)
    XCTAssertEqual(2, configuration?.cutoffTime)
    XCTAssertEqual(configuration?.defaultCurrency, "USD")
    XCTAssertEqual(1000, configuration?.timerInterval ?? 0, accuracy: 0.001)
    XCTAssertEqual(false, configuration?.isCoarseCVAccumulative)
  }

  func testParseRules() throws {
    let rules = [
      [
        "conversion_value": 2,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
          ],
        ],
      ],
      [
        "conversion_value": 4,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100.0,
              ],
            ],
          ],
        ],
      ],
      [
        "conversion_value": 3,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100.0,
              ],
              [
                "currency": "JPY",
                "amount": 100.0,
              ],
            ],
          ],
        ],
      ],
    ]

    let conversionBitRules = try XCTUnwrap(SKAdNetworkConversionConfiguration.parseRules(rules))
    var expectedRules = [SKAdNetworkRule]()

    expectedRules.append(try XCTUnwrap(
      SKAdNetworkRule(json: [
        "conversion_value": 4,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100.0,
              ],
            ],
          ],
        ],
      ])
    ))

    expectedRules.append(try XCTUnwrap(
      SKAdNetworkRule(json: [
        "conversion_value": 3,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100.0,
              ],
              [
                "currency": "JPY",
                "amount": 100.0,
              ],
            ],
          ],
        ],
      ])
    ))

    expectedRules.append(try XCTUnwrap(
      SKAdNetworkRule(json: [
        "conversion_value": 2,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
          ],
        ],
      ])
    ))

    for (expectedRule, parsedRule) in zip(expectedRules, conversionBitRules) {
      XCTAssertEqual(expectedRule.conversionValue, parsedRule.conversionValue)
      XCTAssertEqual(expectedRule.events.count, parsedRule.events.count)

      for (expectedEvent, parsedEvent) in zip(expectedRule.events, parsedRule.events) {
        XCTAssertEqual(expectedEvent.eventName, parsedEvent.eventName)

        XCTAssertEqual(expectedEvent.values, parsedEvent.values) // nil or equal
      }
    }

    XCTAssertNil(SKAdNetworkConversionConfiguration.parseRules(nil))

    let invalidData = [
      [
        "conversion_value": 2,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "amount": 100.0,
              ],
            ],
          ],
        ],
      ],
      [
        "conversion_value": 3,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
            "values": [
              [
                "currency": "USD",
                "amount": 100.0,
              ],
            ],
          ],
        ],
      ],
    ]
    XCTAssertEqual(1, SKAdNetworkConversionConfiguration.parseRules(invalidData)?.count)
  }

  func testParseShuffledRules() throws {
    let data: NSMutableArray = []
    for conv in 0 ... 10 {
      data.add([
        "conversion_value": conv,
        "events": [
          [
            "event_name": "fb_mobile_purchase",
          ],
        ],
      ])
    }
    let expectedConvs = [Int](0 ... 10)
    for _ in 0 ... 1000 {
      let res = try XCTUnwrap(SKAdNetworkConversionConfiguration.parseRules(data.shuffled()))
      var convs: [Int] = []
      for item in res {
        convs.append(item.conversionValue)
      }
      XCTAssertEqual(convs.reversed(), expectedConvs)
    }
  }

  func testEventSet() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "default_currency": "usd",
          "conversion_value_rules": [
            [
              "conversion_value": 2,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                ],
              ],
            ],
            [
              "conversion_value": 4,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100.0,
                    ],
                  ],
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                  "values": [
                    [
                      "currency": "EU",
                      "amount": 100.0,
                    ],
                  ],
                ],
              ],
            ],
            [
              "conversion_value": 3,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100.0,
                    ],
                    [
                      "currency": "JPY",
                      "amount": 100.0,
                    ],
                  ],
                ],
                [
                  "event_name": "fb_mobile_search",
                ],
              ],
            ],
          ],
        ],
      ],
    ]

    let configuration = SKAdNetworkConversionConfiguration(json: data)
    let expected = Set(["fb_mobile_search", "fb_mobile_purchase", "fb_mobile_complete_registration"])
    XCTAssertEqual(configuration?.eventSet, expected)
  }

  func testEventSetWithCoraseValueSetup() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "default_currency": "usd",
          "conversion_value_rules": [
            [
              "conversion_value": 3,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                ],
              ],
            ],
          ],
          "coarse_cv_configs": [
            [
              "postback_sequence_index": 1,
              "coarse_cv_rules": [
                [
                  "coarse_cv_value": "high",
                  "events": [
                    [
                      "event_name": "fb_mobile_add_to_cart",
                    ],
                  ],
                ],
                [
                  "coarse_cv_value": "medium",
                  "events": [
                    [
                      "event_name": "fb_mobile_level_up",
                    ],
                  ],
                ],
              ],
            ],
            [
              "postback_sequence_index": 2,
              "coarse_cv_rules": [
                [
                  "coarse_cv_value": "low",
                  "events": [
                    [
                      "event_name": "fb_mobile_content_view",
                    ],
                  ],
                ],
              ],
            ],
          ],
        ],
      ],
    ]

    let configuration = SKAdNetworkConversionConfiguration(json: data)
    let expected = Set(["fb_mobile_add_to_cart", "fb_mobile_level_up", "fb_mobile_content_view"])
    XCTAssertEqual(configuration?.coarseEventSet, expected)
  }

  func testCurrencySet() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "default_currency": "usd",
          "conversion_value_rules": [
            [
              "conversion_value": 2,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                ],
              ],
            ],
            [
              "conversion_value": 4,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100.0,
                    ],
                  ],
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                  "values": [
                    [
                      "currency": "eu",
                      "amount": 100.0,
                    ],
                  ],
                ],
              ],
            ],
            [
              "conversion_value": 3,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "jpy",
                      "amount": 100.0,
                    ],
                  ],
                ],
              ],
            ],
          ],
        ],
      ],
    ]

    let configuration = SKAdNetworkConversionConfiguration(json: data)
    let expected = Set(["USD", "EU", "JPY"])
    XCTAssertEqual(configuration?.currencySet, expected)
  }

  func testCurrencySetWithCoarseValueSetup() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "cutoff_time": 2,
          "default_currency": "usd",
          "conversion_value_rules": [
            [
              "conversion_value": 4,
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "USD",
                      "amount": 100.0,
                    ],
                  ],
                ],
              ],
            ],
          ],
          "coarse_cv_configs": [
            [
              "postback_sequence_index": 1,
              "coarse_cv_rules": [
                [
                  "coarse_cv_value": "high",
                  "events": [
                    [
                      "event_name": "fb_mobile_purchase",
                      "values": [
                        [
                          "currency": "eur",
                          "amount": 100.0,
                        ],
                      ],
                    ],
                  ],
                ],
                [
                  "coarse_cv_value": "medium",
                  "events": [
                    [
                      "event_name": "fb_mobile_search",
                      "values": [
                        [
                          "currency": "sgd",
                          "amount": 100.0,
                        ],
                      ],
                    ],
                  ],
                ],
              ],
            ],
            [
              "postback_sequence_index": 2,
              "coarse_cv_rules": [
                [
                  "coarse_cv_value": "low",
                  "events": [
                    [
                      "event_name": "fb_mobile_level_up",
                      "values": [
                        [
                          "currency": "gbp",
                          "amount": 100.0,
                        ],
                      ],
                    ],
                  ],
                ],
              ],
            ],
          ],
        ],
      ],
    ]

    let configuration = SKAdNetworkConversionConfiguration(json: data)
    let expected = Set(["EUR", "GBP", "SGD"])
    XCTAssertEqual(configuration?.coarseCurrencySet, expected)
  }

  func testLockWindowRules() {
    let timeData: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2,
          "conversion_value_rules": [],
          "lock_window_rules": [
            [
              "lock_window_type": "time",
              "time": 36,
              "postback_sequence_index": 1,
            ],
            [
              "lock_window_type": "time",
              "time": 68,
              "postback_sequence_index": 2,
            ],
          ],
        ],
      ],
    ]

    let timeConfiguration = SKAdNetworkConversionConfiguration(json: timeData)
    XCTAssertEqual(timeConfiguration?.lockWindowRules?.count, 2)
    XCTAssertEqual(timeConfiguration?.lockWindowRules?[0].lockWindowType, "time")
    XCTAssertEqual(timeConfiguration?.lockWindowRules?[0].time, 36)
    XCTAssertEqual(timeConfiguration?.lockWindowRules?[0].postbackSequenceIndex, 1)
    XCTAssertEqual(timeConfiguration?.lockWindowRules?[1].time, 68)
    XCTAssertEqual(timeConfiguration?.lockWindowRules?[1].postbackSequenceIndex, 2)

    let eventsData: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2,
          "conversion_value_rules": [],
          "lock_window_rules": [
            [
              "lock_window_type": "event",
              "events": [
                [
                  "event_name": "fb_mobile_purchase",
                  "values": [
                    [
                      "currency": "usd",
                      "amount": 100.0,
                    ],
                  ],
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                ],
              ],
              "postback_sequence_index": 1,
            ],
          ],
        ],
      ],
    ]

    let eventsConfiguration = SKAdNetworkConversionConfiguration(json: eventsData)
    XCTAssertEqual(eventsConfiguration?.lockWindowRules?[0].lockWindowType, "event")
    XCTAssertEqual(eventsConfiguration?.lockWindowRules?[0].postbackSequenceIndex, 1)
    XCTAssertEqual(eventsConfiguration?.lockWindowRules?[0].events.count, 2)
    XCTAssertEqual(eventsConfiguration?.lockWindowRules?[0].events[0].eventName, "fb_mobile_purchase")
    XCTAssertEqual(eventsConfiguration?.lockWindowRules?[0].events[1].eventName, "fb_mobile_complete_registration")
  }

  func testCoraseCvConfigs() {
    let data: [String: Any] = [
      "data": [
        [
          "timer_buckets": 1,
          "timer_interval": 1000,
          "default_currency": "usd",
          "cutoff_time": 2,
          "conversion_value_rules": [],
          "coarse_cv_configs": [
            [
              "postback_sequence_index": 1,
              "coarse_cv_rules": [
                [
                  "coarse_cv_value": "high",
                  "events": [
                    [
                      "event_name": "fb_mobile_purchase",
                      "values": [
                        [
                          "currency": "usd",
                          "amount": 100.0,
                        ],
                      ],
                    ],
                    [
                      "event_name": "fb_mobile_search",
                    ],
                  ],
                ],
                [
                  "coarse_cv_value": "medium",
                  "events": [
                    [
                      "event_name": "fb_mobile_purchase",
                    ],
                    [
                      "event_name": "fb_mobile_search",
                    ],
                  ],
                ],
              ],
            ],
            [
              "postback_sequence_index": 2,
              "coarse_cv_rules": [
                [
                  "coarse_cv_value": "low",
                  "events": [
                    [
                      "event_name": "fb_mobile_level_up",
                    ],
                  ],
                ],
              ],
            ],
          ],
        ],
      ],
    ]

    let configuration = SKAdNetworkConversionConfiguration(json: data)
    XCTAssertEqual(configuration?.coarseCvConfigs?.count, 2)
    XCTAssertEqual(configuration?.coarseCvConfigs?[0].postbackSequenceIndex, 1)
    XCTAssertEqual(configuration?.coarseCvConfigs?[0].cvRules.count, 2)
    XCTAssertEqual(configuration?.coarseCvConfigs?[0].cvRules[0].coarseCvValue, "high")
    XCTAssertEqual(configuration?.coarseCvConfigs?[0].cvRules[0].events.count, 2)
    XCTAssertEqual(configuration?.coarseCvConfigs?[0].cvRules[0].events[0].eventName, "fb_mobile_purchase")
    XCTAssertEqual(configuration?.coarseCvConfigs?[0].cvRules[0].events[1].eventName, "fb_mobile_search")
    XCTAssertEqual(configuration?.coarseCvConfigs?[1].postbackSequenceIndex, 2)
    XCTAssertEqual(configuration?.coarseCvConfigs?[1].cvRules.count, 1)
    XCTAssertEqual(configuration?.coarseCvConfigs?[1].cvRules[0].coarseCvValue, "low")
    XCTAssertEqual(configuration?.coarseCvConfigs?[1].cvRules[0].events.count, 1)
    XCTAssertEqual(configuration?.coarseCvConfigs?[1].cvRules[0].events[0].eventName, "fb_mobile_level_up")
  }
}
