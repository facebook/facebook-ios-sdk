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
    businessID: "test_advertiserid_123"
  )! // swiftlint:disable:this force_unwrapping

  static let invocationWithAdvertiserID2 = AEMInvocation(
    campaignID: "test_campaign_1235",
    acsToken: "test_token_2345678",
    acsSharedSecret: "test_shared_secret_124",
    acsConfigID: "test_config_id_124",
    businessID: "test_advertiserid_12346"
  )! // swiftlint:disable:this force_unwrapping

  static let invocationWithoutAdvertiserID = AEMInvocation(
    campaignID: "test_campaign_4321",
    acsToken: "test_token_7654",
    acsSharedSecret: "test_shared_secret_123",
    acsConfigID: "test_config_id_333",
    businessID: nil
  )! // swiftlint:disable:this force_unwrapping
}
