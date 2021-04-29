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

import TestTools
import XCTest

// swiftlint:disable:next type_body_length
class FBSDKAEMReporterTests: XCTestCase {

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
  }

  enum Values {
    static let purchase = "fb_mobile_purchase"
    static let donate = "Donate"
    static let defaultMode = "DEFAULT"
    static let USD = "USD"
  }

  var requestProvider = TestGraphRequestFactory()
  let date = Calendar.current.date(
    byAdding: .day,
    value: -2,
    to: Date()
  )! // swiftlint:disable:this force_unwrapping
  var testInvocation = TestInvocation()
  lazy var reportFilePath = FBSDKBasicUtility.persistenceFilePath(name)
  let urlWithInvocation = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22test_token_1234567%22%2C+%22campaign_ids%22%3A+%22test_campaign_1234%22%2C+%22advertiser_id%22%3A+%22test_advertiserid_12345%22%7D")! // swiftlint:disable:this line_length force_unwrapping

  override func setUp() {
    super.setUp()

    reset()
    FBSDKAEMReporter.isEnabled = true
    FBSDKAEMReporter.reportFilePath = reportFilePath
  }

  func reset() {
    FBSDKAEMReporter.configure(withRequestProvider: requestProvider)
    FBSDKAEMReporter.queue = DispatchQueue.main
    FBSDKAEMReporter.invocations = []
    FBSDKAEMReporter.completionBlocks = []
    FBSDKAEMReporter.isLoadingConfiguration = false
    FBSDKAEMReporter.configs = [:]
    FBSDKAEMReporter._clearCache()
    removeReportFile()
  }

  func testEnable() {
    FBSDKAEMReporter.isEnabled = false
    FBSDKAEMReporter.enable()

    XCTAssertTrue(FBSDKAEMReporter.isEnabled, "AEM Report should be enabled")
  }

  func testParseURL() {
    var url: URL?
    XCTAssertNil(FBSDKAEMReporter.parseURL(url))

    url = URL(string: "fb123://test.com")
    XCTAssertNil(FBSDKAEMReporter.parseURL(url))

    url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22test_token_1234567%22%2C+%22campaign_ids%22%3A+%22test_campaign_1234%22%7D") // swiftlint:disable:this line_length
    var invocation = FBSDKAEMReporter.parseURL(url)
    XCTAssertEqual(invocation?.acsToken, "test_token_1234567")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertNil(invocation?.advertiserID)

    invocation = FBSDKAEMReporter.parseURL(urlWithInvocation)
    XCTAssertEqual(invocation?.acsToken, "test_token_1234567")
    XCTAssertEqual(invocation?.campaignID, "test_campaign_1234")
    XCTAssertEqual(invocation?.advertiserID, "test_advertiserid_12345")
  }

  func testLoadReportData() {
    guard let invocation = FBSDKAEMReporter.parseURL(urlWithInvocation) else {
      return XCTFail("Parsing Error")
    }

    FBSDKAEMReporter.invocations = [invocation]
    FBSDKAEMReporter._saveReportData()
    let data = FBSDKAEMReporter._loadReportData() as? [FBSDKAEMInvocation]
    XCTAssertEqual(data?.count, 1)
    XCTAssertEqual(data?[0].acsToken, "test_token_1234567")
    XCTAssertEqual(data?[0].campaignID, "test_campaign_1234")
    XCTAssertEqual(data?[0].advertiserID, "test_advertiserid_12345")
  }

  func testLoadConfigs() {
    FBSDKAEMReporter._addConfigs([SampleAEMData.validConfigData1])
    FBSDKAEMReporter._addConfigs([SampleAEMData.validConfigData1, SampleAEMData.validConfigData2])
    let loadedConfigs: NSMutableDictionary? = FBSDKAEMReporter._loadConfigs()
    XCTAssertEqual(loadedConfigs?.count, 1, "Should load the expected number of configs")

    let defaultConfigs: [FBSDKAEMConfiguration]? = loadedConfigs?[Values.defaultMode] as? [FBSDKAEMConfiguration]
    XCTAssertEqual(
      defaultConfigs?.count, 2, "Should load the expected number of default configs"
    )
    XCTAssertEqual(
      defaultConfigs?[0].defaultCurrency, Values.USD, "Should save the expected default_currency of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[0].cutoffTime, 1, "Should save the expected cutoff_time of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[0].validFrom, 10000, "Should save the expected valid_from of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[0].configMode, Values.defaultMode, "Should save the expected config_mode of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[0].conversionValueRules.count, 1, "Should save the expected conversion_value_rules of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[1].defaultCurrency, Values.USD, "Should save the expected default_currency of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[1].cutoffTime, 1, "Should save the expected cutoff_time of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[1].validFrom, 10001, "Should save the expected valid_from of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[1].configMode, Values.defaultMode, "Should save the expected config_mode of the config"
    )
    XCTAssertEqual(
      defaultConfigs?[1].conversionValueRules.count, 2, "Should save the expected conversion_value_rules of the config"
    )
  }

  func testClearCache() {
    FBSDKAEMReporter._addConfigs([SampleAEMData.validConfigData1])
    FBSDKAEMReporter._addConfigs([SampleAEMData.validConfigData1, SampleAEMData.validConfigData2])

    FBSDKAEMReporter._clearCache()
    var configs: NSDictionary? = FBSDKAEMReporter.configs
    var configList: [FBSDKAEMConfiguration]? = configs?[Values.defaultMode] as? [FBSDKAEMConfiguration]
    XCTAssertEqual(configList?.count, 1, "Should have the expected number of configs")

    guard let invocation1 = FBSDKAEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigID: "test_config_id_123",
      advertiserID: "test_advertiserid_12345"
    ), let invocation2 = FBSDKAEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigID: "test_config_id_123",
      advertiserID: "test_advertiserid_12345"
    )
    else { return XCTFail("Unwrapping Error") }
    invocation1.setConfigID(10000)
    invocation2.setConfigID(10001)
    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    invocation2.setConversionTimestamp(date)
    FBSDKAEMReporter.invocations = [invocation1, invocation2]
    FBSDKAEMReporter._addConfigs(
      [SampleAEMData.validConfigData1, SampleAEMData.validConfigData2, SampleAEMData.validConfigData3]
    )
    FBSDKAEMReporter._clearCache()
    let invocations = FBSDKAEMReporter.invocations as? [FBSDKAEMInvocation]
    XCTAssertEqual(invocations?.count, 1, "Should clear the expired invocation")
    XCTAssertEqual(invocations?[0].configID, 10000, "Should keep the expected invocation")
    configs = FBSDKAEMReporter.configs
    configList = configs?[Values.defaultMode] as? [FBSDKAEMConfiguration]
    XCTAssertEqual(configList?.count, 2, "Should have the expected number of configs")
    XCTAssertEqual(configList?[0].validFrom, 10000, "Should keep the expected config")
    XCTAssertEqual(configList?[1].validFrom, 20000, "Should keep the expected config")
  }

  func testHandleURL() {
    guard let url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22test_token_1234567%22%2C+%22campaign_ids%22%3A+%22test_campaign_1234%22%7D") // swiftlint:disable:this line_length
    else { return XCTFail("Unwrapping Error") }
    FBSDKAEMReporter.handle(url)
    let invocations = FBSDKAEMReporter.invocations
    XCTAssertTrue(
      invocations.count > 0, // swiftlint:disable:this empty_count
      "Handling a url that contains invocations should set the invocations on the reporter"
    )
  }

  func testIsConfigRefreshTimestampValid() {
    FBSDKAEMReporter.timestamp = Date()
    XCTAssertTrue(
      FBSDKAEMReporter._isConfigRefreshTimestampValid(),
      "Timestamp should be valid"
    )

    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    FBSDKAEMReporter.timestamp = date
    XCTAssertFalse(
      FBSDKAEMReporter._isConfigRefreshTimestampValid(),
      "Timestamp should not be valid"
    )
  }

  func testSendAggregationRequest() {
    FBSDKAEMReporter._sendAggregationRequest()
    XCTAssertNil(
      self.requestProvider.capturedGraphPath,
      "GraphRequest should be created because of there is no invocation"
    )

    guard let invocation = FBSDKAEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    FBSDKAEMReporter.invocations = [invocation]
    FBSDKAEMReporter._sendAggregationRequest()
    XCTAssertTrue(
      self.requestProvider.capturedGraphPath?.hasSuffix("aem_conversions") == true,
      "GraphRequst should created because of there is non-aggregated invocation"
    )
  }

  func testCompletingAggregationRequestWithError() {
    let request = TestGraphRequest()
    requestProvider.stubbedRequest = request
    guard let invocation = FBSDKAEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    FBSDKAEMReporter.invocations = [invocation]
    FBSDKAEMReporter._sendAggregationRequest()

    request.capturedCompletionHandler?(nil, nil, SampleError())
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
    let request = TestGraphRequest()
    requestProvider.stubbedRequest = request
    guard let invocation = FBSDKAEMReporter.parseURL(urlWithInvocation) else { return XCTFail("Parsing Error") }
    invocation.isAggregated = false
    FBSDKAEMReporter.invocations = [invocation]
    FBSDKAEMReporter._sendAggregationRequest()

    request.capturedCompletionHandler?(nil, nil, nil)
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
    FBSDKAEMReporter.timestamp = Date()
    guard let invocation = FBSDKAEMInvocation(
      campaignID: "test_campaign_1234",
      acsToken: "test_token_1234567",
      acsSharedSecret: "test_shared_secret",
      acsConfigID: "test_config_id_123",
      advertiserID: "test_advertiserid_12345"
    )
    else { return XCTFail("Unwrapping Error") }
    guard let config = FBSDKAEMConfiguration(json: SampleAEMData.validConfigData3)
    else { return XCTFail("Unwrapping Error") }

    FBSDKAEMReporter.configs = [Values.defaultMode: [config]]
    FBSDKAEMReporter.invocations = NSMutableArray(array: [invocation])
    FBSDKAEMReporter.recordAndUpdateEvent(Values.purchase, currency: Values.USD, value: 100)
    // Invocation should be attributed and updated while request should be sent
    XCTAssertTrue(
      self.requestProvider.capturedGraphPath?.hasSuffix("aem_conversions") == true,
      "Should create a request to update the conversions for a valid event"
    )
    XCTAssertFalse(
      invocation.isAggregated,
      "Should not mark the invocation as aggregated if it is recorded and sent"
    )
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: self.reportFilePath),
      "Should save uploaded events to disk"
    )
  }

  func testRecordAndUpdateEventsWithAEMDisabled() {
    FBSDKAEMReporter.isEnabled = false
    FBSDKAEMReporter.timestamp = date

    FBSDKAEMReporter.recordAndUpdateEvent(Values.purchase, currency: Values.USD, value: 100)
    XCTAssertNil(
      requestProvider.capturedGraphPath?.hasSuffix("aem_conversion_configs"),
      "Should not create a request to fetch the config if AEM is disabled"
    )
  }

  func testRecordAndUpdateEventsWithEmptyEvent() {
    FBSDKAEMReporter.timestamp = self.date

    FBSDKAEMReporter.recordAndUpdateEvent("", currency: Values.USD, value: 100)

    XCTAssertNil(
      requestProvider.capturedGraphPath?.hasSuffix("aem_conversion_configs"),
      "Should not create a request to fetch the config if the event being recorded is empty"
    )
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: self.reportFilePath),
      "Should not save an empty event to disk"
    )
  }

  func testRecordAndUpdateEventsWithEmptyConfigs() {
    FBSDKAEMReporter.timestamp = date
    FBSDKAEMReporter.invocations = [testInvocation]

    FBSDKAEMReporter.recordAndUpdateEvent(Values.purchase, currency: Values.USD, value: 100)
    guard testInvocation.attributionCallCount == 0,
          testInvocation.updateConversionCallCount == 0 else {
      return XCTFail("Should update attribute and conversions")
    }
  }

  func testLoadConfigurationWithBlock() {
    guard let config = FBSDKAEMConfiguration(json: SampleAEMData.validConfigData3)
    else { return XCTFail("Unwrapping Error") }
    var blockCall = 0
    FBSDKAEMReporter.timestamp = Date()
    FBSDKAEMReporter.configs = [Values.defaultMode: [config]]

    FBSDKAEMReporter._loadConfiguration { _ in
      blockCall += 1
    }
    XCTAssertEqual(
      blockCall,
      1,
      "Should call the completion when loading the configuration"
    )
  }

  func testLoadConfigurationWithoutBlock() {
    FBSDKAEMReporter.timestamp = date

    FBSDKAEMReporter._loadConfiguration(block: nil)
    XCTAssertTrue(
      self.requestProvider.capturedGraphPath?.hasSuffix("aem_conversion_configs") == true,
      "Should not require a completion block to load a configuration"
    )
  }

  // MARK: - Helpers

  func removeReportFile() {
    do {
      try FileManager.default.removeItem(at: URL(fileURLWithPath: reportFilePath))
    } catch _ as NSError { }
  }
}
