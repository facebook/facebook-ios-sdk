/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import XCTest

class FBAEMInvocationTests: XCTestCase {

  enum Keys {
    static let campaignID = "campaign_ids"
    static let ACSToken = "acs_token"
    static let ACSSharedSecret = "shared_secret"
    static let ACSConfigID = "acs_config_id"
    static let advertiserID = "advertiser_id"
    static let businessID = "advertiser_id"
    static let catalogID = "catalog_id"
    static let timestamp = "timestamp"
    static let configMode = "config_mode"
    static let configID = "config_id"
    static let recordedEvents = "recorded_events"
    static let recordedValues = "recorded_values"
    static let conversionValues = "conversion_values"
    static let priority = "priority"
    static let conversionTimestamp = "conversion_timestamp"
    static let isAggregated = "is_aggregated"
    static let hasSKAN = "has_skan"
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
    static let paramRule = "param_rule"
    static let content = "fb_content"
    static let contentID = "fb_content_id"
    static let contentType = "fb_content_type"
    static let identity = "id"
    static let itemPrice = "item_price"
    static let quantity = "quantity"
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let unlock = "fb_unlock_level"
    static let test = "fb_test_event"
    static let defaultMode = "DEFAULT"
    static let brandMode = "BRAND"
    static let cpasMode = "CPAS"
    static let USD = "USD"
  }

  let boostPriority = 32

  var validInvocation = AEMInvocation(
    campaignID: "test_campaign_1234",
    acsToken: "test_token_12345",
    acsSharedSecret: "test_shared_secret",
    acsConfigID: "test_config_123",
    businessID: "test_advertiserid_coffee",
    catalogID: "test_catalog_123",
    timestamp: Date(timeIntervalSince1970: 1618383600),
    configMode: "DEFAULT",
    configID: 10,
    recordedEvents: nil,
    recordedValues: nil,
    conversionValue: -1,
    priority: -1,
    conversionTimestamp: Date(timeIntervalSince1970: 1618383700),
    isAggregated: false,
    isTestMode: false,
    hasSKAN: false,
    isConversionFilteringEligible: true
  )! // swiftlint:disable:this force_unwrapping

  var config1 = AEMConfiguration(json: [
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
  ])! // swiftlint:disable:this force_unwrapping

  var config2 = AEMConfiguration(json: [
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
  ])! // swiftlint:disable:this force_unwrapping

  func testInvocationWithInvalidAppLinkData() {
    var invalidData: [String: Any] = [:]

    XCTAssertNil(AEMInvocation(appLinkData: nil))

    invalidData = [
      "acs_token": "test_token_12345",
    ]
    XCTAssertNil(AEMInvocation(appLinkData: invalidData))

    invalidData = [
      "campaign_ids": "test_campaign_1234",
    ]
    XCTAssertNil(AEMInvocation(appLinkData: invalidData))

    invalidData = [
      "advertiser_id": "test_advertiserid_coffee",
    ]
    XCTAssertNil(AEMInvocation(appLinkData: invalidData))

    invalidData = [
      "acs_token": 123,
      "campaign_ids": 123,
    ]
    XCTAssertNil(AEMInvocation(appLinkData: invalidData))
  }

  func testInvocationWithValidAppLinkData() {
    var validData: [String: Any] = [:]
    var invocation: AEMInvocation?

    validData = [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
    ]
    invocation = AEMInvocation(appLinkData: validData)
    XCTAssertEqual(invocation?.acsToken, "test_token_12345")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertNil(invocation?.businessID)

    validData = [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
    ]
    invocation = AEMInvocation(appLinkData: validData)
    XCTAssertEqual(invocation?.acsToken, "test_token_12345")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertEqual(invocation?.businessID, "test_advertiserid_coffee")
  }

  func testInvocationWithCatalogID() {
    let invocation = AEMInvocation(appLinkData: [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
      "catalog_id": "test_catalog_1234"
    ])

    XCTAssertEqual(
      invocation?.acsToken,
      "test_token_12345",
      "Invocation's ACS token is not expected"
    )
    XCTAssertEqual(
      invocation?.campaignID,
      "test_campaign_1234",
      "Invocation's campaign ID is not expected"
    )
    XCTAssertEqual(
      invocation?.businessID,
      "test_advertiserid_coffee",
      "Invocation's business ID is not expected"
    )
    XCTAssertEqual(
      invocation?.catalogID,
      "test_catalog_1234",
      "Invocation's catalog ID is not expected"
    )
  }

