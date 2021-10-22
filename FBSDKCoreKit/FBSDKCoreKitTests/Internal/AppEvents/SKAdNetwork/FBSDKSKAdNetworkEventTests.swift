/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import XCTest

class FBSDKSKAdNetworkEventTests: XCTestCase {

  func testValidCases() {
    var event = SKAdNetworkEvent(json: ["event_name": "fb_mobile_purchase"])
    XCTAssertTrue(event?.eventName == "fb_mobile_purchase")
    XCTAssertNil(event?.values)
    event = SKAdNetworkEvent(
      json: [
        "event_name": "fb_mobile_purchase",
        "values": [
          [
            "currency": "usd",
            "amount": 100
          ],
          [
            "currency": "JPY",
            "amount": 1000
          ]
        ]
      ]
    )
    XCTAssertTrue(event?.eventName == "fb_mobile_purchase")
    let expectedValues: [String: NSNumber] = [
      "USD": 100,
      "JPY": 1000
    ]
    XCTAssertTrue(event?.values == expectedValues)
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(SKAdNetworkEvent(json: invalidData))
    invalidData = [
      "values": [
        [
          "currency": "usd",
          "amount": 100
        ],
        [
          "currency": "JPY",
          "amount": 1000
        ]
      ]
    ]
    XCTAssertNil(SKAdNetworkEvent(json: invalidData))
    invalidData = [
      "event_name": "fb_mobile_purchase",
      "values": [
        [
          "currency": 100,
          "amount": "usd"
        ],
        [
          "currency": 1000,
          "amount": "jpy"
        ]
      ]
    ]
    XCTAssertNil(SKAdNetworkEvent(json: invalidData))
  }
}

#endif
