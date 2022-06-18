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

final class AEMInvocationTests: XCTestCase {

  enum Keys {
    static let campaignID = "campaign_ids"
    static let acsToken = "acs_token"
    static let acsSharedSecret = "shared_secret"
    static let acsConfigurationID = "acs_config_id"
    static let advertiserID = "advertiser_id"
    static let businessID = "advertiser_id"
    static let catalogID = "catalog_id"
    static let timestamp = "timestamp"
    static let configurationMode = "config_mode"
    static let configurationID = "config_id"
    static let recordedEvents = "recorded_events"
    static let recordedValues = "recorded_values"
    static let conversionValues = "conversion_values"
    static let priority = "priority"
    static let conversionTimestamp = "conversion_timestamp"
    static let isAggregated = "is_aggregated"
    static let hasStoreKitAdNetwork = "has_skan"
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

  var validInvocation = _AEMInvocation(
    campaignID: "test_campaign_1234",
    acsToken: "test_token_12345",
    acsSharedSecret: "test_shared_secret",
    acsConfigurationID: "test_config_123",
    businessID: "test_advertiserid_coffee",
    catalogID: "test_catalog_123",
    timestamp: Date(timeIntervalSince1970: 1618383600),
    configurationMode: "DEFAULT",
    configurationID: 10,
    recordedEvents: nil,
    recordedValues: nil,
    conversionValue: -1,
    priority: -1,
    conversionTimestamp: Date(timeIntervalSince1970: 1618383700),
    isAggregated: false,
    isTestMode: false,
    hasStoreKitAdNetwork: false,
    isConversionFilteringEligible: true
  )! // swiftlint:disable:this force_unwrapping

