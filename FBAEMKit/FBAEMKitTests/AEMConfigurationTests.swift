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

final class AEMConfigurationTests: XCTestCase {

  enum Keys {
    static let defaultCurrency = "default_currency"
    static let cutoffTime = "cutoff_time"
    static let validFrom = "valid_from"
    static let mode = "config_mode"
    static let advertiserID = "advertiser_id"
    static let businessID = "business_id"
    static let paramRule = "param_rule"
    static let conversionValueRules = "conversion_value_rules"
    static let conversionValue = "conversion_value"
    static let priority = "priority"
    static let events = "events"
    static let eventName = "event_name"
    static let values = "values"
    static let currency = "currency"
    static let amount = "amount"
  }

  enum Values {
    static let coffeeBrand = "coffeebrand"
    static let paramRule = #"{"and": [{"fb_content[*].brand": {"eq": "CoffeeShop"}}]}"#
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let defaultMode = "default"
    static let USD = "USD"
    static let JPY = "JPY"
  }

  var sampleData: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 10000,
    Keys.mode: Values.defaultMode,
    Keys.advertiserID: Values.coffeeBrand,
    Keys.paramRule: Values.paramRule,
    Keys.conversionValueRules: [
      [
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
      ],
    ],
  ]

  var rulesData = [
    [
      Keys.conversionValue: 9,
      Keys.priority: 10,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100.0,
            ],
            [
              Keys.currency: Values.JPY,
              Keys.amount: 1000.0,
            ],
          ],
        ],
        [
          Keys.eventName: Values.donate,
        ],
      ],
    ],
    [
      Keys.conversionValue: 15,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.donate,
        ],
      ],
    ],
    [
      Keys.conversionValue: 20,
      Keys.priority: 15,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
        ],
      ],
    ],
  ]

  let advertiserRuleFactory = _AEMAdvertiserRuleFactory()

  override func setUp() {
    super.setUp()

    _AEMConfiguration.configure(withRuleProvider: advertiserRuleFactory)
  }

  func testConfiguration() {
    XCTAssertEqual(
      _AEMConfiguration.ruleProvider as! _AEMAdvertiserRuleFactory, // swiftlint:disable:this force_cast
      advertiserRuleFactory,
      "Should configure the _AEMConfiguration correctly"
    )
  }

  func testValidCases() {
    let configuration = _AEMConfiguration(json: sampleData)

    XCTAssertEqual(
      configuration?.defaultCurrency,
      Values.USD,
      "Should parse the expected default_currency with the correct value"
    )
    XCTAssertEqual(
      configuration?.cutoffTime,
      1,
      "Should parse the expected cutoff_time with the correct value"
    )
    XCTAssertEqual(
      configuration?.validFrom,
      10000,
      "Should parse the expected valid_from with the correct value"
    )
    XCTAssertEqual(
      configuration?.mode,
      Values.defaultMode,
      "Should parse the expected config_mode with the correct value"
    )
    XCTAssertEqual(
      configuration?.businessID,
      Values.coffeeBrand,
      "Should parse the expected business_id with the correct value"
    )
    XCTAssertEqual(
      configuration?.conversionValueRules.count,
      1,
      "Should parse the expected conversion_value_rules with the correct value"
    )
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(_AEMConfiguration(json: invalidData))
    invalidData = [
      Keys.defaultCurrency: 100,
      Keys.cutoffTime: 1,
      Keys.validFrom: 10000,
      Keys.mode: Values.defaultMode,
      Keys.conversionValueRules: [
        [
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
        ],
      ],
    ]
    XCTAssertNil(
      _AEMConfiguration(json: invalidData),
      "Should not consider the configuration json valid with unexpected type for default_currency"
    )
    invalidData = [
      Keys.defaultCurrency: Values.USD,
      Keys.cutoffTime: 1,
      Keys.validFrom: 10000,
      Keys.mode: Values.defaultMode,
    ]
    XCTAssertNil(
      _AEMConfiguration(json: invalidData),
      "Should not consider the configuration json valid without any conversion value rules"
    )
    invalidData = [
      Keys.defaultCurrency: Values.USD,
      Keys.cutoffTime: 1,
      Keys.validFrom: 10000,
      Keys.mode: Values.defaultMode,
      Keys.conversionValueRules: [
        [
          Keys.conversionValue: "2",
          Keys.priority: 10,
          Keys.events: [
            [
              Keys.eventName: Values.purchase,
            ],
            [
              Keys.eventName: Values.donate,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(
      _AEMConfiguration(json: invalidData),
      "Should not consider the configuration json valid with invalid conversion value rule"
    )
  }

  func testGetEventSet() {
    guard let parsedRules: [_AEMRule] = _AEMConfiguration.parseRules(rulesData)
    else { return XCTFail("Unwrapping Error") }
    let eventSet = _AEMConfiguration.getEventSet(from: parsedRules)
    XCTAssertEqual(eventSet, [Values.purchase, Values.donate], "Should get the expected event set")
  }

  func testGetCurrencySet() {
    guard let parsedRules: [_AEMRule] = _AEMConfiguration.parseRules(rulesData)
    else { return XCTFail("Unwrapping Error") }
    let eventSet = _AEMConfiguration.getCurrencySet(from: parsedRules)
    XCTAssertEqual(eventSet, [Values.USD, Values.JPY], "Should get the expected event set")
  }

  func testParseRules() {
    let parsedRules: [_AEMRule]? = _AEMConfiguration.parseRules(rulesData)
    XCTAssertEqual(
      parsedRules?[0].priority, 15, "Shoule parse the rules in descending priority order"
    )
    XCTAssertEqual(
      parsedRules?[1].priority, 10, "Shoule parse the rules in descending priority order"
    )
    XCTAssertEqual(
      parsedRules?[2].priority, 7, "Shoule parse the rules in descending priority order"
    )
  }

  func testParsing() {
    (1 ... 100).forEach { _ in
      if let data = (Fuzzer.randomize(json: self.sampleData) as? [String: Any]) {
        _ = _AEMConfiguration(json: data)
      }
    }
  }

  func testIsSameBusinessID() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()

    XCTAssertTrue(
      configWithBusinessID.isSameBusinessID("test_advertiserid_123") == true,
      "Should return true for the same business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSameBusinessID("test_advertiserid_6666") == true,
      "Should return false for the unexpected business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSameBusinessID(nil) == true,
      "Should return false for nil business ID if the configuration has business ID"
    )

    XCTAssertTrue(
      configWithoutBusinessID.isSameBusinessID(nil) == true,
      "Should return true for nil business ID if the configuration doesn't have business ID"
    )
    XCTAssertFalse(
      configWithoutBusinessID.isSameBusinessID("test_advertiserid_123") == true,
      "Should return false for non-nil business ID if the configuration has business ID"
    )
  }

  func testIsSameValidFromAndBusinessID() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()

    XCTAssertTrue(
      configWithBusinessID.isSame(validFrom: 10000, businessID: "test_advertiserid_123") == true,
      "Should return true for the same validFrom and business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSame(validFrom: 10000, businessID: "test_advertiserid_6666") == true,
      "Should return false for the unexpected validFrom and business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSame(validFrom: 10001, businessID: "test_advertiserid_123") == true,
      "Should return false for the unexpected validFrom and business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSame(validFrom: 10000, businessID: nil) == true,
      "Should return false for the unexpected validFrom and business ID"
    )

    XCTAssertTrue(
      configWithoutBusinessID.isSame(validFrom: 10000, businessID: nil) == true,
      "Should return true for nil business ID if the configuration doesn't have business ID"
    )
    XCTAssertFalse(
      configWithoutBusinessID.isSame(validFrom: 10000, businessID: "test_advertiserid_123") == true,
      "Should return false for the unexpected validFrom and business ID"
    )
    XCTAssertFalse(
      configWithoutBusinessID.isSame(validFrom: 10001, businessID: nil) == true,
      "Should return false for the unexpected validFrom and business ID"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      _AEMConfiguration.supportsSecureCoding,
      "AEM Configuration should support secure coding"
    )
  }

  func testEncodingAndDecoding() throws {
    // swiftlint:disable:next force_unwrapping
    let configuration = _AEMConfiguration(json: sampleData)!
    let decodedObject = try CodabilityTesting.encodeAndDecode(configuration)

    // Test Object
    XCTAssertNotIdentical(configuration, decodedObject)
    XCTAssertNotEqual(configuration, decodedObject) // isEqual method not added yet

    // Test Properties
    XCTAssertEqual(configuration.defaultCurrency, decodedObject.defaultCurrency, .isCodable)
    XCTAssertEqual(configuration.cutoffTime, decodedObject.cutoffTime, .isCodable)
    XCTAssertEqual(configuration.validFrom, decodedObject.validFrom, .isCodable)
    XCTAssertEqual(configuration.mode, decodedObject.mode, .isCodable)
    XCTAssertEqual(configuration.businessID, decodedObject.businessID, .isCodable)
    XCTAssertEqual(
      configuration.conversionValueRules,
      decodedObject.conversionValueRules,
      .isCodable
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "AEMConfiguration should be encodable and decodable"
}

#endif
