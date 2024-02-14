/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import TestTools
import XCTest

final class DomainConfigurationManagerTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var requestFactory: TestGraphRequestFactory!
  var connectionFactory: TestGraphRequestConnectionFactory!
  var domainConfigurationManager: _DomainConfigurationManager!
  var settings: TestSettings!
  var dataStore: DataPersisting!
  // swiftlint:enable implicitly_unwrapped_optional

  let sampleResult: [String: Any] = [
    "id": 2020399148181142,
    "server_domain_infos": [
      "data": [
        [
          "endpoints": [
            [
              "key": "activities",
              "value": [
                "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
                "att_opt_out_domain_prefix": kEndpoint2URLPrefix,
              ],
            ],
            [
              "key": "custom_audience_third_party_id",
              "value": [
                "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
                "att_opt_out_domain_prefix": kEndpoint1URLPrefix,
              ],
            ],
            [
              "key": "app_indexing_session",
              "value": [
                "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
                "att_opt_out_domain_prefix": kEndpoint1URLPrefix,
              ],
            ],
            [
              "key": "default_config",
              "value": [
                "default_domain_prefix": kEndpoint2URLPrefix,
                "default_alternative_domain_prefix": kEndpoint1URLPrefix,
                "enable_for_early_versions": false,
              ],
            ],
          ],
        ],
      ],
    ],
  ]

  let defaultDomainInfo: [String: [String: Any]] = [
    "activities": [
      "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      "att_opt_out_domain_prefix": kEndpoint2URLPrefix,
    ],
    "custom_audience_third_party_id": [
      "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      "att_opt_out_domain_prefix": kEndpoint1URLPrefix,
    ],
    "app_indexing_session": [
      "att_opt_in_domain_prefix": kEndpoint1URLPrefix,
      "att_opt_out_domain_prefix": kEndpoint1URLPrefix,
    ],
    "default_config": [
      "default_domain_prefix": kEndpoint2URLPrefix,
      "default_alternative_domain_prefix": kEndpoint1URLPrefix,
      "enable_for_early_versions": false,
    ],
  ]

  override func setUp() {
    super.setUp()

    connectionFactory = TestGraphRequestConnectionFactory()
    requestFactory = TestGraphRequestFactory()
    domainConfigurationManager = _DomainConfigurationManager.sharedInstance()
    settings = TestSettings()
    dataStore = UserDefaultsSpy()
    domainConfigurationManager.configure(
      settings: settings,
      dataStore: dataStore,
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
    )
    _DomainConfiguration.setDefaultDomainInfo()
  }

  override func tearDown() {
    _DomainConfigurationManager.sharedInstance().reset()
    connectionFactory = nil
    requestFactory = nil
    _DomainConfiguration.resetDefaultDomainInfo()
    super.tearDown()
  }

  func testDefaultDependencies() {
    _DomainConfigurationManager.sharedInstance().reset()

    XCTAssertNil(
      domainConfigurationManager.graphRequestFactory,
      "Should not have a graph request factory by default"
    )
    XCTAssertNil(
      domainConfigurationManager.graphRequestConnectionFactory,
      "Should not have a graph request connection factory by default"
    )
  }

  func testConfiguringWithDependencies() {
    XCTAssertTrue(
      domainConfigurationManager.graphRequestFactory === requestFactory,
      "Should set the provided graph request factory"
    )
    XCTAssertTrue(
      domainConfigurationManager.graphRequestConnectionFactory === connectionFactory,
      "Should set the provided graph request connection factory"
    )
  }

  func testFailToLoadDomainConfigurationFromServer() {
    let failingConnection = TestGraphRequestConnection(
      shouldExecuteCompletion: true,
      error: TestSDKError(type: .general),
      requestConnectionResult: sampleResult
    )
    connectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: failingConnection)
    domainConfigurationManager.configure(
      settings: settings,
      dataStore: dataStore,
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
    )
    domainConfigurationManager.loadDomainConfiguration {}
    XCTAssertNil(
      domainConfigurationManager.domainConfiguration,
      "Should not have domainConfiguration when have error"
    )

    XCTAssertNotNil(
      domainConfigurationManager.domainConfigurationError,
      "Should set domainConfigurationError when have error"
    )

    guard let cachedDomainInfo = domainConfigurationManager.cachedDomainConfiguration().domainInfo,
          let defaultInfo = _DomainConfiguration.default().domainInfo else {
      XCTFail("Should not be nil")
      return
    }
    XCTAssertTrue(
      NSDictionary(dictionary: cachedDomainInfo).isEqual(to: defaultInfo),
      "Cached domain configuration should be the default on failure"
    )
  }

  func testSucceedToLoadDomainConfigurationFromServer() {
    let successfulConnection = TestGraphRequestConnection(
      shouldExecuteCompletion: true,
      error: nil,
      requestConnectionResult: sampleResult
    )
    connectionFactory = TestGraphRequestConnectionFactory(stubbedConnection: successfulConnection)
    domainConfigurationManager.configure(
      settings: settings,
      dataStore: dataStore,
      graphRequestFactory: requestFactory,
      graphRequestConnectionFactory: connectionFactory
    )
    domainConfigurationManager.loadDomainConfiguration {}
    XCTAssertNotNil(
      domainConfigurationManager.domainConfiguration,
      "Should have the domainConfiguration on success"
    )

    XCTAssertNil(
      domainConfigurationManager.domainConfigurationError,
      "Should not set domainConfigurationError on success"
    )
    guard let fetchedDomainInfo = domainConfigurationManager.domainConfiguration?.domainInfo else {
      XCTFail("Should not be nil")
      return
    }
    XCTAssertTrue(
      NSDictionary(dictionary: fetchedDomainInfo).isEqual(to: defaultDomainInfo),
      "Should have the correct domainConfiguration on success"
    )
  }

  func testProcessLoadRequestWithErrorResponse() {
    domainConfigurationManager.processLoadRequestResponse(
      sampleResult,
      error: TestSDKError(type: .general)
    )

    XCTAssertNil(
      domainConfigurationManager.domainConfiguration,
      "Should not have domainConfiguration when have error"
    )

    XCTAssertNotNil(
      domainConfigurationManager.domainConfigurationError,
      "Should set domainConfigurationError when have error"
    )
  }

  func testProcessLoadRequestWithValidResponse() throws {
    domainConfigurationManager.processLoadRequestResponse(
      sampleResult,
      error: nil
    )

    let domainConfiguration = try XCTUnwrap(
      domainConfigurationManager.domainConfiguration,
      "Should have valid domainConfiguration with valid response"
    )

    // test domainInfo in domainConfigurationManager
    XCTAssertEqualDicts(
      domainConfiguration.domainInfo,
      defaultDomainInfo,
      "Should get the excepted domain info"
    )

    XCTAssertNil(
      domainConfigurationManager.domainConfigurationError,
      "Should set domainConfigurationError nil when have valid domain info"
    )

    // test domainInfo in UserDefaults
    let defaultsKey = "com.facebook.sdk:domainConfiguration"
    let data = try XCTUnwrap(
      dataStore.fb_object(forKey: defaultsKey) as? Data,
      "Should have saved domain configuration"
    )
    let userDefaultsData = try NSKeyedUnarchiver.unarchivedObject(ofClass: _DomainConfiguration.self, from: data)
    let decodedData = try XCTUnwrap(
      userDefaultsData,
      "Should have saved domain configuration"
    )

    XCTAssertEqualDicts(
      decodedData.domainInfo,
      defaultDomainInfo,
      "Should get the excepted domain info"
    )
  }

  // MARK: - Helpers

  func XCTAssertEqualDicts(
    _ lhs: [String: Any]?,
    _ rhs: [String: Any]?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    if let lhs = lhs,
       let rhs = rhs {
      let dict1 = NSDictionary(dictionary: lhs)
      let dict2 = NSDictionary(dictionary: rhs)
      XCTAssertEqual(dict1, dict2, message(), file: file, line: line)
    } else if lhs == nil && rhs != nil {
      XCTFail("LHS Dict is nil", file: file, line: line)
    } else if lhs != nil && rhs == nil {
      XCTFail("RHS Dict is nil", file: file, line: line)
    }
  }
}
