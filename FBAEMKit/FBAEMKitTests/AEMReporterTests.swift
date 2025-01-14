/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit

import FBSDKCoreKit_Basics
import TestTools
import XCTest

final class AEMReporterTests: XCTestCase {

  enum Keys {
    static let defaultCurrency = "default_currency"
    static let cutoffTime = "cutoff_time"
    static let validFrom = "valid_from"
    static let configurationMode = "config_mode"
    static let conversionValueRules = "conversion_value_rules"
    static let conversionValue = "conversion_value"
    static let priority = "priority"
    static let events = "events"
    static let eventName = "event_name"
    static let advertiserID = "advertiser_id"
    static let businessID = "advertiser_id"
    static let campaignID = "campaign_id"
    static let catalogID = "catalog_id"
    static let contentID = "fb_content_ids"
    static let content = "fb_content"
    static let token = "token"
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let defaultMode = "DEFAULT"
    static let brandMode = "BRAND"
    static let cpasMode = "CPAS"
    static let USD = "USD"
  }

  let networker = TestAEMNetworker()
  let reporter = TestSKAdNetworkReporter()
  let userDefaultsSpy = UserDefaultsSpy()
  let date = Calendar.current.date(
    byAdding: .day,
    value: -2,
    to: Date()
  )! // swiftlint:disable:this force_unwrapping
  lazy var testInvocation = TestInvocation(
    campaignID: name,
    acsToken: name,
    acsSharedSecret: nil,
    acsConfigurationID: nil,
    businessID: nil,
    catalogID: nil,
    isTestMode: false,
    hasStoreKitAdNetwork: false,
    isConversionFilteringEligible: true
  )! // swiftlint:disable:this force_unwrapping
  lazy var reportFilePath = BasicUtility.persistenceFilePath(name)
  let urlWithInvocation = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22test_token_1234567%22%2C+%22campaign_ids%22%3A+%22test_campaign_1234%22%2C+%22advertiser_id%22%3A+%22test_advertiserid_12345%22%7D")! // swiftlint:disable:this force_unwrapping
  let sampleCatalogOptimizationDictionary = ["data": [["content_id_belongs_to_catalog_id": true]]]
  let aggregationRequestTimestampToNotDelay = Date().addingTimeInterval(-100)
  let analyticsAppID = "analytics_123"

  override func setUp() {
    super.setUp()

    AEMReporter.reset()
    removeReportFile()
    AEMReporter.configure(
      networker: networker,
      appID: "123",
      reporter: reporter,
      analyticsAppID: analyticsAppID,
      store: userDefaultsSpy
    )
    // Actual queue doesn't matter as long as it's not the same as the designated queue name in the class
    AEMReporter.serialQueue = DispatchQueue(label: name, qos: .background)
    AEMReporter.isAEMReportEnabled = true
    AEMReporter.reportFile = reportFilePath
  }

  func testEnable() {
    AEMReporter.enable()

    XCTAssertFalse(AEMReporter.isAEMReportEnabled, "AEM Report should not be enabled")
  }

  func testConversionFilteringDefaultConfigure() {
    XCTAssertFalse(AEMReporter.isConversionFilteringEnabled, "AEM Conversion Filtering should be disabled by default")
  }

  func testSetConversionFilteringEnabled() {
    AEMReporter.isConversionFilteringEnabled = false
    AEMReporter.setConversionFilteringEnabled(true)

    XCTAssertTrue(AEMReporter.isConversionFilteringEnabled, "AEM Conversion Filtering should be enabled")
  }

  func testCatalogMatchingDefaultConfigure() {
    XCTAssertFalse(AEMReporter.isCatalogMatchingEnabled, "AEM Catalog Matching should be disabled by default")
  }

  func testSetCatalogMatchingEnabled() {
    AEMReporter.isCatalogMatchingEnabled = false
    AEMReporter.setCatalogMatchingEnabled(true)

    XCTAssertTrue(AEMReporter.isCatalogMatchingEnabled, "AEM Catalog Matching should be enabled")
  }

  func testAdvertiserRuleMatchInServerEnabledDefaultConfigure() {
    XCTAssertFalse(
      AEMReporter.isAdvertiserRuleMatchInServerEnabled,
      "AEM Advertiser Rule Match in server should be disabled by default"
    )
  }

  func testSetAdvertiserRuleMatchInServerEnabled() {
    AEMReporter.isAdvertiserRuleMatchInServerEnabled = false
    AEMReporter.setAdvertiserRuleMatchInServerEnabled(true)

    XCTAssertTrue(
      AEMReporter.isAdvertiserRuleMatchInServerEnabled,
      "AEM Advertiser Rule Match in server should be enabled"
    )
  }

