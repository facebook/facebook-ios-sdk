/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

final class SKAdNetworkRuleTests: XCTestCase {
  func testValidCase1() {
    let validData: [String: Any] = [
      "conversion_value": 2,
      "events": [
        [
          "event_name": "fb_mobile_purchase",
        ],
        [
          "event_name": "Donate",
        ],
      ],
    ]

    guard let rule = SKAdNetworkRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(2, rule.events.count)

    let event1 = rule.events[0]
    XCTAssertEqual(event1.eventName, "fb_mobile_purchase")
    XCTAssertNil(event1.values)

    let event2 = rule.events[1]
    XCTAssertEqual(event2.eventName, "Donate")
    XCTAssertNil(event2.values)
  }

  func testValidCase2() {
    let validData: [String: Any] = [
      "conversion_value": 2,
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
    ]

    guard let rule = SKAdNetworkRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(1, rule.events.count)
    XCTAssertEqual(1, rule.events.count)

    let event = rule.events[0]
    XCTAssertEqual(event.eventName, "fb_mobile_purchase")
    XCTAssertEqual(event.values, ["USD": 100])
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(SKAdNetworkRule(json: invalidData))

    invalidData = ["conversion_value": 2]
    XCTAssertNil(SKAdNetworkRule(json: invalidData))

    invalidData = [
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
    ]
    XCTAssertNil(SKAdNetworkRule(json: invalidData))

    invalidData = [
      "conversion_value": 2,
      "events": [
        [
          "event_name": "fb_mobile_purchase",
          "values": [
            [
              "currency": 100,
              "amount": "USD",
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(SKAdNetworkRule(json: invalidData))
  }

  func testRuleMatch() {
    let ruleData: [String: Any] = [
      "conversion_value": 2,
      "events": [
        [
          "event_name": "fb_skadnetwork_test1",
        ],
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
    ]

    guard let rule = SKAdNetworkRule(json: ruleData) else { return XCTFail("Unwraping Error") }
    let matchedEventSet: Set = ["fb_mobile_purchase", "fb_skadnetwork_test1", "fb_adnetwork_test2"]
    let unmatchedEventSet: Set = ["fb_mobile_purchase", "fb_skadnetwork_test2"]

    XCTAssertTrue(
      rule.isMatched(withRecordedEvents: matchedEventSet, recordedValues: ["fb_mobile_purchase": ["USD": 1000]])
    )
    XCTAssertFalse(rule.isMatched(withRecordedEvents: [], recordedValues: [:]))
    XCTAssertFalse(rule.isMatched(withRecordedEvents: matchedEventSet, recordedValues: [:]))
    XCTAssertFalse(
      rule.isMatched(withRecordedEvents: matchedEventSet, recordedValues: ["fb_mobile_purchase": ["USD": 50]])
    )
    XCTAssertFalse(
      rule.isMatched(withRecordedEvents: matchedEventSet, recordedValues: ["fb_mobile_purchase": ["JPY": 1000]])
    )
    XCTAssertFalse(
      rule.isMatched(withRecordedEvents: unmatchedEventSet, recordedValues: ["fb_mobile_purchase": ["USD": 1000]])
    )
  }
}

#endif
