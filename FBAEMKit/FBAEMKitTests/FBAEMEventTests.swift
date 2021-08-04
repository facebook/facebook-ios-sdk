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

import FBAEMKit
import TestTools
import XCTest

#if !os(tvOS)

class FBAEMEventTests: XCTestCase {

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
        Keys.amount: 100
      ],
      [
        Keys.currency: Values.JPY,
        Keys.amount: 1000
      ]
    ]
  ]
  var validEventWithValues: FBAEMEvent? = FBAEMEvent(json: [
    Keys.eventName: Values.purchase,
    Keys.values: [
      [
        Keys.currency: Values.usd,
        Keys.amount: 100
      ],
      [
        Keys.currency: Values.JPY,
        Keys.amount: 1000
      ]
    ]
  ])

  var validEventWithoutValues: FBAEMEvent? = FBAEMEvent(json: [
    Keys.eventName: Values.purchase,
  ])

  func testValidCases() {
    var event = self.validEventWithoutValues
    XCTAssertEqual(
      event?.eventName,
      Values.purchase,
      "AEM event name should match the expected event_name in the json"
    )
    XCTAssertNil(
      event?.values,
      "AEM event should not have unexpected values"
    )
    event = self.validEventWithValues
    XCTAssertEqual(
      event?.eventName,
      Values.purchase,
      "AEM event name should match the expected event_name in the json"
    )
    let expectedValues: [String: NSNumber] = [
      Values.USD: 100,
      Values.JPY: 1000
    ]
    XCTAssertEqual(
      event?.values,
      expectedValues,
      "AEM event should have the expected values in the json"
    )
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(FBAEMEvent(json: invalidData))
    invalidData = [
      Keys.values: [
        [
          Keys.currency: Values.usd,
          Keys.amount: 100
        ],
        [
          Keys.currency: Values.JPY,
          Keys.amount: 1000
        ]
      ]
    ]
    XCTAssertNil(FBAEMEvent(json: invalidData))
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
        ]
      ]
    ]
    XCTAssertNil(FBAEMEvent(json: invalidData))
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
        ]
      ]
    ]
    XCTAssertNil(FBAEMEvent(json: invalidData))
  }

  func testParsing() {
    (1...100).forEach { _ in
      if let data = (Fuzzer.randomize(json: self.sampleData) as? [String: Any]) {
        _ = FBAEMEvent(json: data)
      }
    }
  }

  func testSecureCoding() {
    XCTAssertTrue(
      FBAEMEvent.supportsSecureCoding,
      "AEM Events should support secure coding"
    )
  }

  func testEncodingWithValues() {
    let coder = TestCoder()
    let event = self.validEventWithValues
    event?.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject[Keys.eventName] as? String,
      event?.eventName,
      "Should encode the expected event_name with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.values] as? [String: NSNumber],
      event?.values,
      "Should encode the expected values with the correct key"
    )
  }

  func testEncodingWithoutValues() {
    let coder = TestCoder()
    let event = self.validEventWithoutValues
    event?.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject[Keys.eventName] as? String,
      event?.eventName,
      "Should encode the expected event_name with the correct key"
    )
    XCTAssertNil(
      coder.encodedObject[Keys.values] as? [String: NSNumber],
      "Should not encode values"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = FBAEMEvent(coder: decoder)

    XCTAssertTrue(
      decoder.decodedObject[Keys.eventName] is NSString.Type,
      "Should decode the expected type for the event_name key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.values] is NSDictionary.Type,
      "Should decode the expected type for the values key"
    )
  }
}

#endif