  func testConfigure() {
    XCTAssertEqual(
      networker,
      AEMReporter.networker as? TestAEMNetworker,
      "Should configure with the expected AEM networker"
    )
    XCTAssertEqual(
      reporter,
      AEMReporter.reporter as? TestSKAdNetworkReporter,
      "Should configure with the expected SKAdNetwork reporter"
    )
    XCTAssertEqual(
      userDefaultsSpy,
      AEMReporter.dataStore as? UserDefaultsSpy,
      "Should configure with the expected data store"
    )
    XCTAssertEqual(
      AEMReporter.analyticsAppID,
      analyticsAppID,
      "Should configure with the expected analytics app id"
    )
  }

  func testParseURL() {
    var url: URL?
    XCTAssertNil(AEMReporter.parseURL(url))

    url = URL(string: "fb123://test.com")
    XCTAssertNil(AEMReporter.parseURL(url))

    url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22test_token_1234567%22%2C+%22campaign_ids%22%3A+%22test_campaign_1234%22%7D")
    var invocation = AEMReporter.parseURL(url)
    XCTAssertEqual(invocation?.acsToken, "test_token_1234567")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertNil(invocation?.businessID)

    invocation = AEMReporter.parseURL(urlWithInvocation)
    XCTAssertEqual(invocation?.acsToken, "test_token_1234567")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertEqual(invocation?.businessID, "test_advertiserid_12345")
  }

  func testLoadReportData() {
    guard let invocation = AEMReporter.parseURL(urlWithInvocation) else {
      return XCTFail("Parsing Error")
    }

    AEMReporter.invocations = [invocation]
    AEMReporter.saveReportData()
    let data = AEMReporter.loadReportData()
    XCTAssertEqual(data.count, 1)
    XCTAssertEqual(data[0].acsToken, "test_token_1234567")
    XCTAssertEqual(data[0].campaignID, "test_campaign_1234")
    XCTAssertEqual(data[0].businessID, "test_advertiserid_12345")
  }

