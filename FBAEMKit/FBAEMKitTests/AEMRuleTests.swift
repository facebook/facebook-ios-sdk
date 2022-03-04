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
            Keys.amount: 100,
          ],
        ],
      ],
    ],
  ]

  var validRule = AEMRule(json: [
    Keys.conversionValue: 10,
    Keys.priority: 7,
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

    guard let rule = AEMRule(json: validData) else { return XCTFail("Unwraping Error") }
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
    guard let rule = AEMRule(json: sampleData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(7, rule.priority)
    XCTAssertEqual(1, rule.events.count)

    let event = rule.events[0]
    XCTAssertEqual(event.eventName, Values.purchase)
    XCTAssertEqual(event.values, [Values.USD: 100])
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(AEMRule(json: invalidData))

    invalidData = [Keys.conversionValue: 2]
    XCTAssertNil(AEMRule(json: invalidData))

    invalidData = [Keys.priority: 7]
    XCTAssertNil(AEMRule(json: invalidData))

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
    XCTAssertNil(AEMRule(json: invalidData))

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
    XCTAssertNil(AEMRule(json: invalidData))

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
    XCTAssertNil(AEMRule(json: invalidData))
  }

  func testParsing() {
    (1 ... 100).forEach { _ in
      if let data = (Fuzzer.randomize(json: self.sampleData) as? [String: Any]) {
        _ = AEMRule(json: data)
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
      AEMRule.supportsSecureCoding,
      "AEM Rule should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    let rule = validRule
    rule.encode(with: coder)

    let encodedConversionValue = coder.encodedObject[Keys.conversionValue] as? NSNumber
    XCTAssertEqual(
      encodedConversionValue?.intValue,
      rule.conversionValue,
      "Should encode the expected conversion_value with the correct key"
    )
    let encodedPriority = coder.encodedObject[Keys.priority] as? NSNumber
    XCTAssertEqual(
      encodedPriority?.intValue,
      rule.priority,
      "Should encode the expected priority with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.events] as? [AEMEvent],
      rule.events,
      "Should encode the expected events with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AEMRule(coder: decoder)

    XCTAssertEqual(
      decoder.decodedObject[Keys.conversionValue] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the conversion_value key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.priority] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the priority key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.events] as? NSSet,
      [NSArray.self, AEMEvent.self],
      "Should decode the expected type for the events key"
    )
  }

  func testRuleMatch() {
    guard let rule = AEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
            [
              Keys.currency: Values.EU,
              Keys.amount: 100,
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
        recordedValues: [Values.purchase: [Values.USD: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.EU: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp],
        recordedValues: [Values.purchase: [Values.USD: 1000]]
      ),
      "Should not match the unexpected events for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.JPY: 1000]]
      ),
      "Should not match the unexpected values for the rule"
    )
  }

  func testRuleMatchWithEventBundle() {
    guard let rule = AEMRule(json: [
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
              Keys.amount: 100,
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
        recordedValues: [Values.purchase: [Values.USD: 1000]]
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
        recordedValues: [Values.purchase: [Values.USD: 1000]]
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
    guard let rule = AEMRule(json: [
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
              Keys.amount: 0,
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

#endif