  var configuration1 = _AEMConfiguration(json: [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 10000,
    Keys.configurationMode: Values.defaultMode,
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
                Keys.amount: 100.0,
              ],
            ],
          ],
          [
            Keys.eventName: Values.unlock,
          ],
        ],
      ],
    ],
  ])! // swiftlint:disable:this force_unwrapping

  var configuration2 = _AEMConfiguration(json: [
    Keys.defaultCurrency: Values.USD,
    Keys.cutoffTime: 1,
    Keys.validFrom: 20000,
    Keys.configurationMode: Values.defaultMode,
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
  ])! // swiftlint:disable:this force_unwrapping

  func testInvocationWithInvalidAppLinkData() {
    var invalidData: [String: Any] = [:]

    XCTAssertNil(_AEMInvocation(appLinkData: nil))

    invalidData = [
      "acs_token": "test_token_12345",
    ]
    XCTAssertNil(_AEMInvocation(appLinkData: invalidData))

    invalidData = [
      "campaign_ids": "test_campaign_1234",
    ]
    XCTAssertNil(_AEMInvocation(appLinkData: invalidData))

    invalidData = [
      "advertiser_id": "test_advertiserid_coffee",
    ]
    XCTAssertNil(_AEMInvocation(appLinkData: invalidData))

    invalidData = [
      "acs_token": 123,
      "campaign_ids": 123,
    ]
    XCTAssertNil(_AEMInvocation(appLinkData: invalidData))
  }

  func testInvocationWithValidAppLinkData() {
    var validData: [String: Any] = [:]
    var invocation: _AEMInvocation?

    validData = [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
    ]
    invocation = _AEMInvocation(appLinkData: validData)
    XCTAssertEqual(invocation?.acsToken, "test_token_12345")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertNil(invocation?.businessID)

    validData = [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
    ]
    invocation = _AEMInvocation(appLinkData: validData)
    XCTAssertEqual(invocation?.acsToken, "test_token_12345")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertEqual(invocation?.businessID, "test_advertiserid_coffee")
  }

  func testInvocationWithCatalogID() {
    let invocation = _AEMInvocation(appLinkData: [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
      "catalog_id": "test_catalog_1234",
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
    let invocation = _AEMInvocation(appLinkData: [
      "acs_token": "test_token_12345",
      "campaign_ids": "test_campaign_1234",
      "advertiser_id": "test_advertiserid_coffee",
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
      "test_deeplink": 1,
    ] as [String: Any]
    let invocation = try XCTUnwrap(_AEMInvocation(appLinkData: data))

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
      "has_skan": true,
    ] as [String: Any]
    let invocation = try XCTUnwrap(_AEMInvocation(appLinkData: data))

    XCTAssertTrue(
      invocation.hasStoreKitAdNetwork,
      "Invocation's hasStoreKitAdNetwork is expected to be true when has_skan is true"
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
    let invocation: _AEMInvocation? = validInvocation
    let content: [String: AnyHashable] = ["id": "123", "quantity": 5]
    let contentIDs: [String] = ["id123", "id456"]

    let parameters = invocation?.getProcessedParameters(
      from: [
        Keys.content: #"[{"id": "123", "quantity": 5}]"#,
        Keys.contentID: #"["id123", "id456"]"#,
        Keys.contentType: "product",
      ]
    ) as? [String: AnyHashable]
    XCTAssertEqual(
      parameters,
      [
        Keys.content: [content],
        Keys.contentID: contentIDs,
        Keys.contentType: "product",
      ],
      "Processed parameters are not expected"
    )
  }

  func testProcessedParametersWithValidContent() {
    let invocation: _AEMInvocation? = validInvocation
    let content: [String: AnyHashable] = ["id": "123", "quantity": 5]

    let parameters = invocation?.getProcessedParameters(
      from: [
        Keys.content: #"[{"id": "123", "quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product",
      ]
    ) as? [String: AnyHashable]
    XCTAssertEqual(
      parameters,
      [
        Keys.content: [content],
        Keys.contentID: "001",
        Keys.contentType: "product",
      ],
      "Processed parameters are not expected"
    )
  }

  func testProcessedParametersWithInvalidContent() {
    let invocation: _AEMInvocation? = validInvocation

    let parameters = invocation?.getProcessedParameters(
      from: [
        Keys.content: #"[{"id": ,"quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product",
      ]
    ) as? [String: AnyHashable]
    XCTAssertEqual(
      parameters,
      [
        Keys.content: #"[{"id": ,"quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product",
      ],
      "Processed parameters are not expected"
    )
  }

  func testFindConfiguration() {
    var invocation: _AEMInvocation? = validInvocation
    invocation?.reset()
    invocation?.configurationID = 10
    XCTAssertNil(
      invocation?.findConfiguration(in: [Values.defaultMode: [configuration1, configuration2]]),
      "Should not find the configuration with unmatched configurationID"
    )

    invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )
    let configuration = invocation?.findConfiguration(in: [Values.defaultMode: [configuration1, configuration2]])
    XCTAssertEqual(invocation?.configurationID, 20000, "Should set the invocation with expected configurationID")
    XCTAssertEqual(
      invocation?.configurationMode,
      Values.defaultMode,
      "Should set the invocation with expected configurationMode"
    )
    XCTAssertEqual(configuration?.validFrom, configuration2.validFrom, "Should find the expected configuration")
    XCTAssertEqual(
      configuration?.mode,
      configuration2.mode,
      "Should find the expected configuration"
    )
  }

  func testFindConfigWithBusinessID1() {
    let configurationWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessID()
    let configurationWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()
    let invocation = validInvocation
    invocation.reset()
    invocation.configurationID = 10000

    let configuration = invocation.findConfiguration(
      in: [
        Values.defaultMode: [configurationWithoutBusinessID],
        Values.brandMode: [configurationWithBusinessID],
      ]
    )
    XCTAssertEqual(
      configuration?.validFrom,
      10000,
      "Should have expected validFrom"
    )
    XCTAssertNil(
      configuration?.businessID,
      "Should not have unexpected advertiserID"
    )
  }

  func testFindConfigWithBusinessID2() {
    let configurationWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessID()
    let configurationWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()
    let invocation = validInvocation
    invocation.reset()
    invocation.configurationID = 10000
    invocation.businessID = "test_advertiserid_123"

    let configuration = invocation.findConfiguration(
      in: [
        Values.defaultMode: [configurationWithoutBusinessID],
        Values.brandMode: [configurationWithBusinessID],
      ]
    )
    XCTAssertEqual(
      configuration?.validFrom,
      10000,
      "Should have expected validFrom"
    )
    XCTAssertEqual(
      configuration?.businessID,
      "test_advertiserid_123",
      "Should have expected advertiserID"
    )
  }

  func testFindConfigWithBusinessID3() {
    let configurationWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessID()
    let configurationWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()
    let invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: "test_advertiserid_123",
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )
    let configuration = invocation?.findConfiguration(
      in: [
        Values.defaultMode: [configurationWithoutBusinessID],
        Values.brandMode: [configurationWithBusinessID],
      ]
    )
    XCTAssertEqual(invocation?.configurationID, 10000, "Should set the invocation with expected configurationID")
    XCTAssertEqual(
      invocation?.configurationMode,
      Values.defaultMode,
      "Should set the invocation with expected configurationMode"
    )
    XCTAssertEqual(
      configuration?.validFrom,
      configurationWithBusinessID.validFrom,
      "Should find the expected configuration"
    )
    XCTAssertEqual(
      configuration?.mode,
      configurationWithBusinessID.mode,
      "Should find the expected configuration"
    )
    XCTAssertEqual(
      configuration?.businessID,
      configurationWithBusinessID.businessID,
      "Should find the expected configuration"
    )
  }

  func testFindConfigWithCpas() {
    let cpasConfiguration = SampleAEMConfigurations.createCpasConfiguration()
    let invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: "test_advertiserid_cpas",
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )
    let configuration = invocation?.findConfiguration(
      in: [
        Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
        Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessIDAndContentRule()],
        Values.cpasMode: [cpasConfiguration],
      ]
    )
    XCTAssertEqual(invocation?.configurationID, 10000, "Should set the invocation with expected configurationID")
    XCTAssertEqual(
      invocation?.configurationMode,
      Values.cpasMode,
      "Should set the invocation with expected configurationMode"
    )
    XCTAssertEqual(
      configuration?.validFrom,
      cpasConfiguration.validFrom,
      "Should find the expected configuration"
    )
    XCTAssertEqual(
      configuration?.mode,
      cpasConfiguration.mode,
      "Should find the expected configuration"
    )
    XCTAssertEqual(
      configuration?.businessID,
      cpasConfiguration.businessID,
      "Should find the expected configuration"
    )
  }

  func testGetConfigurationList() {
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessIDAndContentRule()],
      Values.cpasMode: [SampleAEMConfigurations.createCpasConfiguration()],
    ]
    let invocation = SampleAEMInvocations.createGeneralInvocation1()

    var configurationList = invocation.getConfigurationList(mode: .default, configurations: configurations)
    XCTAssertEqual(configurationList.count, 1, "Should only find the default configuration")

    configurationList = invocation.getConfigurationList(mode: .brand, configurations: configurations)
    XCTAssertEqual(configurationList.count, 2, "Should only find the brand or cpas configuration")
    XCTAssertEqual(
      configurationList.first?.mode,
      Values.cpasMode,
      "Should have the caps configuration first"
    )
    XCTAssertEqual(
      configurationList.last?.mode,
      Values.brandMode,
      "Should have the brand configuration last"
    )
  }

  func testAttributeEventWithValue() {
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration1)

    var isAttributed = invocation.attributeEvent(
      Values.test,
      currency: Values.USD,
      value: 10,
      parameters: nil,
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: true,
      isRuleMatchInServer: false
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
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: true,
      isRuleMatchInServer: false
    )
    XCTAssertTrue(isAttributed, "Should attribute expected event")
    XCTAssertTrue(
      invocation.recordedEvents.contains(Values.purchase),
      "Should add events that can be attributed to the invocation"
    )
    XCTAssertEqual(
      invocation.recordedValues as? [String: [String: Int]],
      [Values.purchase: [Values.USD: 10]],
      "Should attribute unexpected values"
    )
  }

  func testAttributeUnexpectedEventWithoutValue() {
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration1)

    let isAttributed = invocation.attributeEvent(
      Values.test,
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: true,
      isRuleMatchInServer: false
    )
    XCTAssertFalse(isAttributed, "Should not attribute unexpected event")
    XCTAssertFalse(invocation.recordedEvents.contains(Values.test))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")
  }

  func testAttributeExpectedEventWithoutValue() {
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration1)

    var isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: true,
      isRuleMatchInServer: false
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertTrue(invocation.recordedEvents.contains(Values.purchase))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")

    isAttributed = invocation.attributeEvent(
      Values.donate,
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: true,
      isRuleMatchInServer: false
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertTrue(invocation.recordedEvents.contains(Values.donate))
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not attribute unexpected values")
  }

  func testAttributeEventWithExpectedContent() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessIDAndContentRule()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()
    let invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: "test_advertiserid_content_test",
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configurations = [
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID],
    ]
    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 0,
      parameters: [
        Keys.content: #"[{"id": "abc", "quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product",
      ],
      configurations: configurations,
      shouldUpdateCache: true,
      isRuleMatchInServer: false
    )
    XCTAssertTrue(isAttributed, "Should attribute the event with expected parameters")
  }

  func testAttributeEventWithUnexpectedContent() {
    let configWithBusinessID = SampleAEMConfigurations.createConfigurationWithBusinessIDAndContentRule()
    let configWithoutBusinessID = SampleAEMConfigurations.createConfigurationWithoutBusinessID()
    let invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: "test_advertiserid_content_test",
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configurations = [
      Values.defaultMode: [configWithoutBusinessID],
      Values.brandMode: [configWithBusinessID],
    ]
    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 0,
      parameters: [
        Keys.content: #"[{"id": "123", "quantity": 5}]"#,
        Keys.contentID: "001",
        Keys.contentType: "product",
      ],
      configurations: configurations,
      shouldUpdateCache: true,
      isRuleMatchInServer: false
    )
    XCTAssertFalse(isAttributed, "Should attribute the event with expected parameters")
  }

  func testAttributeCpasEvent() {
    let invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: "test_advertiserid_cpas",
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.cpasMode: [SampleAEMConfigurations.createCpasConfiguration()],
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
            Keys.quantity: NSNumber(value: 10),
          ],
          [
            Keys.identity: "test",
            Keys.itemPrice: NSNumber(value: 200),
            Keys.quantity: NSNumber(value: 20),
          ],
        ],
      ],
      configurations: configurations,
      shouldUpdateCache: true,
      isRuleMatchInServer: false
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
      invocation.recordedValues as? [String: [String: Int]],
      [Values.purchase: [Values.USD: 1000]],
      "Should expect the total value is updated in the cache"
    )
  }

  func testAttributeEventWithRuleMatchInServer() {
    let invocation = _AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_12345",
      acsSharedSecret: nil,
      acsConfigurationID: nil,
      businessID: "test_advertiserid_cpas",
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )! // swiftlint:disable:this force_unwrapping
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.cpasMode: [SampleAEMConfigurations.createCpasConfiguration()],
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
            Keys.quantity: NSNumber(value: 10),
          ],
          [
            Keys.identity: "test",
            Keys.itemPrice: NSNumber(value: 200),
            Keys.quantity: NSNumber(value: 20),
          ],
        ],
      ],
      configurations: configurations,
      shouldUpdateCache: true,
      isRuleMatchInServer: true
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
      invocation.recordedValues as? [String: [String: Int]],
      [Values.purchase: [Values.USD: 5000]],
      "Should expect the value is updated in the cache"
    )
  }

  func testAttributeEventWithoutCache() {
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration1)

    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: false,
      isRuleMatchInServer: false
    )
    XCTAssertTrue(isAttributed, "Should attribute the expected event")
    XCTAssertFalse(invocation.recordedEvents.contains(Values.purchase), "Should not update the event cache")
    XCTAssertEqual(invocation.recordedValues.count, 0, "Should not update value cache")
  }

  func testAttributeEventAndValueWithoutCache() {
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration1)

    let isAttributed = invocation.attributeEvent(
      Values.purchase,
      currency: Values.USD,
      value: 10,
      parameters: nil,
      configurations: [Values.defaultMode: [configuration1, configuration2]],
      shouldUpdateCache: false,
      isRuleMatchInServer: false
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
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration1)

    invocation.recordedEvents = [Values.purchase, Values.unlock]
    XCTAssertFalse(
      invocation.updateConversionValue(
        configurations: [Values.defaultMode: [configuration1, configuration2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
      "Should not update conversion value"
    )

    invocation.recordedEvents = [Values.purchase, Values.donate]
    XCTAssertTrue(
      invocation.updateConversionValue(
        configurations: [Values.defaultMode: [configuration1, configuration2]],
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

    invocation.recordedEvents = [Values.purchase, Values.unlock]
    invocation.recordedValues = [Values.purchase: [Values.USD: 100.0]]
    XCTAssertTrue(
      invocation.updateConversionValue(
        configurations: [Values.defaultMode: [configuration1, configuration2]],
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
    invocation.priority = 100
    invocation.recordedEvents = [Values.purchase, Values.unlock]
    invocation.recordedValues = [Values.purchase: [Values.USD: 100]]
    XCTAssertFalse(
      invocation.updateConversionValue(
        configurations: [Values.defaultMode: [configuration1, configuration2]],
        event: Values.purchase,
        shouldBoostPriority: false
      ),
      "Should not update conversion value under priority"
    )
  }

  func testUpdateConversionWithouValue() {
    let invocation: _AEMInvocation = validInvocation
    invocation.reset()
    invocation.setConfiguration(configuration2)

    invocation.recordedEvents = [Values.purchase]
    XCTAssertFalse(
      invocation.updateConversionValue(
        configurations: [Values.defaultMode: [configuration1, configuration2]],
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

    invocation.recordedEvents = [Values.purchase, Values.donate]
    XCTAssertTrue(
      invocation.updateConversionValue(
        configurations: [Values.defaultMode: [configuration1, configuration2]],
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
    let configuration = SampleAEMConfigurations.createWithMultipleRules()
    let configurations = [Values.defaultMode: [configuration]]
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()

    // swiftlint:disable force_unwrapping
    let lowestPriorityRule = configuration.conversionValueRules.last!
    // Set the highest priority in the conversion rules
    invocation.priority = configuration.conversionValueRules.first!.priority
    // Add the lowest priority event
    invocation.recordedEvents = [lowestPriorityRule.events.first!.eventName]
    // swiftlint:enable force_unwrapping

    XCTAssertTrue(
      invocation.updateConversionValue(configurations: configurations, event: Values.donate, shouldBoostPriority: true),
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
    let configuration = SampleAEMConfigurations.createWithMultipleRules()
    let configurations = [Values.defaultMode: [configuration]]
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    invocation.campaignID = "83" // The campaign id's modulo is matched to purchase's conversion value

    let highestPriorityRule = configuration.conversionValueRules.first! // swiftlint:disable:this force_unwrapping
    invocation.priority = 42 // Set the second highest priority with boost priority in the conversion rules
    invocation.recordedEvents = [Values.purchase] // Add the optimzied event
    invocation.recordedValues = [Values.purchase: [Values.USD: 100.0]]
    XCTAssertTrue(
      invocation.updateConversionValue(
        configurations: configurations,
        event: Values.purchase,
        shouldBoostPriority: true
      ),
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
    let configuration = SampleAEMConfigurations.createWithMultipleRules()
    let configurations = [Values.defaultMode: [configuration]]
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()

    let lowestPriorityRule = configuration.conversionValueRules.last! // swiftlint:disable:this force_unwrapping
    // Set the highest priority in the conversion rules
    invocation.priority = configuration.conversionValueRules.first!.priority // swiftlint:disable:this force_unwrapping
    // Add the lowest priority event
    invocation.recordedEvents = [
      Values.purchase,
      lowestPriorityRule.events.first!.eventName, // swiftlint:disable:this force_unwrapping
    ]
    XCTAssertFalse(
      invocation.updateConversionValue(
        configurations: configurations,
        event: Values.purchase,
        shouldBoostPriority: true
      ),
      "Should expect not to update the conversion value"
    )
  }

  func testDecodeBase64UrlSafeString() {
    let decodedString = validInvocation
      .decodeBase64URLSafeString(
        "E_dwjTaF9-SHijRKoD5jrgJoi9pgObKEqrkxgl3iE9-mxpDn-wpseBmtlNFN2HTI5OzzTVqhBwNi2zrwt-TxCw"
      )
    XCTAssertEqual(
      decodedString?.base64EncodedString(),
      "E/dwjTaF9+SHijRKoD5jrgJoi9pgObKEqrkxgl3iE9+mxpDn+wpseBmtlNFN2HTI5OzzTVqhBwNi2zrwt+TxCw==",
      "Should decode the base64 url safe string correctly"
    )
  }

  func testDecodeBase64UrlSafeStringWithEmptyString() {
    let decodedString = validInvocation.decodeBase64URLSafeString("")
    XCTAssertNil(
      decodedString?.base64EncodedString(),
      "Should decode the base64 url safe string as nil with empty string"
    )
  }

  func testGetHmacWithoutACSSecret() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.acsSharedSecret = nil

    XCTAssertNil(
      invocation.getHMAC(delay: 10),
      "HMAC should be nil when ACS Shared Secret is nil"
    )
  }

  func testGetHmacWithEmptyACSSecret() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.acsSharedSecret = ""

    XCTAssertNil(
      invocation.getHMAC(delay: 10),
      "HMAC should be nil when ACS Shared Secret is an empty string"
    )
  }

  func testGetHmacWithoutACSConfigurationID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.acsConfigurationID = nil

    XCTAssertNil(
      invocation.getHMAC(delay: 10),
      "HMAC should be nil when ACS configuration ID is nil"
    )
  }

  func testGetHmacWithACSSecretAndACSConfigurationID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    invocation.campaignID = "aaa"
    invocation.acsConfigurationID = "abc"
    invocation.acsSharedSecret =
      "E_dwjTaF9-SHijRKoD5jrgJoi9pgObKEqrkxgl3iE9-mxpDn-wpseBmtlNFN2HTI5OzzTVqhBwNi2zrwt-TxCw"
    invocation.conversionValue = 6

    XCTAssertEqual(
      invocation.getHMAC(delay: 31),
      "Z65Xxo-IevEwpLYNES9QmWRlx-zPH8zxfIJPw6ofQtpDJvKWuNI93SBHlUapS1_DIVl9Ovwoa5Xo7v63zQ5_HA",
      "Should generate the expected HMAC"
    )
  }

  func testIsOptimizedEventWithoutCatalogID() {
    let invocation = SampleAEMInvocations.createGeneralInvocation1()
    let configurations = [
      Values.defaultMode: [configuration1],
    ]

    XCTAssertFalse(
      invocation.isOptimizedEvent(Values.purchase, configurations: configurations),
      "Invocation without catalog ID doesn't have optimized event"
    )
  }

  func testIsOptimizedEventWithoutExpectedEvent() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    let configurations = [
      Values.defaultMode: [configuration1],
    ]

    XCTAssertFalse(
      invocation.isOptimizedEvent(Values.donate, configurations: configurations),
      "Event is not expected to be optimized"
    )
  }

  func testIsOptimizedEventWithExpectedEvent() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    let configurations = [
      Values.defaultMode: [configuration1],
    ]

    XCTAssertTrue(
      invocation.isOptimizedEvent(Values.purchase, configurations: configurations),
      "Event is expected to be optimized"
    )
  }

  func testSecureCoding() {
    XCTAssertTrue(
      _AEMInvocation.supportsSecureCoding,
      "AEM Invocation should support secure coding"
    )
  }

  func testEncodingAndDecoding() throws {
    // Encode and Decode
    let object = validInvocation
    let decodedObject = try CodabilityTesting.encodeAndDecode(object)

    // Test Objects
    // XCTAssertEqual(decodedObject, invocation, .isCodable) // Doesn't work since isEqual not implemented
    XCTAssertNotIdentical(decodedObject, object, .isCodable)

    // Test Properties
    XCTAssertEqual(decodedObject.campaignID, object.campaignID, .isCodable)
    XCTAssertEqual(decodedObject.acsToken, object.acsToken, .isCodable)
    XCTAssertEqual(decodedObject.acsSharedSecret, object.acsSharedSecret, .isCodable)
    XCTAssertEqual(decodedObject.acsConfigurationID, object.acsConfigurationID, .isCodable)
    XCTAssertEqual(decodedObject.businessID, object.businessID, .isCodable)
    XCTAssertEqual(decodedObject.catalogID, object.catalogID, .isCodable)
    XCTAssertEqual(decodedObject.timestamp, object.timestamp, .isCodable)
    XCTAssertEqual(decodedObject.configurationMode, object.configurationMode, .isCodable)
    XCTAssertEqual(decodedObject.configurationID, object.configurationID, .isCodable)
    XCTAssertEqual(decodedObject.recordedEvents, object.recordedEvents, .isCodable)
    XCTAssertTrue(decodedObject.recordedValues.isEmpty, .isCodable)
    XCTAssertEqual(decodedObject.conversionValue, object.conversionValue, .isCodable)
    XCTAssertEqual(decodedObject.priority, object.priority, .isCodable)
    XCTAssertEqual(decodedObject.conversionTimestamp, object.conversionTimestamp, .isCodable)
    XCTAssertEqual(decodedObject.isAggregated, object.isAggregated, .isCodable)
    XCTAssertEqual(decodedObject.hasStoreKitAdNetwork, object.hasStoreKitAdNetwork, .isCodable)
    XCTAssertEqual(decodedObject.isConversionFilteringEligible, object.isConversionFilteringEligible, .isCodable)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isCodable = "AEMInvocation should be encodable and decodable"
}
