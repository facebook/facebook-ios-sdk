/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class SKAdNetworkCoarseCVConfigTests: XCTestCase {
  func testValidCase1() {
    let validData: [String: Any] = [
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
    ]

    guard let config = SKAdNetworkCoarseCVConfig(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertNotNil(config.cvRules)
    XCTAssertEqual(2, config.cvRules.count)
    XCTAssertEqual(1, config.postbackSequenceIndex)
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(SKAdNetworkCoarseCVConfig(json: invalidData))

    invalidData = ["postback_sequence_index": 1]
    XCTAssertNil(SKAdNetworkCoarseCVConfig(json: invalidData))

    invalidData = ["postback_sequence_index": 2, "coarse_cv_rules": []]
    XCTAssertNil(SKAdNetworkCoarseCVConfig(json: invalidData))
  }
}