  func testInvocationWithoutCatalogID() {
    let invocation = AEMInvocation(appLinkData: [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee"
    ])

    XCTAssertNotNil(
      invocation,
      "Invocation is not expected to be nil"
    )
    XCTAssertNil(
      invocation?.catalogID,
      "Invocation's catalog ID is expected to be nil"
    )
  }

  func testInvocationWithDebuggingAppLinkData() throws {
    let data = [
      "acs_token": "debuggingtoken",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
      "test_deeplink": 1
    ] as [String: Any]
    let invocation = try XCTUnwrap(AEMInvocation(appLinkData: data))

    XCTAssertTrue(
      invocation.isTestMode,
      "Invocation is expected to be test mode when test_deeplink is true"
    )
    XCTAssertEqual(
      invocation.acsToken,
      "debuggingtoken",
      "Invocations's acsToken is not expected"
    )
    XCTAssertEqual(
      invocation.campaignID,
      "test_campaign_1234",
      "Invocations's campaignID is not expected"
    )
  }

  func testInvocationWithSKANInfoAppLinkData() throws {
    let data = [
      "acs_token": "debuggingtoken",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
      "has_skan": true
    ] as [String: Any]
    let invocation = try XCTUnwrap(AEMInvocation(appLinkData: data))

    XCTAssertTrue(
      invocation.hasSKAN,
      "Invocation's hasSKAN is expected to be true when has_skan is true"
    )
    XCTAssertEqual(
      invocation.acsToken,
      "debuggingtoken",
      "Invocations's acsToken is not expected"
    )
    XCTAssertEqual(
      invocation.campaignID,
      "test_campaign_1234",
      "Invocations's campaignID is not expected"
    )
  }

  func testProcessedParametersWithValidContentAndContentID() {
    let invocation: AEMInvocation? = validInvocation
    let content: [String: AnyHashable] = ["id": "123", "quantity": 5]
    let contentIDs: [String] = ["id123", "id456"]

    let parameters = invocation?.processedParameters([
      Keys.content: #"[{"id": "123", "quantity": 5}]"#,
      Keys.contentID: #"["id123", "id456"]"#,
      Keys.contentType: "product"
    ]) as? [String: AnyHashable]
    XCTAssertEqual(
      parameters,
      [
        Keys.content: [content],
        Keys.contentID: contentIDs,
        Keys.contentType: "product"
      ],
      "Processed parameters are not expected"
    )
  }

  func testProcessedParametersWithValidContent() {
    let invocation: AEMInvocation? = validInvocation
    let content: [String: AnyHashable] = ["id": "123", "quantity": 5]

    let parameters = invocation?.processedParameters([
      Keys.content: #"[{"id": "123", "quantity": 5}]"#,
      Keys.contentID: "001",
      Keys.contentType: "product"
    ]) as? [String: AnyHashable]
    XCTAssertEqual(
      parameters,
      [
        Keys.content: [content],
        Keys.contentID: "001",
        Keys.contentType: "product"
      ],
      "Processed parameters are not expected"
    )
  }

  func testProcessedParametersWithInvalidContent() {
    let invocation: AEMInvocation? = validInvocation

    let parameters = invocation?.processedParameters([
      Keys.content: #"[{"id": ,"quantity": 5}]"#,
      Keys.contentID: "001",
      Keys.contentType: "product"
    ]) as? [String: AnyHashable]
    XCTAssertEqual(
      parameters,
      [
        Keys.content: #"[{"id": ,"quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product"
      ],
      "Processed parameters are not expected"
    )
  }

