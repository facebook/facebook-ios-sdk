/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import Foundation

class SampleAEMData { // swiftlint:disable:this convenience_type

  enum Keys {
    static let defaultCurrency = "default_currency"
    static let cutoffTime = "cutoff_time"
    static let validFrom = "valid_from"
    static let configMode = "config_mode"
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

  static let validConfigData1: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
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

  static let validConfigData2: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 10001,
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
      ],
      [
        Keys.conversionValue: 3,
        Keys.priority: 11,
        Keys.events: [
          [
            Keys.eventName: Values.purchase,
          ],
        ],
      ]
    ]
  ]

  static let validConfigData3: [String: Any] = [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 20000,
    Keys.configMode: Values.defaultMode,
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
    ]
  ]

  static let validAdvertiserSingleEntryRule: AEMAdvertiserSingleEntryRule
    = AEMAdvertiserSingleEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorContains,
      paramKey: "test",
      linguisticCondition: "hello",
      numericalCondition: NSNumber(10),
      arrayCondition: ["abv"]
    )

  static let validAdvertiserMultiEntryRule: AEMAdvertiserMultiEntryRule
    = AEMAdvertiserMultiEntryRule(
      with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorAnd,
      rules: [validAdvertiserSingleEntryRule]
    )

  static let validAdvertiserSingleEntryRuleJson1: [String: Any] = ["content": ["starts_with": "abc"]]

  static let validAdvertiserSingleEntryRuleJson2: [String: Any] = ["value": ["lt": 10]]

  static let validAdvertiserSingleEntryRuleJson3: [String: Any] = ["content": ["is_any": ["abc"]]]

  static let advertiserSingleEntryRule1 = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorStartsWith,
    paramKey: "content",
    linguisticCondition: "abc",
    numericalCondition: nil,
    arrayCondition: nil
  )

  static let advertiserSingleEntryRule2 = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorLessThan,
    paramKey: "value",
    linguisticCondition: nil,
    numericalCondition: NSNumber(value: 10),
    arrayCondition: nil
  )

  static let advertiserSingleEntryRule3 = AEMAdvertiserSingleEntryRule(
    with: AEMAdvertiserRuleOperator.FBAEMAdvertiserRuleOperatorIsAny,
    paramKey: "content",
    linguisticCondition: nil,
    numericalCondition: nil,
    arrayCondition: ["abc"]
  )

  static let invocationWithAdvertiserID1 = AEMInvocation(
    campaignID: "test_campaign_1234",
    acsToken: "test_token_1234567",
    acsSharedSecret: "test_shared_secret",
    acsConfigID: "test_config_id_123",
    businessID: "test_advertiserid_123",
    catalogID: nil,
    isTestMode: false,
    hasSKAN: false
  )! // swiftlint:disable:this force_unwrapping

  static let invocationWithAdvertiserID2 = AEMInvocation(
    campaignID: "test_campaign_1235",
    acsToken: "test_token_2345678",
    acsSharedSecret: "test_shared_secret_124",
    acsConfigID: "test_config_id_124",
    businessID: "test_advertiserid_12346",
    catalogID: nil,
    isTestMode: false,
    hasSKAN: false
  )! // swiftlint:disable:this force_unwrapping

  static let invocationWithoutAdvertiserID = AEMInvocation(
    campaignID: "test_campaign_4321",
    acsToken: "test_token_7654",
    acsSharedSecret: "test_shared_secret_123",
    acsConfigID: "test_config_id_333",
    businessID: nil,
    catalogID: nil,
    isTestMode: false,
    hasSKAN: false
  )! // swiftlint:disable:this force_unwrapping
}
