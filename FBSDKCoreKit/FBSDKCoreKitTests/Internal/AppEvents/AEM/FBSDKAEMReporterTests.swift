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

  func testEnable() {
    FBSDKAEMReporter.enable()

    XCTAssertTrue(FBSDKAEMReporter.isEnabled(), "AEM Report should be enabled")
  }

  func testParseURL() {
    FBSDKAEMReporter.enable()
    FBSDKAEMReporter._clearCache()
    var url: URL?
    var invocation: FBSDKAEMInvocation?

    XCTAssertNil(FBSDKAEMReporter.parseURL(url))

    url = URL(string: "fb123://test.com")
    XCTAssertNil(FBSDKAEMReporter.parseURL(url))

    url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22acstoken%22%2C+%22campaign_id%22%3A+%22campaignid%22%7D") // swiftlint:disable:this line_length
    invocation = FBSDKAEMReporter.parseURL(url)
    XCTAssertEqual(invocation?.acsToken, "acstoken")
    XCTAssertEqual(invocation?.campaignID, "campaignid")
    XCTAssertNil(invocation?.advertiserID)

    url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22acstoken%22%2C+%22campaign_id%22%3A+%22campaignid%22%2C+%22advertiser_id%22%3A+%22advertiserid%22%7D") // swiftlint:disable:this line_length
    invocation = FBSDKAEMReporter.parseURL(url)
    XCTAssertEqual(invocation?.acsToken, "acstoken")
    XCTAssertEqual(invocation?.campaignID, "campaignid")
    XCTAssertEqual(invocation?.advertiserID, "advertiserid")
  }

  func testLoadReportData() {
    FBSDKAEMReporter.enable()
    FBSDKAEMReporter._clearCache()
    let url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22acstoken%22%2C+%22campaign_id%22%3A+%22campaignid%22%2C+%22advertiser_id%22%3A+%22advertiserid%22%7D") // swiftlint:disable:this line_length
    guard let invocation = FBSDKAEMReporter.parseURL(url) else { return XCTFail("Parsing Error") }
    FBSDKAEMReporter.setInvocations([invocation])
    FBSDKAEMReporter._saveReportData()
    let data: [FBSDKAEMInvocation]? = FBSDKAEMReporter._loadReportData() as? [FBSDKAEMInvocation]
    XCTAssertEqual(data?.count, 1)
    XCTAssertEqual(data?[0].acsToken, "acstoken")
    XCTAssertEqual(data?[0].campaignID, "campaignid")
    XCTAssertEqual(data?[0].advertiserID, "advertiserid")
  }

  func testLoadConfigs() {
    FBSDKAEMReporter.enable()
    FBSDKAEMReporter._clearCache()
    FBSDKAEMReporter.setConfigs([:])
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
    FBSDKAEMReporter.enable()
    FBSDKAEMReporter._clearCache()
    FBSDKAEMReporter.setConfigs([:])
    FBSDKAEMReporter._addConfigs([SampleAEMData.validConfigData1])
    FBSDKAEMReporter._addConfigs([SampleAEMData.validConfigData1, SampleAEMData.validConfigData2])

    FBSDKAEMReporter._clearCache()
    var configs: NSDictionary? = FBSDKAEMReporter.getConfigs()
    var configList: [FBSDKAEMConfiguration]? = configs?[Values.defaultMode] as? [FBSDKAEMConfiguration]
    XCTAssertEqual(configList?.count, 1, "Should have the expected number of configs")

    guard let invocation1 = FBSDKAEMInvocation(
      campaignID: "campaignid",
      acsToken: "acstoken",
      acsSharedSecret: "acssharedsecret",
      acsConfigID: "acsconfigid",
      advertiserID: "advertiserid"
    ), let invocation2 = FBSDKAEMInvocation(
      campaignID: "campaignid",
      acsToken: "acstoken",
      acsSharedSecret: "acssharedsecret",
      acsConfigID: "acsconfigid",
      advertiserID: "advertiserid"
    )
    else { return XCTFail("Unwrapping Error") }
    invocation1.setConfigID(10000)
    invocation2.setConfigID(10001)
    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    invocation2.setConversionTimestamp(date)
    FBSDKAEMReporter.setInvocations([invocation1, invocation2])
    FBSDKAEMReporter._addConfigs(
      [SampleAEMData.validConfigData1, SampleAEMData.validConfigData2, SampleAEMData.validConfigData3]
    )
    FBSDKAEMReporter._clearCache()
    let invocations = FBSDKAEMReporter.getInvocations() as? [FBSDKAEMInvocation]
    XCTAssertEqual(invocations?.count, 1, "Should clear the expired invocation")
    XCTAssertEqual(invocations?[0].configID, 10000, "Should keep the expected invocation")
    configs = FBSDKAEMReporter.getConfigs()
    configList = configs?[Values.defaultMode] as? [FBSDKAEMConfiguration]
    XCTAssertEqual(configList?.count, 2, "Should have the expected number of configs")
    XCTAssertEqual(configList?[0].validFrom, 10000, "Should keep the expected config")
    XCTAssertEqual(configList?[1].validFrom, 20000, "Should keep the expected config")
  }

  func testHandleURL() {
    let expectation = self.expectation(description: name)
    FBSDKAEMReporter._clearCache()
    FBSDKAEMReporter.setEnabled(true)
    FBSDKAEMReporter.setInvocations([])
    FBSDKAEMReporter.setQueue(DispatchQueue.main)

    guard let url = URL(string: "fb123://test.com?al_applink_data=%7B%22acs_token%22%3A+%22acstoken%22%2C+%22campaign_id%22%3A+%22campaignid%22%7D") // swiftlint:disable:this line_length
    else { return XCTFail("Unwrapping Error") }
    FBSDKAEMReporter.handle(url)
    DispatchQueue.main.async {
      let invocations = FBSDKAEMReporter.getInvocations()
      if (invocations.count > 0) { // swiftlint:disable:this empty_count control_statement
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: 5, handler: nil)
  }

  func testIsConfigRefreshTimestampValid() {
    FBSDKAEMReporter.setTimestamp(Date())
    XCTAssertTrue(
      FBSDKAEMReporter._isConfigRefreshTimestampValid(),
      "Timestamp should be valid"
    )

    guard let date = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    else { return XCTFail("Date Creation Error") }
    FBSDKAEMReporter.setTimestamp(date)
    XCTAssertFalse(
      FBSDKAEMReporter._isConfigRefreshTimestampValid(),
      "Timestamp should not be valid"
    )
  }
}
