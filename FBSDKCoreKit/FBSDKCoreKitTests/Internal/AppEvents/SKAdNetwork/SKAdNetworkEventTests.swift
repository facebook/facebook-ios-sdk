/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

@testable import FBSDKCoreKit

import XCTest

final class SKAdNetworkEventTests: XCTestCase {

  func testValidCases() {
    var event = _SKAdNetworkEvent(json: ["event_name": "fb_mobile_purchase"])
    XCTAssertTrue(event?.eventName == "fb_mobile_purchase")
    XCTAssertNil(event?.values)
    event = _SKAdNetworkEvent(
      json: [
        "event_name": "fb_mobile_purchase",
        "values": [
          [
            "currency": "usd",
            "amount": 100.0,
          ],
          [
            "currency": "JPY",
            "amount": 1000.0,
          ],
        ],
      ]
    )
    XCTAssertTrue(event?.eventName == "fb_mobile_purchase")
    let expectedValues: [String: Double] = [
      "USD": 100,
      "JPY": 1000,
    ]
    XCTAssertTrue(event?.values == expectedValues)
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(_SKAdNetworkEvent(json: invalidData))
    invalidData = [
      "values": [
        [
          "currency": "usd",
          "amount": 100,
        ],
        [
          "currency": "JPY",
          "amount": 1000,
        ],
      ],
    ]
    XCTAssertNil(_SKAdNetworkEvent(json: invalidData))
    invalidData = [
      "event_name": "fb_mobile_purchase",
      "values": [
        [
          "currency": 100,
          "amount": "usd",
        ],
        [
          "currency": 1000,
          "amount": "jpy",
        ],
      ],
    ]
    XCTAssertNil(_SKAdNetworkEvent(json: invalidData))
  }
}

#endif