  func testClearCache() {
    AEMReporter.addConfigurations([SampleAEMData.validConfigurationData1])
    AEMReporter.addConfigurations([SampleAEMData.validConfigurationData1, SampleAEMData.validConfigurationData2])

    AEMReporter.clearCache()
    var configurations = AEMReporter.configurations
    var configList = configurations[Values.defaultMode]
    XCTAssertEqual(configList?.count, 1, "Should have the expected number of configuration")

    guard let invocation1 = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigurationID: "test_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    ), let invocation2 = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigurationID: "test_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )
    else { return XCTFail("Unwrapping Error") }
    invocation1.configurationID = 10000
    invocation2.configurationID = 10001
    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    invocation2.conversionTimestamp = date
    AEMReporter.invocations = [invocation1, invocation2]
    AEMReporter.addConfigurations(
      [SampleAEMData.validConfigurationData1, SampleAEMData.validConfigurationData2, SampleAEMData.validConfigData3]
    )
    AEMReporter.clearCache()
    let invocations = AEMReporter.invocations
    XCTAssertEqual(invocations.count, 1, "Should clear the expired invocation")
    XCTAssertEqual(invocations[0].configurationID, 10000, "Should keep the expected invocation")
    configurations = AEMReporter.configurations
    configList = configurations[Values.defaultMode]
    XCTAssertEqual(configList?.count, 2, "Should have the expected number of configuration")
    XCTAssertEqual(configList?[0].validFrom, 10000, "Should keep the expected ")
    XCTAssertEqual(configList?[1].validFrom, 20000, "Should keep the expected ")
  }

  func testClearConfigurations() {
    AEMReporter.configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessIDAndContentRule()],
      Values.cpasMode: [SampleAEMConfigurations.createCpasConfiguration()],
    ]

    AEMReporter.clearConfigurations()
    let defaultConfigurations = AEMReporter.configurations[Values.defaultMode]
    let brandConfigurations = AEMReporter.configurations[Values.brandMode]
    let cpasConfigurations = AEMReporter.configurations[Values.cpasMode]
    XCTAssertEqual(
      defaultConfigurations?.count,
      1,
      "Should have default mode "
    )
    XCTAssertEqual(
      brandConfigurations?.count,
      0,
      "Should not have brand mode "
    )
    XCTAssertEqual(
      cpasConfigurations?.count,
      0,
      "Should not have cpas mode "
    )
  }

  func testHandleURL() throws {
    let url = try XCTUnwrap(
      URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22test_token_1234567%22%2C+%22campaign_ids%22%3A+%22test_campaign_1234%22%7D"),
      "Should be able to create URL with valid deeplink"
    )
    AEMReporter.handle(url)
    let invocations = AEMReporter.invocations
    XCTAssertGreaterThan(
      invocations.count,
      0,
      "Handling a url that contains invocations should set the invocations on the reporter"
    )
  }

  func testHandleDebuggingURL() {
    guard let url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22debugging_token%22%2C+%22campaign_ids%22%3A+%2210%22%2C+%22test_deeplink%22%3A+1%7D")
    else { return XCTFail("Unwrapping Error") }
    AEMReporter.invocations = []
    AEMReporter.handle(url)
    XCTAssertEqual(
      AEMReporter.invocations.count,
      0,
      "Handling a debugging url should not affect production traffic"
    )
  }

  func testIsConfigRefreshTimestampValid() {
    AEMReporter.configRefreshTimestamp = Date()
    XCTAssertTrue(
      AEMReporter.isConfigRefreshTimestampValid(),
      "Timestamp should be valid"
    )

    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    AEMReporter.configRefreshTimestamp = date
    XCTAssertFalse(
      AEMReporter.isConfigRefreshTimestampValid(),
      "Timestamp should not be valid"
    )
  }

  func testShouldEnforceRefresh() {
    AEMReporter.invocations = [SampleAEMData.invocationWithoutAdvertiserID]
    AEMReporter.configRefreshTimestamp = Date()
    AEMReporter.configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
    ]

    XCTAssertTrue(
      AEMReporter.shouldRefresh(withIsForced: true),
      "Should refresh  if it's enforced"
    )
  }

  func testShouldRefreshWithoutBusinessID1() {
    AEMReporter.invocations = [SampleAEMData.invocationWithoutAdvertiserID]
    AEMReporter.configRefreshTimestamp = Date()
    AEMReporter.configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
    ]

    XCTAssertFalse(
      AEMReporter.shouldRefresh(withIsForced: false),
      "Should not refresh  if timestamp is not expired and there is no business ID"
    )
  }

  func testShouldRefreshWithoutBusinessID2() {
    AEMReporter.invocations = [SampleAEMData.invocationWithoutAdvertiserID]
    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    AEMReporter.configRefreshTimestamp = date
    AEMReporter.configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
    ]

    XCTAssertTrue(
      AEMReporter.shouldRefresh(withIsForced: false),
      "Should not refresh  if timestamp is expired"
    )
  }

  func testShouldRefreshWithoutBusinessID3() {
    AEMReporter.invocations = [SampleAEMData.invocationWithoutAdvertiserID]
    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    AEMReporter.configRefreshTimestamp = date
    AEMReporter.configurations = [:]

    XCTAssertTrue(
      AEMReporter.shouldRefresh(withIsForced: false),
      "Should not refresh  if configuration is empty"
    )
  }

  func testShouldRefreshWithBusinessID() {
    AEMReporter.invocations = [
      SampleAEMData.invocationWithoutAdvertiserID,
      SampleAEMData.invocationWithAdvertiserID1,
    ]
    AEMReporter.configRefreshTimestamp = Date()
    AEMReporter.configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
    ]

    XCTAssertTrue(
      AEMReporter.shouldRefresh(withIsForced: false),
      "Should not refresh  if there exists an invocation with business ID"
    )
  }

  func testSendDebuggingRequest() {
    AEMReporter.sendDebuggingRequest(SampleAEMInvocations.createDebuggingInvocation())

    XCTAssertTrue(
      networker.capturedGraphPath?.hasSuffix("aem_conversions") == true,
      "GraphRequst should be created because of there is a debugging invocation"
    )
    XCTAssertEqual(
      networker.startCallCount,
      1,
      "Should start the graph request to update the test mode"
    )
  }

  func testDebuggingRequestParameters() {
    XCTAssertEqual(
      AEMReporter.debuggingRequestParameters(SampleAEMInvocations.createDebuggingInvocation()) as NSDictionary,
      [
        "campaign_id": "debugging_campaign",
        "conversion_data": 0,
        "consumption_hour": 0,
        "token": "debugging_token",
        "delay_flow": "server",
      ],
      "Should have expected request parameters for debugging invocation"
    )
  }

  func testRuleMatchRequestParameters() {
    let businessIDs = ["123"]
    let content = #"[{"id": "123", "quantity": 5}]"#
    let parameters = AEMReporter.ruleMatchRequestParameters(businessIDs, content: content)
    let expected = [
      "advertiser_ids": #"["123"]"#,
      "fb_content_data": content,
    ]
    XCTAssertEqual(
      parameters as? [String: String],
      expected,
      "Rule match request parameter is not expected"
    )
  }

  func testSendAggregationRequest() {
    AEMReporter.invocations = []
    AEMReporter.sendAggregationRequest()
    XCTAssertNil(
      networker.capturedGraphPath,
      "GraphRequest should not be created because of there is no invocation"
    )
    XCTAssertNil(
      userDefaultsSpy.capturedSetObjectKey,
      "Min aggregation request timestamp should not be updated because of there is no request"
    )

    guard let invocation = AEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    AEMReporter.invocations = [invocation]
    AEMReporter.sendAggregationRequest()
    XCTAssertTrue(
      networker.capturedGraphPath?.hasSuffix("aem_conversions") == true,
      "GraphRequst should be created because of there is non-aggregated invocation"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp",
      "Min aggregation request timestamp should not be updated because of there is non-aggregated invocation"
    )
  }

  func testSendAggregationRequestWithDelay() {
    AEMReporter.minAggregationRequestTimestamp = Date().addingTimeInterval(100)
    guard let invocation = AEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    AEMReporter.invocations = [invocation]
    AEMReporter.sendAggregationRequest()
    XCTAssertNil(
      networker.capturedGraphPath,
      "GraphRequst should not be created immediately because of there is delay"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp",
      "Min aggregation request timestamp should not be updated because of there is non-aggregated invocation"
    )
  }

  func testCompletingAggregationRequestWithError() {

    guard let invocation = AEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    AEMReporter.invocations = [invocation]
    AEMReporter.sendAggregationRequest()

    networker.capturedCompletionHandler?(nil, SampleAEMError())
    XCTAssertFalse(
      invocation.isAggregated,
      "Completing with an error should not mark the invocation as aggregated"
    )
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: reportFilePath),
      "Completing with an error should not write the report to the expected file path"
    )
  }

  func testCompletingAggregationRequestWithoutError() {
    guard let invocation = AEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    AEMReporter.invocations = [invocation]
    AEMReporter.sendAggregationRequest()

    networker.capturedCompletionHandler?(nil, nil)
    XCTAssertTrue(
      invocation.isAggregated,
      "Completing with no error should mark the invocation as aggregated"
    )
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: reportFilePath),
      "Completing with no error should write the report to the expected file path"
    )
  }

  func testRecordAndUpdateEvents() {
    AEMReporter.configRefreshTimestamp = Date()
    guard let invocation = AEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigurationID: "test_config_id_123",
      businessID: nil,
      catalogID: nil,
      isTestMode: false,
      hasStoreKitAdNetwork: false,
      isConversionFilteringEligible: true
    )
    else { return XCTFail("Unwrapping Error") }
    guard let configuration = AEMConfiguration(json: SampleAEMData.validConfigData3)
    else { return XCTFail("Unwrapping Error") }

    AEMReporter.configurations = [Values.defaultMode: [configuration]]
    AEMReporter.invocations = [invocation]
    AEMReporter.recordAndUpdate(event: Values.purchase, currency: Values.USD, value: 100, parameters: nil)
    // Invocation should be attributed and updated while request should be sent
    XCTAssertEqual(
      invocation.recordedEvents,
      [Values.purchase],
      "Invocation's cached events should be updated"
    )
    XCTAssertEqual(
      invocation.recordedValues as? [String: [String: Int]],
      [Values.purchase: [Values.USD: 100]],
      "Invocation's cached values should be updated"
    )
    XCTAssertTrue(
      networker.capturedGraphPath?.hasSuffix("aem_conversions") == true,
      "Should create a request to update the conversions for a valid event"
    )
    XCTAssertFalse(
      invocation.isAggregated,
      "Should not mark the invocation as aggregated if it is recorded and sent"
    )
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: reportFilePath),
      "Should save uploaded events to disk"
    )
    XCTAssertEqual(
      networker.startCallCount,
      1,
      "Should start the graph request to update the conversions"
    )
  }

  func testRecordAndUpdateEventsWithAEMDisabled() {
    AEMReporter.isAEMReportEnabled = false
    AEMReporter.configRefreshTimestamp = date

    AEMReporter.recordAndUpdate(event: Values.purchase, currency: Values.USD, value: 100, parameters: nil)
    XCTAssertNil(
      networker.capturedGraphPath,
      "Should not create a request to fetch the  if AEM is disabled"
    )
  }

  func testRecordAndUpdateEventsWithEmptyEvent() {
    AEMReporter.configRefreshTimestamp = date

    AEMReporter.recordAndUpdate(event: "", currency: Values.USD, value: 100, parameters: nil)

    XCTAssertNil(
      networker.capturedGraphPath,
      "Should not create a request to fetch the  if the event being recorded is empty"
    )
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: reportFilePath),
      "Should not save an empty event to disk"
    )
  }

  func testRecordAndUpdateEventsWithEmptyConfigurations() throws {
    AEMReporter.configRefreshTimestamp = date
    AEMReporter.invocations = [testInvocation]

    AEMReporter.recordAndUpdate(event: Values.purchase, currency: Values.USD, value: 100, parameters: nil)
    XCTAssertEqual(
      testInvocation.attributionCallCount,
      0,
      "Should not attribute events with empty configurations"
    )
    XCTAssertEqual(
      testInvocation.updateConversionCallCount,
      0,
      "Should not update conversions with empty configurations"
    )
  }

  func testLoadConfigurationWithRefreshEnforced() {
    guard let configuration = AEMConfiguration(json: SampleAEMData.validConfigData3)
    else { return XCTFail("Unwrapping Error") }
    AEMReporter.configRefreshTimestamp = Date()
    AEMReporter.configurations = [Values.defaultMode: [configuration]]

    AEMReporter.isLoadingConfiguration = false
    AEMReporter.loadConfiguration(withRefreshForced: true, block: nil)
    guard
      let path = networker.capturedGraphPath,
      path.hasSuffix("aem_conversion_configs")
    else {
      return XCTFail("Should load configuration when refresh is enforced")
    }
  }

  func testLoadConfigurationWithBlock() {
    guard let configuration = AEMConfiguration(json: SampleAEMData.validConfigData3)
    else { return XCTFail("Unwrapping Error") }
    var blockCall = 0
    AEMReporter.configRefreshTimestamp = Date()
    AEMReporter.configurations = [Values.defaultMode: [configuration]]

    AEMReporter.loadConfiguration(withRefreshForced: false) { _ in
      blockCall += 1
    }
    XCTAssertEqual(
      blockCall,
      1,
      "Should call the completion when loading the configuration"
    )
  }

  func testLoadConfigurationWithoutBlock() {
    AEMReporter.configRefreshTimestamp = date

    AEMReporter.isLoadingConfiguration = false
    AEMReporter.loadConfiguration(withRefreshForced: false, block: nil)
    guard
      let path = networker.capturedGraphPath,
      path.hasSuffix("aem_conversion_configs")
    else {
      return XCTFail("Should not require a completion block to load a configuration")
    }
  }

  func testGetConfigRequestParameterWithoutAdvertiserIDs() {
    AEMReporter.invocations = [SampleAEMData.invocationWithoutAdvertiserID]

    XCTAssertEqual(
      AEMReporter.requestParameters() as NSDictionary,
      ["fields": "", "advertiser_ids": "[]"],
      "Should not have unexpected advertiserIDs in configuration request params"
    )
  }

  func testGetConfigRequestParameterWithAdvertiserIDs() {
    AEMReporter.invocations = [SampleAEMData.invocationWithAdvertiserID1, SampleAEMData.invocationWithoutAdvertiserID]

    XCTAssertEqual(
      AEMReporter.requestParameters() as NSDictionary,
      ["fields": "", "advertiser_ids": #"["\#(SampleAEMData.invocationWithAdvertiserID1.businessID!)"]"#], // swiftlint:disable:this force_unwrapping
      "Should have expected advertiserIDs in configuration request params"
    )

    AEMReporter.invocations = [
      SampleAEMData.invocationWithAdvertiserID1,
      SampleAEMData.invocationWithAdvertiserID2,
      SampleAEMData.invocationWithoutAdvertiserID,
    ]

    XCTAssertEqual(
      AEMReporter.requestParameters() as NSDictionary,
      ["fields": "", "advertiser_ids": #"["\#(SampleAEMData.invocationWithAdvertiserID1.businessID!)","\#(SampleAEMData.invocationWithAdvertiserID2.businessID!)"]"#], // swiftlint:disable:this force_unwrapping
      "Should have expected advertiserIDs in configuration request params"
    )
  }

  func testGetAggregationRequestParameterWithoutAdvertiserID() {
    let params: [String: Any] =
      AEMReporter.aggregationRequestParameters(SampleAEMData.invocationWithoutAdvertiserID)

    XCTAssertEqual(
      params[Keys.campaignID] as? String,
      SampleAEMData.invocationWithoutAdvertiserID.campaignID,
      "Should have expected campaign_id in aggregation request params"
    )
    XCTAssertEqual(
      params[Keys.token] as? String,
      SampleAEMData.invocationWithoutAdvertiserID.acsToken,
      "Should have expected ACS token in aggregation request params"
    )
    XCTAssertNil(
      params[Keys.businessID],
      "Should not have unexpected advertiser_id in aggregation request params"
    )
  }

  func testGetAggregationRequestParameterWithAdvertiserID() {
    let params: [String: Any] =
      AEMReporter.aggregationRequestParameters(SampleAEMData.invocationWithAdvertiserID1)

    XCTAssertEqual(
      params[Keys.campaignID] as? String,
      SampleAEMData.invocationWithAdvertiserID1.campaignID,
      "Should have expected campaign_id in aggregation request params"
    )
    XCTAssertEqual(
      params[Keys.token] as? String,
      SampleAEMData.invocationWithAdvertiserID1.acsToken,
      "Should have expected ACS token in aggregation request params"
    )
    XCTAssertNotNil(
      params[Keys.businessID],
      "Should have expected advertiser_id in aggregation request params"
    )
  }

  func testAttributedInvocationWithoutParameters() {
    let invocations = [
      SampleAEMData.invocationWithoutAdvertiserID,
      SampleAEMData.invocationWithAdvertiserID1,
      SampleAEMData.invocationWithAdvertiserID2,
    ]
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      invocations,
      event: Values.purchase,
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: configurations
    )
    XCTAssertNotNil(
      attributedInvocation,
      "Should have invocation attributed"
    )
    XCTAssertNil(
      attributedInvocation?.businessID,
      "The attributed invocation should not have advertiser ID"
    )
  }

  func testAttributedInvocationWithParameters() {
    let invocations = [
      SampleAEMData.invocationWithoutAdvertiserID,
      SampleAEMData.invocationWithAdvertiserID1,
      SampleAEMData.invocationWithAdvertiserID2,
    ]
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      invocations,
      event: "test",
      currency: nil,
      value: nil,
      parameters: ["values": "abcdefg"],
      configurations: configurations
    )
    XCTAssertNil(
      attributedInvocation,
      "Should not have invocation attributed"
    )
  }

  func testAttributedInvocationWithUnmatchedParameters() {
    let invocations = [
      SampleAEMData.invocationWithoutAdvertiserID,
      SampleAEMData.invocationWithAdvertiserID1,
      SampleAEMData.invocationWithAdvertiserID2,
    ]
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      invocations,
      event: Values.purchase,
      currency: nil,
      value: nil,
      parameters: ["value": "abcdefg"],
      configurations: configurations
    )
    XCTAssertNotNil(
      attributedInvocation,
      "Should have invocation attributed"
    )
    XCTAssertEqual(
      attributedInvocation?.businessID,
      SampleAEMData.invocationWithAdvertiserID1.businessID,
      "The attributed invocation should have advertiser ID"
    )
  }

  func testAttributedInvocationWithMultipleGeneralInvocations() {
    let invocation1 = SampleAEMInvocations.createGeneralInvocation1()
    let invocation2 = SampleAEMInvocations.createGeneralInvocation2()
    let invocations = [invocation1, invocation2]
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      invocations,
      event: Values.purchase,
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: configurations
    )
    XCTAssertEqual(
      attributedInvocation?.campaignID,
      invocation2.campaignID,
      "Should attribute the event to the latest general invocation"
    )
  }

  func testAttributedInvocationWithUnmatchedEvent() {
    let invocation1 = SampleAEMInvocations.createGeneralInvocation1()
    let invocation2 = SampleAEMInvocations.createGeneralInvocation2()
    let invocations = [invocation1, invocation2]
    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
      Values.brandMode: [SampleAEMConfigurations.createConfigurationWithBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      invocations,
      event: "test",
      currency: nil,
      value: nil,
      parameters: nil,
      configurations: configurations
    )
    XCTAssertNil(
      attributedInvocation,
      "Should not attribute the event with incorrect event"
    )
  }

  func testAttributedInvocationWithDoubleCounting() {
    reporter.cutOff = false
    reporter.reportingEvents = [Values.purchase]
    let invocation = SampleAEMInvocations.createSKANOverlappedInvocation()

    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      [invocation],
      event: Values.purchase,
      currency: Values.USD,
      value: 10,
      parameters: ["value": "abcdefg"],
      configurations: configurations
    )
    XCTAssertNil(
      attributedInvocation,
      "Should not have invocation attributed with double counting"
    )
    XCTAssertTrue(
      invocation.recordedEvents.isEmpty,
      "Should not expect invocation's recorded events to be changed with double counting"
    )
    XCTAssertTrue(
      invocation.recordedValues.isEmpty,
      "Should not expect invocation's recorded values to be changed with double counting"
    )
  }

  func testAttributedInvocationWithoutDoubleCounting() {
    reporter.cutOff = false
    reporter.reportingEvents = [Values.purchase]
    let invocation = SampleAEMInvocations.createGeneralInvocation1()

    let configurations = [
      Values.defaultMode: [SampleAEMConfigurations.createConfigurationWithoutBusinessID()],
    ]

    let attributedInvocation = AEMReporter.attributedInvocation(
      [invocation],
      event: Values.purchase,
      currency: Values.USD,
      value: 10,
      parameters: ["value": "abcdefg"],
      configurations: configurations
    )
    XCTAssertNotNil(
      attributedInvocation,
      "Should have invocation attributed without double counting"
    )
  }

  func testIsDoubleCounting() {
    reporter.cutOff = false
    reporter.reportingEvents = ["fb_test"]
    let invocation = SampleAEMInvocations.createSKANOverlappedInvocation()

    XCTAssertTrue(
      AEMReporter.isDoubleCounting(invocation, event: "fb_test"),
      "Should expect double counting"
    )
    XCTAssertFalse(
      AEMReporter.isDoubleCounting(invocation, event: "test"),
      "Should not expect double counting"
    )
  }

  func testIsDoubleCountingWithCutOff() {
    reporter.cutOff = true
    reporter.reportingEvents = ["fb_test"]
    let invocation = SampleAEMInvocations.createSKANOverlappedInvocation()

    XCTAssertFalse(
      AEMReporter.isDoubleCounting(invocation, event: "fb_test"),
      "Should not expect double counting with SKAN cutoff"
    )
  }

  func testIsDoubleCountingWithoutSKANClick() {
    reporter.cutOff = false
    reporter.reportingEvents = ["fb_test"]
    let invocation = SampleAEMInvocations.createGeneralInvocation1()

    XCTAssertFalse(
      AEMReporter.isDoubleCounting(invocation, event: "fb_test"),
      "Should not expect double counting without SKAN click"
    )
  }

  // MARK: - Catalog Reporting

  func testLoadCatalogOptimizationWithoutContentID() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    var blockCall = 0

    AEMReporter.loadCatalogOptimization(with: invocation, contentID: nil) {
      blockCall += 1
    }
    XCTAssertTrue(
      (networker.capturedGraphPath?.contains("aem_conversion_filter")) == true,
      "Should start the catalog request"
    )
    XCTAssertEqual(blockCall, 0, "Should not execute the block when contentID is nil")
  }

  func testLoadCatalogOptimizationWithOptimizedContent() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()
    var blockCall = 0

    AEMReporter.loadCatalogOptimization(with: invocation, contentID: "test_content_id") {
      blockCall += 1
    }
    XCTAssertTrue(
      (networker.capturedGraphPath?.contains("aem_conversion_filter")) == true,
      "Should start the catalog request"
    )
    networker.capturedCompletionHandler?(nil, SampleAEMError())
    XCTAssertEqual(blockCall, 0, "Should not execute the block when there is a network error")
    networker.capturedCompletionHandler?(["data": [["content_id_belongs_to_catalog_id": false]]], nil)
    XCTAssertEqual(blockCall, 0, "Should not execute the block when content is not optmized")
    networker.capturedCompletionHandler?(["data": [["content_id_belongs_to_catalog_id": true]]], nil)
    XCTAssertEqual(blockCall, 1, "Should execute the block when content is optmized")
  }

  func testLoadCatalogOptimizationWithFuzzyInput() {
    let invocation = SampleAEMInvocations.createCatalogOptimizedInvocation()

    AEMReporter.loadCatalogOptimization(with: invocation, contentID: "test_content_id") {}
    for _ in 0 ..< 100 {
      networker.capturedCompletionHandler?(
        Fuzzer.randomize(json: sampleCatalogOptimizationDictionary),
        nil
      )
    }
  }

  func testIsContentOptimized() {
    var data = [
      "data": [["content_id_belongs_to_catalog_id": true]],
    ]
    XCTAssertTrue(AEMReporter.isContentOptimized(data), "Should expect content is optimized")
    data = ["data": [["content_id_belongs_to_catalog_id": false]]]
    XCTAssertFalse(AEMReporter.isContentOptimized(data), "Should expect content is optimized")
  }

  func testCatalogRequestParameters() {
    let params = AEMReporter.catalogRequestParameters("test_catalog", contentID: "test_content_id")

    XCTAssertEqual(
      params as NSDictionary,
      [
        Keys.catalogID: "test_catalog",
        Keys.contentID: "test_content_id",
      ],
      "Catalog request parameters are not expected"
    )
  }

  func testCatalogRequestParametersWithMalformedInput() {
    let malformedInput = [nil, ""]

    for catalogID in malformedInput {
      for contentID in malformedInput {
        _ = AEMReporter.catalogRequestParameters(catalogID, contentID: contentID)
      }
    }
  }

  func testShouldReportConversionInCatalogLevel() {
    for conversionFilteringEnabled in [true, false] {
      for catalogMatchingEnabled in [true, false] {
        for isOptimizedEvent in [true, false] {
          for catalogID in ["test_catalog", nil] {
            AEMReporter.setConversionFilteringEnabled(conversionFilteringEnabled)
            AEMReporter.setCatalogMatchingEnabled(catalogMatchingEnabled)
            testInvocation.isOptimizedEvent = isOptimizedEvent
            testInvocation.catalogID = catalogID
            if conversionFilteringEnabled,
               catalogMatchingEnabled,
               isOptimizedEvent,
               catalogID != nil {
              XCTAssertTrue(
                AEMReporter.shouldReportConversion(inCatalogLevel: testInvocation, event: Values.purchase),
                "Should expect to report conversion in catalog level"
              )
            } else {
              XCTAssertFalse(
                AEMReporter.shouldReportConversion(inCatalogLevel: testInvocation, event: Values.purchase),
                "Should expect not to report conversion in catalog level"
              )
            }
          }
        }
      }
    }
  }

  // MARK: - Rule Match in Server

  func testLoadRuleMatch() {
    let content = #"[{"id": "123", "quantity": 5}]"#
    AEMReporter.loadRuleMatch(["123"], event: "test", currency: nil, value: nil, parameters: [Keys.content: content])
    let expectedParameters = [
      "advertiser_ids": #"["123"]"#,
      "fb_content_data": content,
    ]
    XCTAssertTrue(
      (networker.capturedGraphPath?.contains("aem_attribution")) == true,
      "Should start the rule match request"
    )
    XCTAssertEqual(
      networker.capturedParameters as? [String: String],
      expectedParameters,
      "Should have the expected parameters in the rule match request"
    )
  }

  // MARK: - Aggregation Request

  func testShouldDelayAggregationRequestWithNilTimestamp() {
    AEMReporter.minAggregationRequestTimestamp = nil
    XCTAssertFalse(
      AEMReporter.shouldDelayAggregationRequest(),
      "Should not expect to delay aggregation request when timestamp is nil"
    )
  }

  func testShouldDelayAggregationRequestWithExpiredTimestamp() {
    AEMReporter.minAggregationRequestTimestamp = aggregationRequestTimestampToNotDelay
    XCTAssertFalse(
      AEMReporter.shouldDelayAggregationRequest(),
      "Should not expect to delay aggregation request when timestamp is expired"
    )
  }

  func testShouldDelayAggregationRequestWithValidTimestamp() {
    AEMReporter.minAggregationRequestTimestamp = Date().addingTimeInterval(5)
    XCTAssertTrue(
      AEMReporter.shouldDelayAggregationRequest(),
      "Should not expect to delay aggregation request when timestamp is within the range"
    )
  }

  func testLoadMinAggregationRequestTimestamp() {
    let timestamp = Date()
    userDefaultsSpy.set(
      timestamp,
      forKey: "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp"
    )

    let data = AEMReporter.loadMinAggregationRequestTimestamp()
    XCTAssertEqual(
      timestamp,
      data,
      "Should return the timestamp from the userDefaultsSpy"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedObjectRetrievalKey,
      "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp",
      "Should retrieve the min aggregation request timestamp from the userDefaultsSpy"
    )
  }

  func testUpdateAggregationRequestTimestamp() {
    let timestamp = Date().timeIntervalSince1970
    AEMReporter.updateAggregationRequestTimestamp(timestamp)

    XCTAssertEqual(
      timestamp,
      AEMReporter.minAggregationRequestTimestamp?.timeIntervalSince1970,
      "Should set the expected tiemstamp"
    )
    XCTAssertEqual(
      userDefaultsSpy.capturedSetObjectKey,
      "com.facebook.sdk:FBAEMMinAggregationRequestTimestamp",
      "Should persist the min aggregation request timestamp when setting a new one"
    )
  }

  // MARK: - Helpers

  func removeReportFile() {
    do {
      try FileManager.default.removeItem(at: URL(fileURLWithPath: reportFilePath))
    } catch _ as NSError {}
  }
}
