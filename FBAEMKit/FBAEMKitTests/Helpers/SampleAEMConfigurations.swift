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
