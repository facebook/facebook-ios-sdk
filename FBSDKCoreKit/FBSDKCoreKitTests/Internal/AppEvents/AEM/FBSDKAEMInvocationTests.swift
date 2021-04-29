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

import XCTest

class FBSDKAEMInvocationTests: XCTestCase { // swiftlint:disable:this type_body_length

    enum Keys {
        static let campaignID = "campaign_ids"
        static let ACSToken = "acs_token"
        static let ACSSharedSecret = "shared_secret"
        static let ACSConfigID = "acs_config_id"
        static let advertiserID = "advertiser_id"
        static let timestamp = "timestamp"
        static let configMode = "config_mode"
        static let configID = "config_id"
        static let recordedEvents = "recorded_events"
        static let recordedValues = "recorded_values"
        static let conversionValues = "conversion_values"
        static let priority = "priority"
        static let conversionTimestamp = "conversion_timestamp"
        static let isAggregated = "is_aggregated"
        static let defaultCurrency = "default_currency"
        static let cutoffTime = "cutoff_time"
        static let validFrom = "valid_from"
        static let conversionValueRules = "conversion_value_rules"
        static let conversionValue = "conversion_value"
        static let events = "events"
        static let eventName = "event_name"
        static let values = "values"
        static let currency = "currency"
        static let amount = "amount"
    }

    enum Values {
        static let purchase = "fb_mobile_purchase"
        static let donate = "Donate"
        static let unlock = "fb_unlock_level"
        static let test = "fb_test_event"
        static let defaultMode = "DEFAULT"
        static let USD = "USD"
    }

