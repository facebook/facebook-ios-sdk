/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit
import Foundation

final class SampleAEMData { // swiftlint:disable:this convenience_type

  enum Keys {
    static let defaultCurrency = "default_currency"
    static let cutoffTime = "cutoff_time"
    static let validFrom = "valid_from"
    static let mode = "config_mode"
    static let conversionValueRules = "conversion_value_rules"
    static let conversionValue = "conversion_value"
    static let priority = "priority"
    static let events = "events"
    static let eventName = "event_name"
    static let businessID = "advertiser_id"
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let defaultMode = "DEFAULT"
    static let USD = "USD"
  }

  static let validConfigurationData1: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
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

  static let validConfigurationData2: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 10001,
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
      [
        Keys.conversionValue: 3,
        Keys.priority: 11,
        Keys.events: [
          [
            Keys.eventName: Values.purchase,
          ],
        ],
      ],
    ],
  ]

  static let validConfigData3: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 20000,
    Keys.mode: Values.defaultMode,
    Keys.conversionValueRules: [
      [
        Keys.conversionValue: 2,
        Keys.priority: 10,
        Keys.events: [
          [
            Keys.eventName: Values.purchase,
          ],
        ],
      ],
    ],
  ]

  static let validAdvertiserSingleEntryRule = _AEMAdvertiserSingleEntryRule(
    with: .contains,
    paramKey: "test",
    linguisticCondition: "hello",
    numericalCondition: 10.0,
    arrayCondition: ["abv"]
  )

  static let validAdvertiserMultiEntryRule = _AEMAdvertiserMultiEntryRule(
    with: .and,
    rules: [validAdvertiserSingleEntryRule]
  )

  static let validAdvertiserSingleEntryRuleJson1: [String: Any] = ["content": ["starts_with": "abc"]]

  static let validAdvertiserSingleEntryRuleJson2: [String: Any] = ["value": ["lt": 10]]

  static let validAdvertiserSingleEntryRuleJson3: [String: Any] = ["content": ["is_any": ["abc"]]]

  static let advertiserSingleEntryRule1 = _AEMAdvertiserSingleEntryRule(
    with: .startsWith,
    paramKey: "content",
    linguisticCondition: "abc",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let advertiserSingleEntryRule2 = _AEMAdvertiserSingleEntryRule(
    with: .lessThan,
    paramKey: "value",
    linguisticCondition: nil,
    numericalCondition: 10,
    arrayCondition: nil
  )

  static let advertiserSingleEntryRule3 = _AEMAdvertiserSingleEntryRule(
    with: .isAny,
    paramKey: "content",
    linguisticCondition: nil,
    numericalCondition: nil,
    arrayCondition: ["abc"]
  )

  static let invocationWithAdvertiserID1 = _AEMInvocation(
    campaignID: "test_campaign_1234",
    acsToken: "test_token_1234567",
    acsSharedSecret: "test_shared_secret",
    acsConfigurationID: "test_config_id_123",
    businessID: "test_advertiserid_123",
    catalogID: nil,
    isTestMode: false,
    hasStoreKitAdNetwork: false,
    isConversionFilteringEligible: true
  )! // swiftlint:disable:this force_unwrapping

  static let invocationWithAdvertiserID2 = _AEMInvocation(
    campaignID: "test_campaign_1235",
    acsToken: "test_token_2345678",
    acsSharedSecret: "test_shared_secret_124",
    acsConfigurationID: "test_config_id_124",
    businessID: "test_advertiserid_12346",
    catalogID: nil,
    isTestMode: false,
    hasStoreKitAdNetwork: false,
    isConversionFilteringEligible: true
  )! // swiftlint:disable:this force_unwrapping

  static let invocationWithoutAdvertiserID = _AEMInvocation(
    campaignID: "test_campaign_4321",
    acsToken: "test_token_7654",
    acsSharedSecret: "test_shared_secret_123",
    acsConfigurationID: "test_config_id_333",
    businessID: nil,
    catalogID: nil,
    isTestMode: false,
    hasStoreKitAdNetwork: false,
    isConversionFilteringEligible: true
  )! // swiftlint:disable:this force_unwrapping
}
