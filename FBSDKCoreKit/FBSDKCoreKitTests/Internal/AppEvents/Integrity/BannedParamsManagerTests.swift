/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

final class BannedParamsManagerTests: XCTestCase {

  let serverConfigDict = [
    "protectedModeRules": [
      "standard_params_blocked": [
        "predicted_ltv",
      ],
    ],
  ]

  lazy var serverConfiguration = ServerConfigurationFixtures.configuration(withDictionary: serverConfigDict)

  // swiftlint:disable implicitly_unwrapped_optional
  var provider: TestServerConfigurationProvider!
  var bannedParamsManager: BannedParamsManager!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    bannedParamsManager = BannedParamsManager()
    provider = TestServerConfigurationProvider(configuration: serverConfiguration)
    bannedParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
  }

  override func tearDown() {
    super.tearDown()
    bannedParamsManager = nil
    provider = nil
  }

  func testDefaultDependencies() throws {
    bannedParamsManager.resetDependencies()
    XCTAssertTrue(
      bannedParamsManager.serverConfigurationProvider === _ServerConfigurationManager.shared,
      "Should use the shared server configuration manger by default"
    )
  }

  func testConfiguringDependencies() {
    XCTAssertTrue(
      bannedParamsManager.serverConfigurationProvider === provider,
      "Should be able to create with a server configuration provider"
    )
  }

  func testAllowOtherParams() {
    bannedParamsManager.enable()
    XCTAssertTrue(bannedParamsManager.getIsEnabled() == true)

    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "predicted_ltv"): "NOT_COMPLIANT",
      AppEvents.ParameterName(rawValue: "something_else"): "THIS_IS_FINE",
    ]

    let expectedFilteredParams: NSDictionary = [
      AppEvents.ParameterName(rawValue: "something_else"): "THIS_IS_FINE",
    ]

    let filteredParams = bannedParamsManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }

  func testBannedParamBlocking() {
    bannedParamsManager.enable()
    XCTAssertTrue(bannedParamsManager.getIsEnabled() == true)

    let parameters: NSDictionary = [
      AppEvents.ParameterName(rawValue: "predicted_ltv"): "NOT_COMPLIANT",
    ]

    let expectedFilteredParams: NSDictionary = [:]

    let filteredParams = bannedParamsManager.processParameters(parameters, event: "test_event")
    XCTAssertEqual(filteredParams, expectedFilteredParams)
  }

  func testNotEnabled() {
    let testServerConfigDict = [
      "protectedModeRules": [
        "standard_params_blocked": [],
      ],
    ]
    let serverConfig = ServerConfigurationFixtures.configuration(withDictionary: testServerConfigDict)
    provider = TestServerConfigurationProvider(configuration: serverConfig)
    bannedParamsManager.configuredDependencies = .init(
      serverConfigurationProvider: provider
    )
    bannedParamsManager.enable()
    XCTAssertTrue(bannedParamsManager.getIsEnabled() == false)
  }
}