    var validInvocation: FBSDKAEMInvocation! // swiftlint:disable:this implicitly_unwrapped_optional
      = FBSDKAEMInvocation(
        campaignID: "test_campaign_1234",
        acsToken: "test_token_12345",
        acsSharedSecret: "test_shared_secret",
        acsConfigID: "test_config_123",
        advertiserID: "test_advertiserid_coffee",
        timestamp: Date(timeIntervalSince1970: 1618383600),
        configMode: "DEFAULT",
        configID: 10,
        recordedEvents: nil,
        recordedValues: nil,
        conversionValue: -1,
        priority: -1,
        conversionTimestamp: Date(timeIntervalSince1970: 1618383700),
        isAggregated: false
      )
    var config1: FBSDKAEMConfiguration!  // swiftlint:disable:this implicitly_unwrapped_optional
      = FBSDKAEMConfiguration(json: [
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
          ],
          [
            Keys.conversionValue: 1,
            Keys.priority: 11,
            Keys.events: [
              [
                Keys.eventName: Values.purchase,
                Keys.values: [
                  [
                    Keys.currency: Values.USD,
                    Keys.amount: 100
                  ]
                ]
              ],
              [
                Keys.eventName: Values.unlock,
              ],
            ],
          ]
        ]
      ])
    var config2: FBSDKAEMConfiguration! // swiftlint:disable:this implicitly_unwrapped_optional
      = FBSDKAEMConfiguration(json: [
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
              [
                Keys.eventName: Values.donate,
              ],
            ],
          ]
        ]
      ])

    func testInvocationWithInvalidAppLinkData() {
        var invalidData: [String: Any] = [:]

        XCTAssertNil(FBSDKAEMInvocation(appLinkData: nil))

        invalidData = [
          "acs_token": "test_token_12345",
        ]
        XCTAssertNil(FBSDKAEMInvocation(appLinkData: invalidData))

        invalidData = [
          "campaign_ids": "test_campaign_1234",
        ]
        XCTAssertNil(FBSDKAEMInvocation(appLinkData: invalidData))

        invalidData = [
          "advertiser_id": "test_advertiserid_coffee",
        ]
        XCTAssertNil(FBSDKAEMInvocation(appLinkData: invalidData))

        invalidData = [
          "acs_token": 123,
          "campaign_ids": 123,
        ]
        XCTAssertNil(FBSDKAEMInvocation(appLinkData: invalidData))
    }

    func testInvocationWithValidAppLinkData() {
        var validData: [String: Any] = [:]
        var invocation: FBSDKAEMInvocation?

        validData = [
          "acs_token": "test_token_12345",
          "campaign_ids": "test_campaign_1234",
        ]
        invocation = FBSDKAEMInvocation(appLinkData: validData)
        XCTAssertEqual(invocation?.acsToken, "test_token_12345")
        XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
        XCTAssertNil(invocation?.advertiserID)

        validData = [
          "acs_token": "test_token_12345",
          "campaign_ids": "test_campaign_1234",
          "advertiser_id": "test_advertiserid_coffee",
        ]
        invocation = FBSDKAEMInvocation(appLinkData: validData)
        XCTAssertEqual(invocation?.acsToken, "test_token_12345")
        XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
        XCTAssertEqual(invocation?.advertiserID, "test_advertiserid_coffee")
    }

  func testFindConfig() {
    var invocation: FBSDKAEMInvocation? = self.validInvocation
    invocation?.reset()
    invocation?.setConfigID(10)
    XCTAssertNil(
      invocation?._findConfig([Values.defaultMode: [config1, config2]]),
      "Should not find the config with unmatched configID"
    )

    invocation = FBSDKAEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      advertiserID: "test_advertiserid_coffee"
    )
    let config = invocation?._findConfig([Values.defaultMode: [config1, config2]])
    XCTAssertEqual(invocation?.configID, 20000, "Should set the invocation with expected configID")
    XCTAssertEqual(invocation?.configMode, Values.defaultMode, "Should set the invocation with expected configMode")
    XCTAssertEqual(config?.validFrom, config2.validFrom, "Should find the expected config")
    XCTAssertEqual(config?.configMode, config2.configMode, "Should find the expected config")
  }

  func testAttributeEventWithValue() {
    let invocation: FBSDKAEMInvocation = self.validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    var isAttributed = invocation.attributeEvent(
      Values.test, currency: Values.USD, value: 10, configs: [Values.defaultMode: [config1, config2]]
    )
    XCTAssertFalse(isAttributed, "Should not attribute unexpected event")
    XCTAssertFalse(
      invocation.recordedEvents.contains(Values.test),
      "Should not add events that cannot be attributed to the invocation"
    )
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")

    isAttributed = invocation.attributeEvent(
      Values.purchase, currency: Values.USD, value: 10, configs: [Values.defaultMode: [config1, config2]]
    )
    XCTAssertTrue(isAttributed, "Should attribute expected event")
    XCTAssertTrue(
      invocation.recordedEvents.contains(Values.purchase),
      "Should add events that can be attributed to the invocation"
    )
    XCTAssertEqual(invocation.recordedValues, [Values.purchase: [Values.USD: 10]], "Should attribute unexpected values")
  }

  func testAttributeUnexpectedEventWithoutValue() {
    let invocation: FBSDKAEMInvocation = self.validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    let isAttributed = invocation.attributeEvent(
      Values.test, currency: nil, value: nil, configs: [Values.defaultMode: [config1, config2]]
    )
    XCTAssertFalse(isAttributed, "Should not attribute unexpected event")
    XCTAssertFalse(invocation.recordedEvents.contains(Values.test))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")
  }

  func testAttributeExpectedEventWithoutValue() {
    let invocation: FBSDKAEMInvocation = self.validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    var isAttributed = invocation.attributeEvent(
      Values.purchase, currency: nil, value: nil, configs: [Values.defaultMode: [config1, config2]]
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertTrue(invocation.recordedEvents.contains(Values.purchase))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")

    isAttributed = invocation.attributeEvent(
      Values.donate, currency: nil, value: nil, configs: [Values.defaultMode: [config1, config2]]
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertTrue(invocation.recordedEvents.contains(Values.donate))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")
  }

  func testUpdateConversionWithValue() {
    let invocation: FBSDKAEMInvocation = self.validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.unlock]))
    XCTAssertFalse(
      invocation.updateConversionValue(withConfigs: [Values.defaultMode: [config1, config2]]),
      "Should not update conversion value"
    )

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.donate]))
    XCTAssertTrue(
      invocation.updateConversionValue(withConfigs: [Values.defaultMode: [config1, config2]]),
      "Should update conversion value"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      2,
      "Should update the expected conversion value"
    )

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.unlock]))
    invocation.setRecordedValues(NSMutableDictionary(dictionary: [Values.purchase: [Values.USD: 100]]))
    XCTAssertTrue(
      invocation.updateConversionValue(withConfigs: [Values.defaultMode: [config1, config2]]),
      "Should update conversion value"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      1,
      "Should update the expected conversion value"
    )

    invocation.reset()
    invocation.setPriority(100)
    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.unlock]))
    invocation.setRecordedValues(NSMutableDictionary(dictionary: [Values.purchase: [Values.USD: 100]]))
    XCTAssertFalse(
      invocation.updateConversionValue(withConfigs: [Values.defaultMode: [config1, config2]]),
      "Should not update conversion value under priority"
    )
  }

  func testUpdateConversionWithouValue() {
    let invocation: FBSDKAEMInvocation = self.validInvocation
    invocation.reset()
    invocation._setConfig(config2)

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase]))
    XCTAssertFalse(
      invocation.updateConversionValue(withConfigs: [Values.defaultMode: [config1, config2]]),
      "Should not update conversion value"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      -1,
      "Should not update the unexpected conversion value"
    )

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.donate]))
    XCTAssertTrue(
      invocation.updateConversionValue(withConfigs: [Values.defaultMode: [config1, config2]]),
      "Should update conversion value"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      2,
      "Should update the expected conversion value"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      FBSDKAEMInvocation.supportsSecureCoding,
      "AEM Invocation should support secure coding"
    )
  }

  func testEncoding() { // swiftlint:disable:this function_body_length
    let coder = TestCoder()
    let invocation: FBSDKAEMInvocation = self.validInvocation
    invocation.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject[Keys.campaignID] as? String,
      invocation.campaignID,
      "Should encode the expected campaignID with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.ACSToken] as? String,
      invocation.acsToken,
      "Should encode the expected acsToken with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.ACSSharedSecret] as? String,
      invocation.acsSharedSecret,
      "Should encode the expected ACSSharedSecret with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.ACSConfigID] as? String,
      invocation.acsConfigID,
      "Should encode the expected acsConfigID with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.timestamp] as? Date,
      invocation.timestamp,
      "Should encode the expected timestamp with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.configMode] as? String,
      invocation.configMode,
      "Should encode the expected configMode with the correct key"
    )
    let configID = coder.encodedObject[Keys.configID] as? NSNumber
    XCTAssertEqual(
      configID?.intValue,
      invocation.configID,
      "Should encode the expected configID with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.recordedEvents] as? NSSet,
      invocation.recordedEvents,
      "Should encode the expected recordedEvents with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.recordedValues] as? NSDictionary,
      invocation.recordedValues,
      "Should encode the expected recordedValues with the correct key"
    )
    let conversionValue = coder.encodedObject[Keys.conversionValue] as? NSNumber
    XCTAssertEqual(
      conversionValue?.intValue,
      invocation.conversionValue,
      "Should encode the expected conversionValue with the correct key"
    )
    let priority = coder.encodedObject[Keys.priority] as? NSNumber
    XCTAssertEqual(
      priority?.intValue,
      invocation.priority,
      "Should encode the expected priority with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.conversionTimestamp] as? Date,
      invocation.conversionTimestamp,
      "Should encode the expected conversionTimestamp with the correct key"
    )
    let isAggregated = coder.encodedObject[Keys.isAggregated] as? NSNumber
    XCTAssertEqual(
      isAggregated?.boolValue,
      invocation.isAggregated,
      "Should encode the expected isAggregated with the correct key"
    )
  }

  func testDecoding() { // swiftlint:disable:this function_body_length
    let decoder = TestCoder()
    _ = FBSDKAEMInvocation(coder: decoder)

    XCTAssertTrue(
      decoder.decodedObject[Keys.campaignID] is NSString.Type,
      "Should decode the expected type for the campaign_id key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ACSToken] is NSString.Type,
      "Should decode the expected type for the acs_token key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ACSSharedSecret] is NSString.Type,
      "Should decode the expected type for the shared_secret key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ACSConfigID] is NSString.Type,
      "Should decode the expected type for the acs_config_id key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.advertiserID] is NSString.Type,
      "Should decode the expected type for the advertiser_id key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.timestamp] is NSDate.Type,
      "Should decode the expected type for the timestamp key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.configMode] is NSString.Type,
      "Should decode the expected type for the config_mode key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.configID] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the config_id key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.recordedEvents] is NSSet.Type,
      "Should decode the expected type for the recorded_events key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.recordedValues] is NSDictionary.Type,
      "Should decode the expected type for the recorded_values key"
    )
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
    XCTAssertTrue(
      decoder.decodedObject[Keys.conversionTimestamp] is NSDate.Type,
      "Should decode the expected type for the conversion_timestamp key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.isAggregated] as? String,
      "decodeBoolForKey",
      "Should decode the expected type for the is_aggregated key"
    )
  }
} // swiftlint:disable:this file_length
