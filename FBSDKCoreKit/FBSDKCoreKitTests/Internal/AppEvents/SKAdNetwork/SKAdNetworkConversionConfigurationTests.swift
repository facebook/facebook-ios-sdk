/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

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
        ],
      ],
    ]

    configuration = SKAdNetworkConversionConfiguration(json: validData)
    XCTAssertNotNil(configuration)
    XCTAssertEqual(1, configuration?.timerBuckets)
    XCTAssertEqual(2, configuration?.cutoffTime)
    XCTAssertEqual(configuration?.defaultCurrency, "USD")
    XCTAssertEqual(1000, configuration?.timerInterval ?? 0, accuracy: 0.001)
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
                "amount": 100,
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
                "amount": 100,
              ],
              [
                "currency": "JPY",
                "amount": 100,
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
                "amount": 100,
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
                "amount": 100,
              ],
              [
                "currency": "JPY",
                "amount": 100,
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
                "amount": 100,
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
                "amount": 100,
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
                      "amount": 100,
                    ],
                  ],
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                  "values": [
                    [
                      "currency": "EU",
                      "amount": 100,
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
                      "amount": 100,
                    ],
                    [
                      "currency": "JPY",
                      "amount": 100,
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
                      "amount": 100,
                    ],
                  ],
                ],
                [
                  "event_name": "fb_mobile_complete_registration",
                  "values": [
                    [
                      "currency": "eu",
                      "amount": 100,
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
                      "currency": "usd",
                      "amount": 100,
                    ],
                    [
                      "currency": "jpy",
                      "amount": 100,
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
    let expected = Set(["USD", "EU", "JPY"])
    XCTAssertEqual(configuration?.currencySet, expected)
  }
}

#endif
