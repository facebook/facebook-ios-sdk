/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import TestTools
import XCTest

#if !os(tvOS)

class AEMConfigurationTests: XCTestCase {

  enum Keys {
    static let defaultCurrency = "default_currency"
    static let cutoffTime = "cutoff_time"
    static let validFrom = "valid_from"
    static let configMode = "config_mode"
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
    Keys.configMode: Values.defaultMode,
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
      ]
    ]
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
              Keys.amount: 100
            ],
            [
              Keys.currency: Values.JPY,
              Keys.amount: 1000
            ]
          ]
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
    ]
  ]

  let advertiserRuleFactory = AEMAdvertiserRuleFactory()

  override func setUp() {
    super.setUp()

    AEMConfiguration.configure(withRuleProvider: advertiserRuleFactory)
  }

  func testConfiguration() {
    XCTAssertEqual(
      AEMConfiguration.ruleProvider() as! AEMAdvertiserRuleFactory, // swiftlint:disable:this force_cast
      advertiserRuleFactory,
      "Should configure the AEMConfiguration correctly"
    )
  }

  func testValidCases() {
    let config = AEMConfiguration(json: sampleData)

    XCTAssertEqual(
      config?.defaultCurrency,
      Values.USD,
      "Should parse the expected default_currency with the correct value"
    )
    XCTAssertEqual(
      config?.cutoffTime,
      1,
      "Should parse the expected cutoff_time with the correct value"
    )
    XCTAssertEqual(
      config?.validFrom,
      10000,
      "Should parse the expected valid_from with the correct value"
    )
    XCTAssertEqual(
      config?.configMode,
      Values.defaultMode,
      "Should parse the expected config_mode with the correct value"
    )
    XCTAssertEqual(
      config?.businessID,
      Values.coffeeBrand,
      "Should parse the expected business_id with the correct value"
    )
    XCTAssertEqual(
      config?.conversionValueRules.count,
      1,
      "Should parse the expected conversion_value_rules with the correct value"
    )
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(AEMConfiguration(json: invalidData))
    invalidData = [
      Keys.defaultCurrency: 100,
      Keys.cutoffTime: 1,
      Keys.validFrom: 10000,
      Keys.configMode: Values.defaultMode,
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
        ]
      ]
    ]
    XCTAssertNil(
      AEMConfiguration(json: invalidData),
      "Should not consider the config json valid with unexpected type for default_currency"
    )
    invalidData = [
      Keys.defaultCurrency: Values.USD,
      Keys.cutoffTime: 1,
      Keys.validFrom: 10000,
      Keys.configMode: Values.defaultMode
    ]
    XCTAssertNil(
      AEMConfiguration(json: invalidData),
      "Should not consider the config json valid without any conversion value rules"
    )
    invalidData = [
      Keys.defaultCurrency: Values.USD,
      Keys.cutoffTime: 1,
      Keys.validFrom: 10000,
      Keys.configMode: Values.defaultMode,
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
        ]
      ]
    ]
    XCTAssertNil(
      AEMConfiguration(json: invalidData),
      "Should not consider the config json valid with invalid conversion value rule"
    )
  }

  func testGetEventSet() {
    guard let parsedRules: [FBAEMRule] = AEMConfiguration.parseRules(rulesData)
    else { return XCTFail("Unwrapping Error") }
    let eventSet = AEMConfiguration.getEventSet(from: parsedRules)
    XCTAssertEqual(eventSet, [Values.purchase, Values.donate], "Should get the expected event set")
  }

  func testGetCurrencySet() {
    guard let parsedRules: [FBAEMRule] = AEMConfiguration.parseRules(rulesData)
    else { return XCTFail("Unwrapping Error") }
    let eventSet = AEMConfiguration.getCurrencySet(from: parsedRules)
    XCTAssertEqual(eventSet, [Values.USD, Values.JPY], "Should get the expected event set")
  }

  func testParseRules() {
    let parsedRules: [FBAEMRule]? = AEMConfiguration.parseRules(rulesData)
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
        _ = AEMConfiguration(json: data)
      }
    }
  }

  func testIsSameBusinessID() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()

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
      "Should return false for nil business ID if the config has business ID"
    )

    XCTAssertTrue(
      configWithoutBusinessID.isSameBusinessID(nil) == true,
      "Should return true for nil business ID if the config doesn't have business ID"
    )
    XCTAssertFalse(
      configWithoutBusinessID.isSameBusinessID("test_advertiserid_123") == true,
      "Should return false for non-nil business ID if the config has business ID"
    )
  }

  func testIsSameValidFromAndBusinessID() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()

    XCTAssertTrue(
      configWithBusinessID.isSameValid(from: 10000, businessID: "test_advertiserid_123") == true,
      "Should return true for the same validFrom and business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSameValid(from: 10000, businessID: "test_advertiserid_6666") == true,
      "Should return false for the unexpected validFrom and business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSameValid(from: 10001, businessID: "test_advertiserid_123") == true,
      "Should return false for the unexpected validFrom and business ID"
    )
    XCTAssertFalse(
      configWithBusinessID.isSameValid(from: 10000, businessID: nil) == true,
      "Should return false for the unexpected validFrom and business ID"
    )

    XCTAssertTrue(
      configWithoutBusinessID.isSameValid(from: 10000, businessID: nil) == true,
      "Should return true for nil business ID if the config doesn't have business ID"
    )
    XCTAssertFalse(
      configWithoutBusinessID.isSameValid(from: 10000, businessID: "test_advertiserid_123") == true,
      "Should return false for the unexpected validFrom and business ID"
    )
    XCTAssertFalse(
      configWithoutBusinessID.isSameValid(from: 10001, businessID: nil) == true,
      "Should return false for the unexpected validFrom and business ID"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      AEMConfiguration.supportsSecureCoding,
      "AEM Configuration should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    let config = AEMConfiguration(json: sampleData)
    config?.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject[Keys.defaultCurrency] as? String,
      config?.defaultCurrency,
      "Should encode the expected default_currency with the correct key"
    )
    let cutoffTime = coder.encodedObject[Keys.cutoffTime] as? NSNumber
    XCTAssertEqual(
      cutoffTime?.intValue,
      config?.cutoffTime,
      "Should encode the expected cutoff_time with the correct key"
    )
    let validFrom = coder.encodedObject[Keys.validFrom] as? NSNumber
    XCTAssertEqual(
      validFrom?.intValue,
      config?.validFrom,
      "Should encode the expected valid_from with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.configMode] as? String,
      config?.configMode,
      "Should encode the expected config_mode with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.businessID] as? String,
      config?.businessID,
      "Should encode the expected business_id with the correct key"
    )
    XCTAssertTrue(
      coder.encodedObject[Keys.paramRule] is FBAEMAdvertiserRuleMatching,
      "Should encode the expected param_rule with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.conversionValueRules] as? [FBAEMRule],
      config?.conversionValueRules,
      "Should encode the expected conversion_value_rules with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AEMConfiguration(coder: decoder)

    XCTAssertTrue(
      decoder.decodedObject[Keys.defaultCurrency] is NSString.Type,
      "Should decode the expected type for the default_currency key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.cutoffTime] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the cutoff_time key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.validFrom] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the valid_from key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.configMode] is NSString.Type,
      "Should decode the expected type for the config_mode key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.businessID] is NSString.Type,
      "Should decode the expected type for the business_id key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.paramRule] as? NSSet,
      [NSArray.self, AEMAdvertiserMultiEntryRule.self, AEMAdvertiserSingleEntryRule.self],
      "Should decode the expected type for the param_rule key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.conversionValueRules] as? NSSet,
      [NSArray.self, FBAEMEvent.self, FBAEMRule.self],
      "Should decode the expected type for the conversion_value_rules key"
    )
  }
}

#endif
