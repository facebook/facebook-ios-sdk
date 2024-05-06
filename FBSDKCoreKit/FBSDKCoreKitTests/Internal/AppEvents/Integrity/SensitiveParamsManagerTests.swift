/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class SensitiveParamsManagerTests: XCTestCase {

  let serverConfigDict = [
    "protectedModeRules": [
      "sensitive_params": [
        [
          "key": "test_event_name_1",
          "value": ["test_sensitive_param_1", "test_sensitive_param_2"],
        ],
        [
          "key": "test_event_name_2",
          "value": ["test_sensitive_param_2", "test_sensitive_param_3", "test_sensitive_param_4"],
        ],
        [
          "key": "_MTSDK_Default_",
          "value": ["default_param_1", "default_param_2"],
        ],
      ],
    ],
  ]

  lazy var serverConfiguration = ServerConfigurationFixtures.configuration(withDictionary: serverConfigDict)

  // swiftlint:disable implicitly_unwrapped_optional
  var provider: TestServerConfigurationProvider!
  var sensitiveParamsManager: SensitiveParamsManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    sensitiveParamsManager = SensitiveParamsManager()
    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    sensitiveParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
  }

  override func tearDown() {
    super.tearDown()
    sensitiveParamsManager = nil
    provider = nil
  }

  func testDefaultDependencies() throws {
    sensitiveParamsManager.resetDependencies()
    XCTAssertTrue(
      sensitiveParamsManager.serverConfigurationProvider === _ServerConfigurationManager.shared,
      "Should use the shared server configuration manger by default"
    )
  }

  func testConfiguringDependencies() {
    XCTAssertTrue(
      sensitiveParamsManager.serverConfigurationProvider === provider,
      "Should be able to create with a server configuration provider"
    )
  }

  func testEnable1() {
    let expectedSensitiveParamsConfig: [String: Set<String>] = [
      "test_event_name_1": ["test_sensitive_param_1", "test_sensitive_param_2"],
      "test_event_name_2": ["test_sensitive_param_2", "test_sensitive_param_3", "test_sensitive_param_4"],
    ]
    let expectedDefaultSensitiveParams: Set<String> = ["default_param_1", "default_param_2"]
    sensitiveParamsManager.enable()
    XCTAssertTrue(sensitiveParamsManager.getIsEnabled())
    XCTAssertTrue(sensitiveParamsManager.getSensitiveParamsConfig() == expectedSensitiveParamsConfig)
    XCTAssertTrue(sensitiveParamsManager.getDefaultSensitiveParams() == expectedDefaultSensitiveParams)
  }

  func testEnable2() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "sensitive_params": [
          [
            "key": "test_event_name_1",
            "value": ["test_sensitive_param_1", "test_sensitive_param_2"],
          ],
          [
            "key": "test_event_name_2",
            "value": ["test_sensitive_param_2", "test_sensitive_param_3", "test_sensitive_param_4"],
          ],
        ],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    sensitiveParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    let expectedSensitiveParamsConfig: [String: Set<String>] = [
      "test_event_name_1": ["test_sensitive_param_1", "test_sensitive_param_2"],
      "test_event_name_2": ["test_sensitive_param_2", "test_sensitive_param_3", "test_sensitive_param_4"],
    ]
    sensitiveParamsManager.enable()
    XCTAssertTrue(sensitiveParamsManager.getIsEnabled())
    XCTAssertTrue(sensitiveParamsManager.getSensitiveParamsConfig() == expectedSensitiveParamsConfig)
    XCTAssertTrue(sensitiveParamsManager.getDefaultSensitiveParams().isEmpty)
  }

  func testEnable3() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "sensitive_params": [
          [
            "key": "_MTSDK_Default_",
            "value": ["default_param_1", "default_param_2"],
          ],
        ],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    sensitiveParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    let expectedDefaultSensitiveParams: Set<String> = ["default_param_1", "default_param_2"]
    sensitiveParamsManager.enable()
    XCTAssertTrue(sensitiveParamsManager.getIsEnabled())
    XCTAssertTrue(sensitiveParamsManager.getSensitiveParamsConfig().isEmpty)
    XCTAssertTrue(sensitiveParamsManager.getDefaultSensitiveParams() == expectedDefaultSensitiveParams)
  }

  func testEnable4() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "sensitive_params": [],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    sensitiveParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    sensitiveParamsManager.enable()
    XCTAssertFalse(sensitiveParamsManager.getIsEnabled())
    XCTAssertTrue(sensitiveParamsManager.getSensitiveParamsConfig().isEmpty)
    XCTAssertTrue(sensitiveParamsManager.getDefaultSensitiveParams().isEmpty)
  }

  func testEnable5() {
    let testServerConfigDict = [
      "protectedModeRules": [],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    sensitiveParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    sensitiveParamsManager.enable()
    XCTAssertFalse(sensitiveParamsManager.getIsEnabled())
    XCTAssertTrue(sensitiveParamsManager.getSensitiveParamsConfig().isEmpty)
    XCTAssertTrue(sensitiveParamsManager.getDefaultSensitiveParams().isEmpty)
  }

  func testProcessParams1() {
    sensitiveParamsManager.enable()
    let eventName = AppEvents.Name(rawValue: "test_event_name_1")
    let parameters = [
      AppEvents.ParameterName.currency: "CAD",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_1"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_2"): "This is a sensitive param",
    ]
    let expectedFilteredParams: [AppEvents.ParameterName: Any] = [
      AppEvents.ParameterName.currency: "CAD",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "_filteredKey"): ["test_sensitive_param_1", "test_sensitive_param_2"],
    ]
    let filteredParams = sensitiveParamsManager.processParameters(parameters, eventName: eventName)
    XCTAssertEqual(filteredParams?.count, 3)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "test_sensitive_param_1")), false)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "test_sensitive_param_2")), false)
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.currency] as? String,
      expectedFilteredParams[AppEvents.ParameterName.currency] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.description] as? String,
      expectedFilteredParams[AppEvents.ParameterName.description] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "_filteredKey")] as? Set<String>,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "_filteredKey")] as? Set<String>
    )
  }

  func testProcessParams2() {
    sensitiveParamsManager.enable()
    let eventName = AppEvents.Name(rawValue: "test_event_name_2")
    let parameters = [
      AppEvents.ParameterName.currency: "USD",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_2"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_4"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "default_param_1"): "This is a default sensitive param",
    ]
    let expectedFilteredParams: [AppEvents.ParameterName: Any] = [
      AppEvents.ParameterName.currency: "USD",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "_filteredKey"): [
        "test_sensitive_param_2",
        "test_sensitive_param_4",
        "default_param_1",
      ],
    ]
    let filteredParams = sensitiveParamsManager.processParameters(parameters, eventName: eventName)
    XCTAssertEqual(filteredParams?.count, 3)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "test_sensitive_param_2")), false)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "test_sensitive_param_4")), false)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "default_param_1")), false)
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.currency] as? String,
      expectedFilteredParams[AppEvents.ParameterName.currency] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.description] as? String,
      expectedFilteredParams[AppEvents.ParameterName.description] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "_filteredKey")] as? Set<String>,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "_filteredKey")] as? Set<String>
    )
  }

  func testProcessParams3() {
    sensitiveParamsManager.enable()
    let eventName = AppEvents.Name(rawValue: "test_event_name_3")
    let parameters = [
      AppEvents.ParameterName.currency: "GBP",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_1"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_3"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "default_param_2"): "This is a default sensitive param",
    ]
    let expectedFilteredParams: [AppEvents.ParameterName: Any] = [
      AppEvents.ParameterName.currency: "GBP",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_1"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_3"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "_filteredKey"): ["default_param_2"],
    ]
    let filteredParams = sensitiveParamsManager.processParameters(parameters, eventName: eventName)
    XCTAssertEqual(filteredParams?.count, 5)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "default_param_2")), false)
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.currency] as? String,
      expectedFilteredParams[AppEvents.ParameterName.currency] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.description] as? String,
      expectedFilteredParams[AppEvents.ParameterName.description] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "test_sensitive_param_1")] as? String,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "test_sensitive_param_1")] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "test_sensitive_param_3")] as? String,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "test_sensitive_param_3")] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "_filteredKey")] as? Set<String>,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "_filteredKey")] as? Set<String>
    )
  }

  func testProcessParams4() {
    sensitiveParamsManager.enable()
    let eventName = AppEvents.Name(rawValue: "test_event_name_3")
    let parameters = [
      AppEvents.ParameterName.currency: "GBP",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_1"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_3"): "This is a sensitive param",
    ]
    let expectedFilteredParams: [AppEvents.ParameterName: Any] = [
      AppEvents.ParameterName.currency: "GBP",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_1"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_3"): "This is a sensitive param",
    ]
    let filteredParams = sensitiveParamsManager.processParameters(parameters, eventName: eventName)
    XCTAssertEqual(filteredParams?.count, 4)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "_filteredKey")), false)
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.currency] as? String,
      expectedFilteredParams[AppEvents.ParameterName.currency] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.description] as? String,
      expectedFilteredParams[AppEvents.ParameterName.description] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "test_sensitive_param_1")] as? String,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "test_sensitive_param_1")] as? String
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "test_sensitive_param_3")] as? String,
      expectedFilteredParams[AppEvents.ParameterName(rawValue: "test_sensitive_param_3")] as? String
    )
  }

  func testProcessParamsNotEnabled() {
    let eventName = AppEvents.Name(rawValue: "test_event_name_1")
    let parameters = [
      AppEvents.ParameterName.currency: "CAD",
      AppEvents.ParameterName.description: "This is a test event",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_1"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "test_sensitive_param_2"): "This is a sensitive param",
      AppEvents.ParameterName(rawValue: "default_param_1"): "This is a default sensitive param",
      AppEvents.ParameterName(rawValue: "default_param_2"): "This is a default sensitive param",
    ]
    let filteredParams = sensitiveParamsManager.processParameters(parameters, eventName: eventName)
    XCTAssertEqual(filteredParams?.count, 6)
    XCTAssertEqual(filteredParams?.keys.contains(AppEvents.ParameterName(rawValue: "_filteredKey")), false)
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.currency] as? String,
      parameters[AppEvents.ParameterName.currency]
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName.description] as? String,
      parameters[AppEvents.ParameterName.description]
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "test_sensitive_param_1")] as? String,
      parameters[AppEvents.ParameterName(rawValue: "test_sensitive_param_1")]
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "test_sensitive_param_2")] as? String,
      parameters[AppEvents.ParameterName(rawValue: "test_sensitive_param_2")]
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "default_param_1")] as? String,
      parameters[AppEvents.ParameterName(rawValue: "default_param_1")]
    )
    XCTAssertEqual(
      filteredParams?[AppEvents.ParameterName(rawValue: "default_param_2")] as? String,
      parameters[AppEvents.ParameterName(rawValue: "default_param_2")]
    )
  }
}
