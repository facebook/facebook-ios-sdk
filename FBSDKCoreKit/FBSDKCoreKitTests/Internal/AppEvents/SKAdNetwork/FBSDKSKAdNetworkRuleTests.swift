// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if !os(tvOS)

class FBSDKSKAdNetworkRuleTests: FBSDKTestCase {
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

    guard let rule = FBSDKSKAdNetworkRule(json: validData) else { return XCTFail("Unwraping Error") }
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

    guard let rule = FBSDKSKAdNetworkRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(1, rule.events.count)
    XCTAssertEqual(1, rule.events.count)

    let event = rule.events[0]
    XCTAssertEqual(event.eventName, "fb_mobile_purchase")
    XCTAssertEqual(event.values, ["USD": 100])
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(FBSDKSKAdNetworkRule(json: invalidData))

    invalidData = ["conversion_value": 2]
    XCTAssertNil(FBSDKSKAdNetworkRule(json: invalidData))

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
    XCTAssertNil(FBSDKSKAdNetworkRule(json: invalidData))

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
    XCTAssertNil(FBSDKSKAdNetworkRule(json: invalidData))
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

    guard let rule = FBSDKSKAdNetworkRule(json: ruleData) else { return XCTFail("Unwraping Error") }
    let matchedEventSet: Set = ["fb_mobile_purchase", "fb_skadnetwork_test1", "fb_adnetwork_test2"]
    let unmatchedEventSet: Set = ["fb_mobile_purchase", "fb_skadnetwork_test2"]

    XCTAssertTrue(rule.isMatched(withRecordedEvents: matchedEventSet,
                                 recordedValues: ["fb_mobile_purchase": ["USD": 1000]]))
    XCTAssertFalse(rule.isMatched(withRecordedEvents: [],
                                  recordedValues: [:]))
    XCTAssertFalse(rule.isMatched(withRecordedEvents: matchedEventSet,
                                  recordedValues: [:]))
    XCTAssertFalse(rule.isMatched(withRecordedEvents: matchedEventSet,
                                  recordedValues: ["fb_mobile_purchase": ["USD": 50]]))
    XCTAssertFalse(rule.isMatched(withRecordedEvents: matchedEventSet,
                                  recordedValues: ["fb_mobile_purchase": ["JPY": 1000]]))
    XCTAssertFalse(rule.isMatched(withRecordedEvents: unmatchedEventSet,
                                  recordedValues: ["fb_mobile_purchase": ["USD": 1000]]))
  }
}

#endif
