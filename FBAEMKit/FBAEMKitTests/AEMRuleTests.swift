/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit

import TestTools
import XCTest

#if !os(tvOS)

final class AEMRuleTests: XCTestCase {

  enum Keys {
    static let conversionValue = "conversion_value"
    static let priority = "priority"
    static let events = "events"
    static let eventName = "event_name"
    static let values = "values"
    static let currency = "currency"
    static let amount = "amount"
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let activateApp = "fb_activate_app"
    static let testEvent = "fb_test_event"
    static let USD = "USD"
    static let EU = "EU"
    static let JPY = "JPY"
  }

  var sampleData: [String: Any] = [
    Keys.conversionValue: 2,
    Keys.priority: 7,
    Keys.events: [
      [
        Keys.eventName: Values.purchase,
        Keys.values: [
          [
            Keys.currency: Values.USD,
            Keys.amount: 100.0,
          ],
        ],
      ],
    ],
  ]

  var validRule = _AEMRule(json: [
    Keys.conversionValue: 10,
    Keys.priority: 7,
    Keys.events: [
      [
        Keys.eventName: Values.purchase,
        Keys.values: [
          [
            Keys.currency: Values.USD,
            Keys.amount: 100.0,
          ],
        ],
      ],
    ],
  ])! // swiftlint:disable:this force_unwrapping

  func testValidCase1() {
    let validData: [String: Any] = [
      Keys.conversionValue: 2,
      Keys.priority: 10,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
        ],
        [
          Keys.eventName: Values.donate,
        ],
      ],
    ]

    guard let rule = _AEMRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(10, rule.priority)
    XCTAssertEqual(2, rule.events.count)

    let event1 = rule.events[0]
    XCTAssertEqual(event1.eventName, Values.purchase)
    XCTAssertNil(event1.values)

    let event2 = rule.events[1]
    XCTAssertEqual(event2.eventName, Values.donate)
    XCTAssertNil(event2.values)
  }

  func testValidCase2() {
    guard let rule = _AEMRule(json: sampleData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(7, rule.priority)
    XCTAssertEqual(1, rule.events.count)

    let event = rule.events[0]
    XCTAssertEqual(event.eventName, Values.purchase)
    XCTAssertEqual(event.values, [Values.USD: 100.0])
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(_AEMRule(json: invalidData))

    invalidData = [Keys.conversionValue: 2]
    XCTAssertNil(_AEMRule(json: invalidData))

    invalidData = [Keys.priority: 7]
    XCTAssertNil(_AEMRule(json: invalidData))

    invalidData = [
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(_AEMRule(json: invalidData))

    invalidData = [
      Keys.conversionValue: 2,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: 100,
              Keys.amount: Values.USD,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(_AEMRule(json: invalidData))

    invalidData = [
      Keys.priority: 2,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(_AEMRule(json: invalidData))
  }

  func testParsing() {
    (1 ... 100).forEach { _ in
      if let data = (Fuzzer.randomize(json: self.sampleData) as? [String: Any]) {
        _ = _AEMRule(json: data)
      }
    }
  }

  func testContainsEvent() {
    let rule = validRule

    XCTAssertTrue(
      rule.containsEvent(Values.purchase),
      "Should expect to return true for the event in the rule"
    )
    XCTAssertFalse(
      rule.containsEvent(Values.testEvent),
      "Should expect to return false for the event not in the rule"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      _AEMRule.supportsSecureCoding,
      "AEM Rule should support secure coding"
    )
  }

  func testEncodingAndDecoding() throws {
    let rule = validRule
    let decodedObject = try CodabilityTesting.encodeAndDecode(rule)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, rule, .isCodable)
    XCTAssertEqual(decodedObject, rule, .isCodable)

    // Test Properties
    XCTAssertEqual(decodedObject.conversionValue, rule.conversionValue, .isCodable)
    XCTAssertEqual(decodedObject.priority, rule.priority, .isCodable)
    XCTAssertEqual(rule.events, decodedObject.events, .isCodable)
  }

  func testRuleMatch() {
    guard let rule = _AEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100.0,
            ],
            [
              Keys.currency: Values.EU,
              Keys.amount: 100.0,
            ],
          ],
        ],
      ],
    ]) else {
      return XCTFail("Fail to initalize AEM rule")
    }
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.USD: 1000.0]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.EU: 1000.0]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp],
        recordedValues: [Values.purchase: [Values.USD: 1000.0]]
      ),
      "Should not match the unexpected events for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.JPY: 1000.0]]
      ),
      "Should not match the unexpected values for the rule"
    )
  }

  func testRuleMatchWithEventBundle() {
    guard let rule = _AEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.activateApp,
        ],
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100.0,
            ],
          ],
        ],
        [
          Keys.eventName: Values.testEvent,
        ],
      ],
    ]) else {
      return XCTFail("Fail to initalize AEM rule")
    }
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: [Values.purchase: [Values.USD: 1000.0]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: nil
      ),
      "Should not match the unexpected values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.USD: 1000.0]]
      ),
      "Should not match the unexpected events for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: [Values.purchase: [Values.JPY: 1000]]
      ),
      "Should not match the unexpected values for the rule"
    )
  }

  func testRuleMatchWithoutValue() {
    guard let rule = _AEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.activateApp,
        ],
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 0.0,
            ],
          ],
        ],
        [
          Keys.eventName: Values.testEvent,
        ],
      ],
    ]) else {
      return XCTFail("Fail to initalize AEM rule")
    }
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: nil
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: [Values.purchase: [Values.JPY: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "AEMRule should be encodable and decodable"
}

#endif
