/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import Foundation

enum SampleAEMConfigurations {

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
    static let paramRule = "param_rule"
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let defaultMode = "DEFAULT"
    static let USD = "USD"
  }

  static func createConfigWithBusinessID() -> AEMConfiguration {
    let advertiserRuleFactory = AEMAdvertiserRuleFactory()

    AEMConfiguration.configure(withRuleProvider: advertiserRuleFactory)

    return AEMConfiguration(
      json: [
        Keys.defaultCurrency: Values.USD,
        Keys.cutoffTime: 1,
        Keys.validFrom: 10000,
        Keys.configMode: Values.defaultMode,
        Keys.businessID: "test_advertiserid_123",
        Keys.paramRule: "{\"and\":[{\"value\":{\"contains\":\"abc\"}}]}",
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
    )! // swiftlint:disable:this force_unwrapping
  }

  static func createConfigWithBusinessIDAndContentRule() -> AEMConfiguration {
    let advertiserRuleFactory = AEMAdvertiserRuleFactory()

    AEMConfiguration.configure(withRuleProvider: advertiserRuleFactory)

    return AEMConfiguration(
      json: [
        Keys.defaultCurrency: Values.USD,
        Keys.cutoffTime: 1,
        Keys.validFrom: 10000,
        Keys.configMode: Values.defaultMode,
        Keys.businessID: "test_advertiserid_content_test",
        Keys.paramRule: "{\"or\":[{\"fb_content[*].id\":{\"eq\":\"abc\"}}]}",
        Keys.conversionValueRules: [
          [
            Keys.conversionValue: 2,
            Keys.priority: 10,
            Keys.events: [
              [
                Keys.eventName: Values.purchase,
              ],
            ],
          ]
        ]
      ]
    )! // swiftlint:disable:this force_unwrapping
  }

  static func createConfigWithoutBusinessID() -> AEMConfiguration {
    let advertiserRuleFactory = AEMAdvertiserRuleFactory()

    AEMConfiguration.configure(withRuleProvider: advertiserRuleFactory)

    return AEMConfiguration(
      json: [
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
    )! // swiftlint:disable:this force_unwrapping
  }
}
