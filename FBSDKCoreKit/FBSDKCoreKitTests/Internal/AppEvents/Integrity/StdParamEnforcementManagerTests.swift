/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class StdParamEnforcementManagerTests: XCTestCase {

  // swiftlint:enable:this multiline_literal_brackets trailing_comma
  let serverConfigDict = [
    "protectedModeRules": [
      "standard_params_schema": [
        ["key": "fb_currency", "value": [
          ["require_exact_match": false, "potential_matches": ["^[a-zA-Z]{3}$"]],
          ["require_exact_match": true, "potential_matches": ["USDP", "TEST"]],
        ]],
        ["key": "fb_value", "value": [
          ["require_exact_match": false, "potential_matches": ["^-?\\d+(?:\\.\\d+)?$"]],
        ]],
        ["key": "fb_order_id", "value": [
          ["require_exact_match": false, "potential_matches": ["^.{0,1000}$"]],
        ]],
        ["key": "fb_content_ids", "value": [
          ["require_exact_match": false, "potential_matches": ["^.{0,1000}$"]],
        ]],
      ],
    ],
  ]

  lazy var serverConfiguration = ServerConfigurationFixtures.configuration(withDictionary: serverConfigDict)

  // swiftlint:disable implicitly_unwrapped_optional
  var provider: TestServerConfigurationProvider!
  var stdParamEnforcementManager: StdParamEnforcementManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    stdParamEnforcementManager = StdParamEnforcementManager()
    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    stdParamEnforcementManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
  }

  override func tearDown() {
    super.tearDown()
    stdParamEnforcementManager = nil
    provider = nil
  }

  func testDefaultDependencies() throws {
    stdParamEnforcementManager.resetDependencies()
    XCTAssertTrue(
      stdParamEnforcementManager.serverConfigurationProvider === _ServerConfigurationManager.shared,
      "Should use the shared server configuration manger by default"
    )
  }

  func testConfiguringDependencies() {
    XCTAssertTrue(
      stdParamEnforcementManager.serverConfigurationProvider === provider,
      "Should be able to create with a server configuration provider"
    )
  }

  func testEnable() {
    let expectedStdParamsRegexConfig: [String: Set<String>] = [
      "fb_currency": ["^[a-zA-Z]{3}$"],
      "fb_value": ["^-?\\d+(?:\\.\\d+)?$"],
      "fb_order_id": ["^.{0,1000}$"],
      "fb_content_ids": ["^.{0,1000}$"],
    ]
    let expectedStdParamsEnumConfig: [String: Set<String>] = [
      "fb_currency": ["USDP", "TEST"],
    ]
    stdParamEnforcementManager.enable()
    XCTAssertTrue(stdParamEnforcementManager.getIsEnabled() == true)
    XCTAssertTrue(stdParamEnforcementManager.getRegexRestrictionsConfig() == expectedStdParamsRegexConfig)
    XCTAssertTrue(stdParamEnforcementManager.getEnumRestrictionsConfig() == expectedStdParamsEnumConfig)
  }

  func testNotEnablesIfNoConfigIsNotPresent() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "standard_params_schema": [],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    stdParamEnforcementManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    stdParamEnforcementManager.enable()
    XCTAssertTrue(stdParamEnforcementManager.getIsEnabled() == false)
    XCTAssertTrue(stdParamEnforcementManager.getRegexRestrictionsConfig().isEmpty)
    XCTAssertTrue(stdParamEnforcementManager.getEnumRestrictionsConfig().isEmpty)
  }

  func testEnumRestriction() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "standard_params_schema": [
          ["key": "fb_currency", "value": [
            ["require_exact_match": true, "potential_matches": ["USDP", "TEST"]],
          ]],
        ],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    stdParamEnforcementManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    stdParamEnforcementManager.enable()
    XCTAssertTrue(stdParamEnforcementManager.getIsEnabled() == true)

    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "fb_currency"): "USDP",
    ]

    let expectedFilteredParams: NSDictionary = [
      AppEvents.ParameterName(rawValue: "fb_currency"): "USDP",
    ]

    let filteredParams = stdParamEnforcementManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }

  func testSchemaEnumRestrictionWhenNoRulePasses() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "standard_params_schema": [
          ["key": "fb_currency", "value": [
            ["require_exact_match": true, "potential_matches": ["USDP", "TEST"]],
          ]],
        ],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    stdParamEnforcementManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    stdParamEnforcementManager.enable()
    XCTAssertTrue(stdParamEnforcementManager.getIsEnabled() == true)
    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "fb_currency"): "NOT_COMPLIANT",
    ]
    let expectedFilteredParams: NSDictionary = [:]
    let filteredParams = stdParamEnforcementManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }

  func testSchemaRegexRestrictionWhenSomeRulePasses() {
    stdParamEnforcementManager.enable()
    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "fb_content_ids"): "compliant_content_123",
      AppEvents.ParameterName(rawValue: "fb_currency"): "ABC",
      AppEvents.ParameterName(rawValue: "fb_value"): "23",
    ]

    let expectedFilteredParams: NSDictionary = [
      AppEvents.ParameterName(rawValue: "fb_content_ids"): "compliant_content_123",
      AppEvents.ParameterName(rawValue: "fb_currency"): "ABC",
      AppEvents.ParameterName(rawValue: "fb_value"): "23",
    ]

    let filteredParams = stdParamEnforcementManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }

  func testSchemaRegexRestrictionWhenAllRulesFail() {
    stdParamEnforcementManager.enable()
    XCTAssertTrue(stdParamEnforcementManager.getIsEnabled() == true)

    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "fb_value"): "NOT_COMPLIANT",
    ]

    let expectedFilteredParams: NSDictionary = [:]

    let filteredParams = stdParamEnforcementManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }

  func testSchemaBlockedRule() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "standard_params_schema": [
          ["key": "some_std_param", "value": [
            ["require_exact_match": true, "potential_matches": []],
          ]],
        ],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    stdParamEnforcementManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    stdParamEnforcementManager.enable()
    XCTAssertTrue(stdParamEnforcementManager.getIsEnabled() == true)
    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "some_std_param"): "random_value",
    ]
    let expectedFilteredParams: NSDictionary = [:]
    let filteredParams = stdParamEnforcementManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }
}
