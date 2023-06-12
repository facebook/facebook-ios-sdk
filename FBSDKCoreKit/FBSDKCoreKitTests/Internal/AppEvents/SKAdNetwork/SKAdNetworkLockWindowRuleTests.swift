/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class SKAdNetworkLockWindowRuleTests: XCTestCase {
  func testValidCase1() {
    let validData: [String: Any] = [
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
    ]

    guard let rule = SKAdNetworkLockWindowRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual("event", rule.lockWindowType)
    XCTAssertEqual(2, rule.events.count)
    XCTAssertEqual(1, rule.postbackSequenceIndex)

    let event1 = rule.events[0]
    XCTAssertEqual(event1.eventName, "fb_mobile_purchase")
    XCTAssertEqual(event1.values, ["USD": 100.0])

    let event2 = rule.events[1]
    XCTAssertEqual(event2.eventName, "fb_mobile_complete_registration")
    XCTAssertNil(event2.values)
  }

  func testValidCase2() {
    let validData: [String: Any] = [
      "lock_window_type": "time",
      "time": 36,
      "postback_sequence_index": 1,
    ]

    guard let rule = SKAdNetworkLockWindowRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual("time", rule.lockWindowType)
    XCTAssertEqual(36, rule.time)
    XCTAssertEqual(1, rule.postbackSequenceIndex)
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(SKAdNetworkLockWindowRule(json: invalidData))

    invalidData = ["lock_window_type": ""]
    XCTAssertNil(SKAdNetworkLockWindowRule(json: invalidData))

    invalidData = ["lock_window_type": "time"]
    XCTAssertNil(SKAdNetworkLockWindowRule(json: invalidData))

    invalidData = ["lock_window_type": "time", "postback_sequence_index": 2]
    XCTAssertNil(SKAdNetworkLockWindowRule(json: invalidData))

    invalidData = ["lock_window_type": "event", "postback_sequence_index": 2]
    XCTAssertNil(SKAdNetworkLockWindowRule(json: invalidData))

    invalidData = ["lock_window_type": "event", "postback_sequence_index": 2, "events": []]
    XCTAssertNil(SKAdNetworkLockWindowRule(json: invalidData))
  }
}
