/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class SKAdNetworkCoarseCVRuleTests: XCTestCase {
  func testValidCase1() {
    let validData: [String: Any] = [
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
    ]

    guard let rule = SKAdNetworkCoarseCVRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual("high", rule.coarseCvValue)
    XCTAssertEqual(2, rule.events.count)

    let event1 = rule.events[0]
    XCTAssertEqual(event1.eventName, "fb_mobile_purchase")
    XCTAssertEqual(event1.values, ["USD": 100.0])

    let event2 = rule.events[1]
    XCTAssertEqual(event2.eventName, "fb_mobile_search")
    XCTAssertNil(event2.values)
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(SKAdNetworkCoarseCVRule(json: invalidData))

    invalidData = ["coarse_cv_value": ""]
    XCTAssertNil(SKAdNetworkCoarseCVRule(json: invalidData))

    invalidData = ["coarse_cv_value": "high"]
    XCTAssertNil(SKAdNetworkCoarseCVRule(json: invalidData))

    invalidData = ["coarse_cv_value": "low", "events": []]
    XCTAssertNil(SKAdNetworkCoarseCVRule(json: invalidData))
  }
}