  func testFindConfig() {
    var invocation: AEMInvocation? = validInvocation
    invocation?.reset()
    invocation?.setConfigID(10)
    XCTAssertNil(
      invocation?._findConfig([Values.defaultMode: [config1, config2]]),
      "Should not find the config with unmatched configID"
    )

    invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )
    let config = invocation?._findConfig([Values.defaultMode: [config1, config2]])
    XCTAssertEqual(invocation?.configID, 20000, "Should set the invocation with expected configID")
    XCTAssertEqual(invocation?.configMode, Values.defaultMode, "Should set the invocation with expected configMode")
    XCTAssertEqual(config?.validFrom, config2.validFrom, "Should find the expected config")
    XCTAssertEqual(config?.configMode, config2.configMode, "Should find the expected config")
  }

  func testFindConfigWithBusinessID1() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()
    let invocation = validInvocation
    invocation.reset()
    invocation.setConfigID(10000)

    let config = invocation._findConfig([
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID]
    ])
    XCTAssertEqual(
      config?.validFrom,
      10000,
      "Should have expected validFrom"
    )
    XCTAssertNil(
      config?.businessID,
      "Should not have unexpected advertiserID"
    )
  }

  func testFindConfigWithBusinessID2() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()
    let invocation = validInvocation
    invocation.reset()
    invocation.setConfigID(10000)
    invocation.setBusinessID("test_advertiserid_123")

    let config = invocation._findConfig([
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID]
    ])
    XCTAssertEqual(
      config?.validFrom,
      10000,
      "Should have expected validFrom"
    )
    XCTAssertEqual(
      config?.businessID,
      "test_advertiserid_123",
      "Should have expected advertiserID"
    )
  }

  func testFindConfigWithBusinessID3() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessID()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()
    let invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      businessID: "test_advertiserid_123",
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )
    let config = invocation?._findConfig([
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID]
    ])
    XCTAssertEqual(invocation?.configID, 10000, "Should set the invocation with expected configID")
    XCTAssertEqual(invocation?.configMode, Values.defaultMode, "Should set the invocation with expected configMode")
    XCTAssertEqual(
      config?.validFrom,
      configWithBusinessID.validFrom,
      "Should find the expected config"
    )
    XCTAssertEqual(
      config?.configMode,
      configWithBusinessID.configMode,
      "Should find the expected config"
    )
    XCTAssertEqual(
      config?.businessID,
      configWithBusinessID.businessID,
      "Should find the expected config"
    )
  }

  func testFindConfigWithCpas() {
    let cpasConfig = SampleAEMConfigurations.createCpasConfig()
    let invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      businessID: "test_advertiserid_cpas",
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )
    let config = invocation?._findConfig([
      Values.defaultMode: [SampleAEMConfigurations.createConfigWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigWithBusinessIDAndContentRule()],
      Values.cpasMode: [cpasConfig]
    ])
    XCTAssertEqual(invocation?.configID, 10000, "Should set the invocation with expected configID")
    XCTAssertEqual(invocation?.configMode, Values.cpasMode, "Should set the invocation with expected configMode")
    XCTAssertEqual(
      config?.validFrom,
      cpasConfig.validFrom,
      "Should find the expected config"
    )
    XCTAssertEqual(
      config?.configMode,
      cpasConfig.configMode,
      "Should find the expected config"
    )
    XCTAssertEqual(
      config?.businessID,
      cpasConfig.businessID,
      "Should find the expected config"
    )
  }

  func testGetConfigList() {
    let configs = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigWithBusinessIDAndContentRule()],
      Values.cpasMode: [SampleAEMConfigurations.createCpasConfig()]
    ]
    let invocation = SampleAEMInvocations.createGeneralInvocation1()

    var configList = invocation._getConfigList(Values.defaultMode, configs: configs)
    XCTAssertEqual(configList.count, 1, "Should only find the default config")

    configList = invocation._getConfigList(Values.brandMode, configs: configs)
    XCTAssertEqual(configList.count, 2, "Should only find the brand or cpas config")
    XCTAssertEqual(configList.first?.configMode, Values.cpasMode, "Should have the caps config first")
    XCTAssertEqual(configList.last?.configMode, Values.brandMode, "Should have the brand config last")
  }

  func testAttributeEventWithValue() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    var isAttributed = invocation.attributeEvent(
      Values.test,
      currency: Values.USD,
      value: 10,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: true
    )
    XCTAssertFalse(isAttributed, "Should not attribute unexpected event")
    XCTAssertFalse(
      invocation.recordedEvents.contains(Values.test),
      "Should not add events that cannot be attributed to the invocation"
    )
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")

    isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 10,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: true
    )
    XCTAssertTrue(isAttributed, "Should attribute expected event")
    XCTAssertTrue(
      invocation.recordedEvents.contains(Values.purchase),
      "Should add events that can be attributed to the invocation"
    )
    XCTAssertEqual(invocation.recordedValues, [Values.purchase: [Values.USD: 10]], "Should attribute unexpected values")
  }

  func testAttributeUnexpectedEventWithoutValue() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    let isAttributed = invocation.attributeEvent(
      Values.test,
      currency: nil,
      value: nil,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: true
    )
    XCTAssertFalse(isAttributed, "Should not attribute unexpected event")
    XCTAssertFalse(invocation.recordedEvents.contains(Values.test))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")
  }

  func testAttributeExpectedEventWithoutValue() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    var isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: nil,
      value: nil,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: true
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertTrue(invocation.recordedEvents.contains(Values.purchase))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")

    isAttributed = invocation.attributeEvent(
      Values.donate,
      currency: nil,
      value: nil,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: true
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertTrue(invocation.recordedEvents.contains(Values.donate))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")
  }

  func testAttributeEventWithExpectedContent() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessIDAndContentRule()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()
    let invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      businessID: "test_advertiserid_content_test",
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configs = [
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID]
    ]
    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 0,
      parameters: [
        Keys.content: #"[{"id": "abc", "quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product"
      ],
      configs: configs,
      shouldUpdateCache: true
    )
    XCTAssertTrue(isAttributed, "Should attribute the event with expected parameters")
  }

  func testAttributeEventWithUnexpectedContent() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigWithBusinessIDAndContentRule()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigWithoutBusinessID()
    let invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      businessID: "test_advertiserid_content_test",
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configs = [
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID]
    ]
    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 0,
      parameters: [
        Keys.content: #"[{"id": "123", "quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product"
      ],
      configs: configs,
      shouldUpdateCache: true
    )
    XCTAssertFalse(isAttributed, "Should attribute the event with expected parameters")
  }

  func testAttributeCpasEvent() {
    let invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigID: nil,
      businessID: "test_advertiserid_cpas",
      catalogID: nil,
      isTestMode: false,
      hasSKAN: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configs = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigWithoutBusinessID()],
      Values.cpasMode: [SampleAEMConfigurations.createCpasConfig()]
    ]
    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: NSNumber(value: 5000),
      parameters: [
        Keys.content: [
          [
            Keys.identity: "abc",
            Keys.itemPrice: NSNumber(value: 100),
            Keys.quantity: NSNumber(value: 10)
          ],
          [
            Keys.identity: "test",
            Keys.itemPrice: NSNumber(value: 200),
            Keys.quantity: NSNumber(value: 20)
          ]
        ]
      ],
      configs: configs,
      shouldUpdateCache: true
    )
    XCTAssertTrue(
      isAttributed,
      "Should attribute the event"
    )
    XCTAssertEqual(
      invocation.recordedEvents,
      [Values.purchase],
      "Should expect the event is updated in the cache"
    )
    XCTAssertEqual(
      invocation.recordedValues,
      [Values.purchase: [Values.USD: 1000]],
      "Should expect the value is updated in the cache"
    )
  }

  func testAttributeEventWithoutCache() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: nil,
      value: nil,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: false
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertFalse(invocation.recordedEvents.contains(Values.purchase), "Should not update the event cache")
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not update value cache")
  }

  func testAttributeEventAndValueWithoutCache() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 10,
      parameters: nil,
      configs: [Values.defaultMode: [config1, config2]],
      shouldUpdateCache: false
    )
    XCTAssertTrue(isAttributed, "Should attribute expected event")
    XCTAssertFalse(
      invocation.recordedEvents.contains(Values.purchase),
      "Should add events that can be attributed to the invocation"
    )
    XCTAssertEqual(
      invocation.recordedValues.count,
      0,
      "Should not update value cache"
    )
  }

  func testUpdateConversionWithValue() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config1)

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.unlock]))
    XCTAssertFalse(
      invocation.updateConversionValue(
        withConfigs: [Values.defaultMode: [config1, config2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
      "Should not update conversion value"
    )

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.donate]))
    XCTAssertTrue(
      invocation.updateConversionValue(
        withConfigs: [Values.defaultMode: [config1, config2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
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
      invocation.updateConversionValue(
        withConfigs: [Values.defaultMode: [config1, config2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
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
      invocation.updateConversionValue(
        withConfigs: [Values.defaultMode: [config1, config2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
      "Should not update conversion value under priority"
    )
  }

  func testUpdateConversionWithouValue() {
    let invocation: AEMInvocation = validInvocation
    invocation.reset()
    invocation._setConfig(config2)

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase]))
    XCTAssertFalse(
      invocation.updateConversionValue(
        withConfigs: [Values.defaultMode: [config1, config2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
      "Should not update conversion value"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      -1,
      "Should not update the unexpected conversion value"
    )

    invocation.setRecordedEvents(NSMutableSet(array: [Values.purchase, Values.donate]))
    XCTAssertTrue(
      invocation.updateConversionValue(
        withConfigs: [Values.defaultMode: [config1, config2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
      "Should update conversion value"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      2,
      "Should update the expected conversion value"
    )
  }

  func testUpdateConversionWithBoostPriority() {
    let config = SampleAEMConfigurations.createWithMultipleRules()
    let configs = [Values.defaultMode: [config]]
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()

    let lowestPriorityRule = config.conversionValueRules.last! // swiftlint:disable:this force_unwrapping
    // Set the highest priority in the conversion rules
    invocation.setPriority(config.conversionValueRules.first!.priority) // swiftlint:disable:this force_unwrapping
    // Add the lowest priority event
    invocation.setRecordedEvents(
      [lowestPriorityRule.events.first!.eventName] // swiftlint:disable:this force_unwrapping
    )
    XCTAssertTrue(
      invocation.updateConversionValue(withConfigs: configs, event: Values.donate, shouldBoostPriority: true),
      "Should expect to update the conversion value"
    )
    XCTAssertEqual(
      invocation.priority,
      lowestPriorityRule.priority + boostPriority,
      "Should expect the updated priority to be boosted"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      lowestPriorityRule.conversionValue,
      "Should expect the conversion value is updated for the optimized event"
    )
  }

  // Test conversion value updating when optimized event has multiple conversion values
  func testUpdateConversionWithHigherBoostPriority() {
    let config = SampleAEMConfigurations.createWithMultipleRules()
    let configs = [Values.defaultMode: [config]]
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    invocation.campaignID = "83" // The campaign id's modulo is matched to purchase's conversion value

    let highestPriorityRule = config.conversionValueRules.first! // swiftlint:disable:this force_unwrapping
    invocation.setPriority(42) // Set the second highest priority with boost priority in the conversion rules
    invocation.setRecordedEvents([Values.purchase]) // Add the optimzied event
    invocation.setRecordedValues([
      Values.purchase: [Values.USD: 100]
    ])
    XCTAssertTrue(
      invocation.updateConversionValue(withConfigs: configs, event: Values.purchase, shouldBoostPriority: true),
      "Should expect to update the conversion value"
    )
    XCTAssertEqual(
      invocation.priority,
      highestPriorityRule.priority + boostPriority,
      "Should expect the updated priority to be boosted"
    )
    XCTAssertEqual(
      invocation.conversionValue,
      highestPriorityRule.conversionValue,
      "Should expect the conversion value is updated for the optimized event"
    )
  }

  func testUpdateConversionWithBoostPriorityAndNonOptimziedEvent() {
    let config = SampleAEMConfigurations.createWithMultipleRules()
    let configs = [Values.defaultMode: [config]]
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()

    let lowestPriorityRule = config.conversionValueRules.last! // swiftlint:disable:this force_unwrapping
    // Set the highest priority in the conversion rules
    invocation.setPriority(config.conversionValueRules.first!.priority) // swiftlint:disable:this force_unwrapping
    // Add the lowest priority event
    invocation.setRecordedEvents(
      [
        Values.purchase,
        lowestPriorityRule.events.first!.eventName // swiftlint:disable:this force_unwrapping
      ]
    )
    XCTAssertFalse(
      invocation.updateConversionValue(withConfigs: configs, event: Values.purchase, shouldBoostPriority: true),
      "Should expect not to update the conversion value"
    )
  }

  func testDecodeBase64UrlSafeString() {
    let decodedString = validInvocation
      .decodeBase64UrlSafeString(
        "E_dwjTaF9-SHijRKoD5jrgJoi9pgObKEqrkxgl3iE9-mxpDn-wpseBmtlNFN2HTI5OzzTVqhBwNi2zrwt-TxCw"
      )
    XCTAssertEqual(
      decodedString?.base64EncodedString(),
      "E/dwjTaF9+SHijRKoD5jrgJoi9pgObKEqrkxgl3iE9+mxpDn+wpseBmtlNFN2HTI5OzzTVqhBwNi2zrwt+TxCw==",
      "Should decode the base64 url safe string correctly"
    )
  }

  func testDecodeBase64UrlSafeStringWithEmptyString() {
    let decodedString = validInvocation.decodeBase64UrlSafeString("")
    XCTAssertNil(
      decodedString?.base64EncodedString(),
      "Should decode the base64 url safe string as nil with empty string"
    )
  }

  func testGetHmacWithoutACSSecret() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.acsSharedSecret = nil

    XCTAssertNil(
      invocation.getHMAC(10),
      "HMAC should be nil when ACS Shared Secret is nil"
    )
  }

  func testGetHmacWithEmptyACSSecret() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.acsSharedSecret = ""

    XCTAssertNil(
      invocation.getHMAC(10),
      "HMAC should be nil when ACS Shared Secret is an empty string"
    )
  }

  func testGetHmacWithoutACSConfigID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.acsConfigID = nil

    XCTAssertNil(
      invocation.getHMAC(10),
      "HMAC should be nil when ACS config ID is nil"
    )
  }

  func testGetHmacWithACSSecretAndACSConfigID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.campaignID = "aaa"
    invocation.acsConfigID = "abc"
    invocation.acsSharedSecret =
      "E_dwjTaF9-SHijRKoD5jrgJoi9pgObKEqrkxgl3iE9-mxpDn-wpseBmtlNFN2HTI5OzzTVqhBwNi2zrwt-TxCw"
    invocation.conversionValue = 6

    XCTAssertEqual(
      invocation.getHMAC(31),
      "Z65Xxo-IevEwpLYNES9QmWRlx-zPH8zxfIJPw6ofQtpDJvKWuNI93SBHlUapS1_DIVl9Ovwoa5Xo7v63zQ5_HA",
      "Should generate the expected HMAC"
    )
  }

  func testIsOptimizedEventWithoutCatalogID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    let configs = [
      Values.defaultMode: [config1]
    ]

    XCTAssertFalse(
      invocation.isOptimizedEvent(Values.purchase, configs: configs),
      "Invocation without catalog ID doesn't have optimized event"
    )
  }

  func testIsOptimizedEventWithoutExpectedEvent() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    let configs = [
      Values.defaultMode: [config1]
    ]

    XCTAssertFalse(
      invocation.isOptimizedEvent(Values.donate, configs: configs),
      "Event is not expected to be optimized"
    )
  }

  func testIsOptimizedEventWithExpectedEvent() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    let configs = [
      Values.defaultMode: [config1]
    ]

    XCTAssertTrue(
      invocation.isOptimizedEvent(Values.purchase, configs: configs),
      "Event is expected to be optimized"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      AEMInvocation.supportsSecureCoding,
      "AEM Invocation should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    let invocation: AEMInvocation = validInvocation
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
      coder.encodedObject[Keys.catalogID] as? String,
      invocation.catalogID,
      "Should encode the expected catalogID with the correct key"
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
    let hasSKAN = coder.encodedObject[Keys.hasSKAN] as? NSNumber
    XCTAssertEqual(
      hasSKAN?.boolValue,
      invocation.hasSKAN,
      "Should encode the expected hasSKAN with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AEMInvocation(coder: decoder)

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
      decoder.decodedObject[Keys.businessID] is NSString.Type,
      "Should decode the expected type for the advertiser_id key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.catalogID] is NSString.Type,
      "Should decode the expected type for the catalog_id key"
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
    XCTAssertEqual(
      decoder.decodedObject[Keys.hasSKAN] as? String,
      "decodeBoolForKey",
      "Should decode the expected type for the has_skan key"
    )
  }
}
