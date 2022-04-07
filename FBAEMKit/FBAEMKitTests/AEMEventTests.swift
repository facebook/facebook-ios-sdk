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

final class AEMEventTests: XCTestCase {

  enum Keys {
    static let eventName = "event_name"
    static let values = "values"
    static let currency = "currency"
    static let amount = "amount"
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let subscribe = "Subscribe"
    static let usd = "usd"
    static let jpy = "jpy"
    static let USD = "USD"
    static let JPY = "JPY"
  }

  var sampleData: [String: Any] = [
    Keys.eventName: Values.purchase,
    Keys.values: [
      [
        Keys.currency: Values.usd,
        Keys.amount: 100,
      ],
      [
        Keys.currency: Values.JPY,
        Keys.amount: 1000,
      ],
    ],
  ]
  var validEventWithValues: _AEMEvent? = _AEMEvent(dict: [
    Keys.eventName: Values.purchase,
    Keys.values: [
      [
        Keys.currency: Values.usd,
        Keys.amount: 100,
      ],
      [
        Keys.currency: Values.JPY,
        Keys.amount: 1000,
      ],
    ],
  ])

  var validEventWithoutValues: _AEMEvent? = _AEMEvent(dict: [
    Keys.eventName: Values.purchase,
  ])

  func testValidCases() {
    var event = validEventWithoutValues
    XCTAssertEqual(
      event?.eventName,
      Values.purchase,
      "AEM event name should match the expected event_name in the json"
    )
    XCTAssertNil(
      event?.values,
      "AEM event should not have unexpected values"
    )
    event = validEventWithValues
    XCTAssertEqual(
      event?.eventName,
      Values.purchase,
      "AEM event name should match the expected event_name in the json"
    )
    let expectedValues: [String: Int] = [
      Values.USD: 100,
      Values.JPY: 1000,
    ]
    XCTAssertEqual(
      event?.values,
      expectedValues,
      "AEM event should have the expected values in the json"
    )
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(_AEMEvent(dict: invalidData))
    invalidData = [
      Keys.values: [
        [
          Keys.currency: Values.usd,
          Keys.amount: 100,
        ],
        [
          Keys.currency: Values.JPY,
          Keys.amount: 1000,
        ],
      ],
    ]
    XCTAssertNil(_AEMEvent(dict: invalidData))
    invalidData = [
      Keys.eventName: Values.purchase,
      Keys.values: [
        [
          Keys.currency: 100,
          Keys.amount: Values.usd,
        ],
        [
          Keys.currency: 1000,
          Keys.amount: Values.jpy,
        ],
      ],
    ]
    XCTAssertNil(_AEMEvent(dict: invalidData))
    invalidData = [
      Keys.eventName: [Values.purchase, Values.subscribe],
      Keys.values: [
        [
          Keys.currency: 100,
          Keys.amount: Values.usd,
        ],
        [
          Keys.currency: 1000,
          Keys.amount: Values.jpy,
        ],
      ],
    ]
    XCTAssertNil(_AEMEvent(dict: invalidData))
  }

  func testParsing() {
    (1 ... 100).forEach { _ in
      if let data = (Fuzzer.randomize(json: self.sampleData) as? [String: Any]) {
        _ = _AEMEvent(dict: data)
      }
    }
  }

  func testSecureCoding() {
    XCTAssertTrue(
      _AEMEvent.supportsSecureCoding,
      "AEM Events should support secure coding"
    )
  }

  func testEncodingAndDecodingWithValues() throws {
    let event = validEventWithValues
    // swiftlint:disable:next force_unwrapping
    let decodedObject = try CodabilityTesting.encodeAndDecode(event!)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, event, .isCodable)
    XCTAssertEqual(decodedObject, event, .isCodable)

    // Test Properties
    XCTAssertEqual(event?.eventName, decodedObject.eventName)
    XCTAssertEqual(event?.values, decodedObject.values)
  }

  func testEncodingAndDecodingWithoutValues() throws {
    let event = validEventWithoutValues
    // swiftlint:disable:next force_unwrapping
    let decodedObject = try CodabilityTesting.encodeAndDecode(event!)

    // Test Objects
    XCTAssertNotIdentical(decodedObject, event, .isCodable)
    XCTAssertEqual(decodedObject, event, .isCodable)

    // Test Properties
    XCTAssertEqual(event?.eventName, decodedObject.eventName)
    XCTAssertEqual(event?.values, decodedObject.values)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "AEMEvents should be encodable and decodable"
}

#endif
